//
//  DeviceTracker.m
//  MacGuarder
//
//  Created by GoKu on 14-7-24.
//  Copyright (c) 2014年 GoKuStudio. All rights reserved.
//

#import "DeviceTracker.h"
#import "LogFormatter.h"
#import "RSSISmootheningFilter.h"
#import "ConfigManager.h"

float const kMGMonitorTrackerTimeInteval  = 1;

static NSString * const kServiceName    = @"com.GoKuStudio.MacGuarder";             // service provided by iPhone installed with MacGuarder app
static NSString * const kServiceUUID    = @"3708ADE8-34FA-4FF6-82F8-8B4E3FCCAB1B";  // uuid generated by uuidgen

@interface DeviceTracker ()

@property (nonatomic, strong) NSThread *workThread;
@property (atomic, readwrite, assign) BOOL isMonitoring;
@property (nonatomic, readwrite, assign) BOOL deviceInRange;

@property (nonatomic, strong) NSThread *broadcastThread;
@property (nonatomic, strong) IOBluetoothDevice *deviceToBroadcast;

@property (nonatomic, assign) BluetoothHCIRSSIValue currentRSSI;

@end

@implementation DeviceTracker

+ (DeviceTracker *)sharedTracker
{
    static DeviceTracker *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DeviceTracker alloc] init];
        sharedInstance.inRangeThreshold = kDefaultInRangeThreshold;
    });
    return sharedInstance;
}

#pragma mark - broadcast

- (void)startBroadcastingRSSIForDevice:(IOBluetoothDevice *)device
{
    if (device) {
        self.deviceToBroadcast = device;

        self.broadcastThread = [[NSThread alloc] initWithTarget:self selector:@selector(updateBroadcastStatus) object:nil];
        self.broadcastThread.name = [NSString stringWithFormat:@"%@", [NSDate date]];
        [self.broadcastThread start];
    }
}

- (void)stopBroadcastingRSSI
{
    [self.broadcastThread cancel];

//    if (self.deviceToBroadcast.isConnected) {
//        if (!self.isMonitoring ||
//            ![self.deviceToBroadcast.addressString isEqualToString:self.deviceToMonitor.addressString]) {
//            [self.deviceToBroadcast closeConnection];
//        }
//    }

    self.deviceToBroadcast = nil;
}

- (void)updateBroadcastStatus
{
    DDLogVerbose(@"broadcast thread <%@> start", [NSThread currentThread].name);
    while (!([NSThread currentThread].isCancelled)) {

        if (self.deviceToBroadcast) {
            if (!self.deviceToBroadcast.isConnected) {
                if (self.deviceRSSIBroadcastBlock) {
                    self.deviceRSSIBroadcastBlock(-127);
                }

                [self.deviceToBroadcast openConnection];
            }

            if (self.deviceToBroadcast.isConnected) {
                BluetoothHCIRSSIValue rawRSSI = [self.deviceToBroadcast rawRSSI];
                DDLogVerbose(@"broadcast raw RSSI: %hhd", rawRSSI);

                if (self.deviceRSSIBroadcastBlock) {
                    self.deviceRSSIBroadcastBlock(rawRSSI);
                }

            } else {
                if (self.deviceRSSIBroadcastBlock) {
                    self.deviceRSSIBroadcastBlock(-127);
                }
            }

        } else {
            if (self.deviceRSSIBroadcastBlock) {
                self.deviceRSSIBroadcastBlock(-127);
            }
        }

        [NSThread sleepForTimeInterval:kMGMonitorTrackerTimeInteval];
    }

//    if (self.deviceToBroadcast.isConnected) {
//        if (!self.isMonitoring ||
//            ![self.deviceToBroadcast.addressString isEqualToString:self.deviceToMonitor.addressString]) {
//            [self.deviceToBroadcast closeConnection];
//        }
//    }

    DDLogVerbose(@"broadcast thread <%@> stop", [NSThread currentThread].name);
}

#pragma mark - monitor

- (void)setDeviceToMonitor:(IOBluetoothDevice *)deviceToMonitor
{
//    if (_deviceToMonitor.isConnected) {
//        [_deviceToMonitor closeConnection];
//    }
    _deviceToMonitor = deviceToMonitor;
}

