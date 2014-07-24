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

+ (void)setIdleRSSI:(int)RSSI forDevice:(NSString*)deviceAddress
{
    NSMutableDictionary *devices = [DeviceKeeper devices];
    NSMutableDictionary *deviceDict = [[devices objectForKey:deviceAddress] mutableCopy];
    if(!deviceDict)
    {
        deviceDict = [NSMutableDictionary dictionary];
    }
    [deviceDict setObject:[NSNumber numberWithInt:RSSI] forKey:kIdleRSSI];
    [devices setObject:deviceDict forKey:deviceAddress];
    [DeviceKeeper saveDevices:devices];
}

+ (void)setThresholdRSSI:(int)RSSI forDevice:(NSString*)deviceAddress
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

+ (int)getIdleRSSIForDevice:(NSString*)deviceAddress
{
    NSMutableDictionary *devices = [DeviceKeeper devices];
    if([devices objectForKey:deviceAddress])
    {
        return [[[devices objectForKey:deviceAddress] objectForKey:kIdleRSSI] intValue];
    }
    return kDefaultInRangeThreshold;
}

+ (int)getThresholdRSSIForDevice:(NSString*)deviceAddress
{
    NSMutableDictionary *devices = [DeviceKeeper devices];
    if([devices objectForKey:deviceAddress])
    {
        return [[[devices objectForKey:deviceAddress] objectForKey:kThresholdRSSI] intValue];
    }
    return kDefaultInRangeThreshold;
}

@end
