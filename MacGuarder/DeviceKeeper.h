//
//  DeviceKeeper.h
//  MacGuarder
//
//  Created by GoKu on 14-7-24.
//  Copyright (c) 2014年 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSInteger const kDefaultInRangeThreshold;

@interface DeviceKeeper : NSObject

+ (BOOL)deviceExists:(NSString *)deviceAddress;

+ (void)setThresholdRSSI:(NSInteger)RSSI ofDevice:(NSString *)deviceAddress forUser:(NSString *)uid;
+ (NSInteger)getThresholdRSSIOfDevice:(NSString *)deviceAddress forUser:(NSString *)uid;

+ (void)saveFavoriteDevice:(NSString *)deviceAddress forUser:(NSString *)uid;
+ (NSArray *)getFavoriteDevicesForUser:(NSString *)uid;

+ (void)savePassword:(NSString *)password forUser:(NSString *)uid;
+ (NSString *)getPasswordForUser:(NSString *)uid;

@end
