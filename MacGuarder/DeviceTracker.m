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
    
    [NSThread detachNewThreadSelector:@selector(_updateRSSI) toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(_updateStatus) toTarget:self withObject:nil];
    
    self.deviceInRange = YES;
    self.initialRSSI = -127;
}

- (void)stopMonitoring
{
    _isMonitoring = NO;
}

- (void)selectDevice
{
    IOBluetoothDeviceSelectorController *deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
    [deviceSelector runModal];
    
    NSArray *results = [deviceSelector getResults];
    
    if (results) {
        self.device = [results objectAtIndex:0];
        //[self.device closeConnection];
        
        if (self.deviceSelectedBlock) {
            self.deviceSelectedBlock(self);
        }
    }
}

- (void)_updateRSSI
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
                NSLog(@"connected, current RSSI: %d", self.currentRSSI);
            } else {
            }
            
            if (reconnected) {
                self.initialRSSI = self.currentRSSI;
            }
        } else {
            NSLog(@"no device");
        }
        
        [NSThread sleepForTimeInterval:0.25];
    }
    
    NSLog(@"close connection");
    [self.device closeConnection];
}

- (void)_updateStatus
{
    while (self.isMonitoring) {
        if (self.device && [self.device isConnected]) {
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
        
        [NSThread sleepForTimeInterval:0.25];
    }
}

@end
