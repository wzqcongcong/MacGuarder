//
//  DeviceKeeper.m
//  MacGuarder
//
//  Created by user on 14-7-24.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import "DeviceKeeper.h"


@implementation DeviceKeeper

+ (NSMutableDictionary*)devices
{
    NSMutableDictionary *devices = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kDevices] mutableCopy];
    if(!devices)
    {
        devices = [NSMutableDictionary dictionary];
        [DeviceKeeper saveDevices:devices];
    }
    return devices;
}

+ (void)saveDevices:(NSMutableDictionary*)devices
{
    [[NSUserDefaults standardUserDefaults] setObject:devices forKey:kDevices];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)deviceExists:(NSString*)deviceAddress
{
    return ([[DeviceKeeper devices] objectForKey:deviceAddress] != nil);
}

+ (void)setThresholdRSSI:(int)RSSI ofDevice:(NSString*)deviceAddress forUser:(NSString *)uid
{
    NSMutableDictionary *devices = [DeviceKeeper devices];
    NSMutableDictionary *deviceDict = [[devices objectForKey:deviceAddress] mutableCopy];
    if(!deviceDict)
    {
        deviceDict = [NSMutableDictionary dictionary];
    }
    [deviceDict setObject:[NSNumber numberWithInt:RSSI] forKey:kThresholdRSSI];
    [devices setObject:deviceDict forKey:deviceAddress];
    [DeviceKeeper saveDevices:devices];
}

+ (int)getThresholdRSSIOfDevice:(NSString*)deviceAddress forUser:(NSString *)uid
{
    NSMutableDictionary *devices = [DeviceKeeper devices];
    if([devices objectForKey:deviceAddress])
    {
        return [[[devices objectForKey:deviceAddress] objectForKey:kThresholdRSSI] intValue];
    }
    return kDefaultInRangeThreshold;
}

+ (void)saveFavoriteDevice:(NSString*)deviceAddress forUser:(NSString *)uid
{
    NSString *configPlist = [[NSBundle mainBundle] pathForResource:kDevicesConfig ofType:@"plist"];
    NSMutableDictionary *configDic = [NSMutableDictionary dictionaryWithContentsOfFile:configPlist];
    
    NSMutableArray *favoriteDevices = [configDic valueForKey:kDevicesConfig_favoriteDevices];
    if (!favoriteDevices) {
        favoriteDevices = [NSMutableArray arrayWithCapacity:1];
        [configDic setObject:favoriteDevices forKey:kDevicesConfig_favoriteDevices];
    }
    [favoriteDevices removeAllObjects];
    [favoriteDevices addObject:deviceAddress];
    
    [configDic writeToFile:configPlist atomically:YES];    
}

+ (NSArray *)getFavoriteDevicesForUser:(NSString *)uid
{
    NSString *configPlist = [[NSBundle mainBundle] pathForResource:kDevicesConfig ofType:@"plist"];
    NSDictionary *configDic = [NSDictionary dictionaryWithContentsOfFile:configPlist];
    
    NSArray *favoriteDevices = [configDic valueForKey:kDevicesConfig_favoriteDevices];
    return favoriteDevices;
}

+ (void)savePassword:(NSString *)password forUser:(NSString *)uid
{
    NSString *userPlist = [[NSBundle mainBundle] pathForResource:kUserInfo ofType:@"plist"];
    NSMutableDictionary *userDic = [NSMutableDictionary dictionaryWithContentsOfFile:userPlist];
    [userDic setObject:password forKey:uid];
    [userDic writeToFile:userPlist atomically:YES];
}

+ (NSString *)getPasswordForUser:(NSString *)uid
{
    NSString *userPlist = [[NSBundle mainBundle] pathForResource:kUserInfo ofType:@"plist"];
    NSDictionary *userDic = [NSDictionary dictionaryWithContentsOfFile:userPlist];
    
    NSString *password = [userDic valueForKey:uid];
    return (password ? password : @"");
}

@end
