//
//  DeviceKeeper.h
//  MacGuarder
//
//  Created by user on 14-7-24.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kDevices                    @"MacGuarderDevices"
#define kIdleRSSI                   @"MacGuarderIdleRSSI"
#define kThresholdRSSI              @"MacGuarderThresholdRSSI"
#define kDefaultInRangeThreshold    -60

@interface DeviceKeeper : NSObject

+ (BOOL)deviceExists:(NSString*)deviceAddress;

+ (void)setIdleRSSI:(int)RSSI forDevice:(NSString*)deviceAddress;
+ (void)setThresholdRSSI:(int)RSSI forDevice:(NSString*)deviceAddress;

+ (int)getIdleRSSIForDevice:(NSString*)deviceAddress;
+ (int)getThresholdRSSIForDevice:(NSString*)deviceAddress;

@end
