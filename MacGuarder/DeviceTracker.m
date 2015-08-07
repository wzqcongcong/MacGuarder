//
//  DeviceTracker.m
//  MacGuarder
//
//  Created by GoKu on 14-7-24.
//  Copyright (c) 2014年 GoKuStudio. All rights reserved.
//

#import "DeviceTracker.h"
#import "DeviceKeeper.h"
#import "RSSISmootheningFilter.h"
#import "LogFormatter.h"

extern int ddLogLevel;

@interface DeviceTracker ()

@property (nonatomic, readwrite) BOOL isMonitoring;

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

- (void)startMonitoring
{
    self.isMonitoring = YES;
    
    self.inRangeThreshold = [DeviceKeeper getThresholdRSSIOfDevice:self.device.addressString forUser:nil];
    DDLogInfo(@"get threshold for device %@: %ld", self.device.name, self.inRangeThreshold);
    DDLogInfo(@"monitoring: %@", self.device.name);
    
    [[RSSISmootheningFilter sharedInstance] reset];
    
    [NSThread detachNewThreadSelector:@selector(updateStatus) toTarget:self withObject:nil];
    
    self.deviceInRange = YES;
    self.initialRSSI = -127;
}

- (void)stopMonitoring
{
    self.isMonitoring = NO;
}

- (void)selectDevice
{
    IOBluetoothDeviceSelectorController *deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
    // show dialog to select
    [deviceSelector runModal];
    
    NSArray *results = [deviceSelector getResults];
    
    if (results) {
        self.device = [results objectAtIndex:0];
        
        [self.device performSDPQuery:self];
        
        if (self.deviceSelectedBlock) {
            self.deviceSelectedBlock(self);
        }
    }
}

- (void)updateStatus
{
    while (self.isMonitoring) {

        if (self.device) {
            BOOL reconnected = NO;
            
            if (![self.device isConnected]) {
                DDLogInfo(@"connecting");
                reconnected = ([self.device openConnection] == kIOReturnSuccess);
                [[RSSISmootheningFilter sharedInstance] reset];

                if (reconnected) {
                    DDLogInfo(@"connected");
                    self.initialRSSI = self.currentRSSI;
                }
            }

            if ([self.device isConnected]) {
                BluetoothHCIRSSIValue rawRSSI = [self.device rawRSSI];
                [[RSSISmootheningFilter sharedInstance] addSample:rawRSSI];
                self.currentRSSI = [[RSSISmootheningFilter sharedInstance] getMedianValue];
                DDLogVerbose(@"connected, current raw RSSI: %d", rawRSSI);
                DDLogVerbose(@"connected, current RSSI: %d", self.currentRSSI);
                
                // device is in area
                if (self.currentRSSI > self.inRangeThreshold) {
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
        
        [NSThread sleepForTimeInterval:kTrackerTimeInteval];
    }
    
    DDLogInfo(@"close connection");
    [self.device closeConnection];
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
        DDLogError(@"failed to get services of device: %@", device.name);
    }
}

- (void)connectionComplete:(IOBluetoothDevice *)device status:(IOReturn)status
{
    
}

- (void)remoteNameRequestComplete:(IOBluetoothDevice *)device status:(IOReturn)status
{
    
}

@end
