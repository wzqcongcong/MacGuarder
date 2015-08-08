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

+ (void)setThresholdRSSI:(NSInteger)RSSI forDevice:(NSString *)deviceAddress;
+ (NSInteger)getThresholdRSSIOfDevice:(NSString *)deviceAddress;

+ (void)saveFavoriteDevice:(NSString *)deviceAddress;
+ (NSArray *)getFavoriteDevices;

+ (void)savePassword:(NSString *)password forUser:(NSString *)uid;
+ (NSString *)getPasswordForUser:(NSString *)uid;

@end
