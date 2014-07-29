//
//  DeviceKeeper.h
//  MacGuarder
//
//  Created by user on 14-7-24.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import <Foundation/Foundation.h>

/* by Plist */
#define kUserInfo                                   @"UserInfo"         // UserInfo.plist
#define kDevicesConfig                              @"DevicesConfig"    // DevicesConfig.plist
#define kDevicesConfig_favoriteDevices              @"favoriteDevices"  // array
#define kDevicesConfig_storedDevices                @"storedDevices"    // dictionary
#define kDevicesConfig_storedDevices_idleRSSI       @"idleRSSI"
#define kDevicesConfig_storedDevices_thresholdRSSI  @"thresholdRSSI"

/* by NSUserDefaults*/
#define kDevices                                    @"com.trendmicro.MacGuarder.Devices"
#define kIdleRSSI                                   @"MacGuarderIdleRSSI"
#define kThresholdRSSI                              @"MacGuarderThresholdRSSI"
#define kDefaultInRangeThreshold                    -60

@interface DeviceKeeper : NSObject

+ (BOOL)deviceExists:(NSString*)deviceAddress;

+ (void)setThresholdRSSI:(int)RSSI ofDevice:(NSString*)deviceAddress forUser:(NSString *)uid;
+ (int)getThresholdRSSIOfDevice:(NSString*)deviceAddress forUser:(NSString *)uid;

+ (void)saveFavoriteDevice:(NSString*)deviceAddress forUser:(NSString *)uid;
+ (NSArray *)getFavoriteDevicesForUser:(NSString *)uid;

+ (void)savePassword:(NSString *)password forUser:(NSString *)uid;
+ (NSString *)getPasswordForUser:(NSString *)uid;

@end
