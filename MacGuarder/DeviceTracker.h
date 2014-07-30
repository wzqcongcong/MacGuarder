//
//  DeviceTracker.h
//  MacGuarder
//
//  Created by user on 14-7-24.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import <IOBluetoothUI/IOBluetoothUI.h>


#define kService                @"com.trendmicro.MacGuarder"    // service provided by iPhone installed with MacGuarder app
#define kTrackerTimeInteval     0.5


@class DeviceTracker;
typedef void (^DeviceRangeStatusUpdateBlock)(DeviceTracker *tracker);   // callback for updating device range status
typedef void (^DeviceSelectedBlock)(DeviceTracker *tracker);            // callback for select a device to monitor


@interface DeviceTracker : NSObject

@property (nonatomic, strong) IOBluetoothDevice *device;                // the device to be monitored
@property (nonatomic, assign) BluetoothHCIRSSIValue initialRSSI;
@property (nonatomic, assign) BluetoothHCIRSSIValue currentRSSI;

@property (nonatomic, assign) BOOL deviceInRange;
@property (nonatomic, readonly) BOOL isMonitoring;
@property (nonatomic, assign) int inRangeThreshold;     // default is -70, range is (weak signal) -127..+20 (strong signal)

@property (nonatomic, copy) DeviceRangeStatusUpdateBlock deviceRangeStatusUpdateBlock;
@property (nonatomic, copy) DeviceSelectedBlock deviceSelectedBlock;

+ (DeviceTracker*)sharedTracker;
- (void)selectDevice;
- (void)startMonitoring;
- (void)stopMonitoring;

- (void)testService;

@end
