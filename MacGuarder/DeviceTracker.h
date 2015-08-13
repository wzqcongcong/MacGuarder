//
//  DeviceTracker.h
//  MacGuarder
//
//  Created by GoKu on 14-7-24.
//  Copyright (c) 2014年 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import <IOBluetoothUI/IOBluetoothUI.h>

extern float const kMGMonitorTrackerTimeInteval;

@class DeviceTracker;

typedef void (^DeviceRangeStatusUpdateBlock)(DeviceTracker *tracker);   // callback for updating device range status
typedef void (^DeviceRSSIBroadcastBlock)(NSInteger rssi);              // callback for broadcasting device current rssi

@interface DeviceTracker : NSObject <IOBluetoothDeviceAsyncCallbacks>

@property (atomic, readonly, assign) BOOL isMonitoring;
@property (nonatomic, strong) IOBluetoothDevice *deviceToMonitor;                // the device to be monitored

@property (nonatomic, readonly, assign) BOOL deviceInRange;
@property (nonatomic, assign) NSInteger inRangeThreshold;               // default is -60, range is (weak signal) -127..+20 (strong signal)

@property (nonatomic, copy) DeviceRangeStatusUpdateBlock deviceRangeStatusUpdateBlock;
@property (nonatomic, copy) DeviceRSSIBroadcastBlock deviceRSSIBroadcastBlock;

+ (DeviceTracker *)sharedTracker;

- (void)startBroadcastingRSSIForDevice:(IOBluetoothDevice *)device;
- (void)stopBroadcastingRSSI;

- (void)startMonitoring;
- (void)stopMonitoring;

@end
