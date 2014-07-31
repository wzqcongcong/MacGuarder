//
//  DeviceTracker.m
//  MacGuarder
//
//  Created by user on 14-7-24.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import "DeviceTracker.h"
#import "DeviceKeeper.h"
#import "RSSISmootheningFilter.h"


@interface DeviceTracker ()

@property (nonatomic, readwrite) BOOL isMonitoring;

@end


@implementation DeviceTracker

+ (DeviceTracker*)sharedTracker
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
    _isMonitoring = YES;
    
    self.inRangeThreshold = [DeviceKeeper getThresholdRSSIOfDevice:self.device.addressString forUser:nil];
    NSLog(@"get threshold of device %@: %d", self.device.name, self.inRangeThreshold);
    
    [[RSSISmootheningFilter sharedInstance] reset];
    
    [NSThread detachNewThreadSelector:@selector(updateStatus) toTarget:self withObject:nil];
    
    self.deviceInRange = YES;
    self.initialRSSI = -127;
}

- (void)stopMonitoring
{
    _isMonitoring = NO;
}

// just for test scanning services
- (void)testService
{
    IOBluetoothServiceBrowserController *serviceSelector = [IOBluetoothServiceBrowserController serviceBrowserController:kNilOptions];
    [serviceSelector runModal];
    
    NSArray *results = [serviceSelector getResults];
    [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IOBluetoothSDPServiceRecord *service = (IOBluetoothSDPServiceRecord *)obj;
        NSLog(@"%@", [service getServiceName]);
        
        NSDictionary *attributes = [service attributes];
        [attributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSLog(@"%@, %@", key, obj);
        }];
    }];
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
                NSLog(@"connecting");
                reconnected = ([self.device openConnection] == kIOReturnSuccess);
                [[RSSISmootheningFilter sharedInstance] reset];
            }
            
            if ([self.device isConnected]) {
                BluetoothHCIRSSIValue rawRSSI = [self.device rawRSSI];
                [[RSSISmootheningFilter sharedInstance] addSample:rawRSSI];
                self.currentRSSI = [[RSSISmootheningFilter sharedInstance] getMedianValue];
                NSLog(@"connected, current raw RSSI: %d", rawRSSI);
                NSLog(@"connected, current RSSI: %d", self.currentRSSI);
                
                // device is in area
                if (self.currentRSSI > self.inRangeThreshold) {
                    NSLog(@"connected, device is in area.");
                    // device was out of area before, trigger unlock.
                    if (!self.deviceInRange) {
                        NSLog(@"connected, device was out of area before, trigger unlock.");
                        self.deviceInRange = YES;
                        
                        if (self.deviceRangeStatusUpdateBlock) {
                            self.deviceRangeStatusUpdateBlock(self);
                        }
                    }
                    // device was in area already, do nothing.
                    else {
                        NSLog(@"device was in area already, do nothing.");
                    }
                }
                // device is out of area
                else {
                    NSLog(@"connected, device is out of area.");
                    // device was in area before, trigger lock.
                    if (self.deviceInRange) {
                        NSLog(@"connected, device was in area before, trigger lock.");
                        self.deviceInRange = NO;
                        
                        if (self.deviceRangeStatusUpdateBlock) {
                            self.deviceRangeStatusUpdateBlock(self);
                        }
                    }
                    // device was out of area already, do nothing.
                    else {
                        NSLog(@"device was out of area already, do nothing.");
                    }
                }
            }
            
            if (reconnected) {
                self.initialRSSI = self.currentRSSI;
            }
            
        } else {
            NSLog(@"no device");
        }
        
        [NSThread sleepForTimeInterval:kTrackerTimeInteval];
    }
    
    NSLog(@"close connection");
    [self.device closeConnection];
}


#pragma mark - delegate

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
            NSLog(@"%@ %@", [service getServiceName], ([service hasServiceFromArray:matchedUUIDs] ? @"- Matched!" : @""));
        }];
    } else {
        NSLog(@"failed to get services of device: %@", device.name);
    }
}

- (void)connectionComplete:(IOBluetoothDevice *)device status:(IOReturn)status
{
    
}

- (void)remoteNameRequestComplete:(IOBluetoothDevice *)device status:(IOReturn)status
{
    
}

@end