- (void)startMonitoring
{
    if (!self.isMonitoring && self.deviceToMonitor) {
        self.isMonitoring = YES;

        self.inRangeThreshold = [ConfigManager getThresholdRSSIOfDevice:self.deviceToMonitor.addressString];
        DDLogInfo(@"set threshold [%ld] for device: %@ [%@]", self.inRangeThreshold, self.deviceToMonitor.name, self.deviceToMonitor.addressString);
        DDLogInfo(@"now monitoring: %@ [%@]", self.deviceToMonitor.name, self.deviceToMonitor.addressString);

        [[RSSISmootheningFilter sharedInstance] reset];

        self.deviceInRange = YES;
        self.currentRSSI = +127;

        self.workThread = [[NSThread alloc] initWithTarget:self selector:@selector(updateStatus) object:nil];
        self.workThread.name = [NSString stringWithFormat:@"%@", [NSDate date]];
        [self.workThread start];

    } else {
        DDLogError(@"can not start monitor, please use \"Settings\" to setup device.");
    }
}

- (void)stopMonitoring
{
    self.isMonitoring = NO;

    [self.workThread cancel];

//    if (self.deviceToMonitor.isConnected) {
//        [self.deviceToMonitor closeConnection];
//    }
}

- (void)updateStatus
{
    DDLogVerbose(@"work thread <%@> start", [NSThread currentThread].name);
    while (!([NSThread currentThread].isCancelled) && self.isMonitoring) {

        if (self.deviceToMonitor) {
            BOOL reconnected = NO;
            
            if (!self.deviceToMonitor.isConnected) {
                DDLogInfo(@"connecting");
                reconnected = ([self.deviceToMonitor openConnection] == kIOReturnSuccess);
                [[RSSISmootheningFilter sharedInstance] reset];

                if (reconnected) {
                    DDLogInfo(@"connected");
                } else {
                    DDLogInfo(@"no connection");
                }
            }

            if (self.deviceToMonitor.isConnected) {
                BluetoothHCIRSSIValue rawRSSI = [self.deviceToMonitor rawRSSI];

                // add valid RSSI into sample
                if (rawRSSI != 127) {
                    [[RSSISmootheningFilter sharedInstance] addSample:rawRSSI];
                    self.currentRSSI = [[RSSISmootheningFilter sharedInstance] getMedianValue];
                    DDLogVerbose(@"connected, current raw RSSI: %d", rawRSSI);
                    DDLogVerbose(@"connected, current RSSI: %d", self.currentRSSI);
                }
                
                // device is in area
                if (self.currentRSSI >= self.inRangeThreshold) {
                    DDLogVerbose(@"connected, device is in area.");
                    // device was out of area before, trigger unlock.
                    if (!self.deviceInRange) {
                        DDLogInfo(@"connected, device was out of area before, trigger unlock.");
                        self.deviceInRange = YES;
                        
                        if (self.deviceRangeStatusUpdateBlock) {
                            self.deviceRangeStatusUpdateBlock(self);
                        }
                    }
                    // device was in area already, do nothing.
                    else {
                        DDLogVerbose(@"device was in area already, do nothing.");
                    }
                }
                // device is out of area
                else {
                    DDLogVerbose(@"connected, device is out of area.");
                    // device was in area before, trigger lock.
                    if (self.deviceInRange) {
                        DDLogInfo(@"connected, device was in area before, trigger lock.");
                        self.deviceInRange = NO;
                        
                        if (self.deviceRangeStatusUpdateBlock) {
                            self.deviceRangeStatusUpdateBlock(self);
                        }
                    }
                    // device was out of area already, do nothing.
                    else {
                        DDLogVerbose(@"device was out of area already, do nothing.");
                    }
                }
            }
            
        } else {
            DDLogWarn(@"no device");
        }
        
        [NSThread sleepForTimeInterval:kMGMonitorTrackerTimeInteval];
    }
    
//    if (self.deviceToMonitor.isConnected) {
//        [self.deviceToMonitor closeConnection];
//    }

    DDLogVerbose(@"work thread <%@> stop", [NSThread currentThread].name);
}

#pragma mark - IOBluetoothDeviceAsyncCallbacks delegate

- (void)sdpQueryComplete:(IOBluetoothDevice *)device status:(IOReturn)status
{
    if (status == kIOReturnSuccess) {
        // get services of this device
        NSArray *services = device.services;
        [services enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            IOBluetoothSDPServiceRecord *service = (IOBluetoothSDPServiceRecord *)obj;
            // match desired services
            NSArray *matchedUUIDs = @[[IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassAudioSource],
                                      [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassPhonebookAccess]];
            DDLogVerbose(@"%@ %@", [service getServiceName], ([service hasServiceFromArray:matchedUUIDs] ? @"- Matched!" : @""));
        }];
    } else {
        DDLogVerbose(@"failed to get services of device: %@", device.name);
    }
}

- (void)connectionComplete:(IOBluetoothDevice *)device status:(IOReturn)status
{
    
}

- (void)remoteNameRequestComplete:(IOBluetoothDevice *)device status:(IOReturn)status
{
    
}

@end
