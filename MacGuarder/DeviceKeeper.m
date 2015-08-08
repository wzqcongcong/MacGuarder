//
//  DeviceKeeper.m
//  MacGuarder
//
//  Created by GoKu on 14-7-24.
//  Copyright (c) 2014年 GoKuStudio. All rights reserved.
//

#import "DeviceKeeper.h"
#import "LogFormatter.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"

NSInteger const kDefaultInRangeThreshold    = -60;

static NSString * const kDeviceSettings     = @"DeviceSettings"; // {"addressString": dicSettings}
static NSString * const kThresholdRSSI      = @"MacGuarderThresholdRSSI";

static NSString * const kFavoriteDevices    = @"FavoriteDevices"; // ["addressString"]

// stored with encryption
static NSString * const kUserInfo           = @"UserInfo"; // {"uid": "password"}

static NSString * const kDeviceKeeperKey    = @"com.GoKuStudio.MacGuarder.DeviceKeeperKey";

extern int ddLogLevel;

@implementation DeviceKeeper

+ (void)setThresholdRSSI:(NSInteger)RSSI forDevice:(NSString *)deviceAddress
{
    NSMutableDictionary *deviceSettings = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kDeviceSettings] mutableCopy];
    if (!deviceSettings) {
        deviceSettings = [NSMutableDictionary dictionary];
    }

    NSMutableDictionary *settings = [[deviceSettings objectForKey:deviceAddress] mutableCopy];
    if (!settings) {
        settings = [NSMutableDictionary dictionary];
    }

    [settings setObject:[NSNumber numberWithInteger:RSSI] forKey:kThresholdRSSI];
    [deviceSettings setObject:settings forKey:deviceAddress];

    [[NSUserDefaults standardUserDefaults] setObject:deviceSettings forKey:kDeviceSettings];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSInteger)getThresholdRSSIOfDevice:(NSString *)deviceAddress
{
    NSDictionary *deviceSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kDeviceSettings];
    if (deviceSettings) {
        NSDictionary *settings = [deviceSettings objectForKey:deviceAddress];
        if (settings) {
            NSNumber *thresholdRSSI = [settings objectForKey:kThresholdRSSI];
            if (thresholdRSSI) {
                return [thresholdRSSI integerValue];
            }
        }
    }

    return kDefaultInRangeThreshold;
}

+ (void)saveFavoriteDevice:(NSString *)deviceAddress
{
    NSMutableArray *favoriteDevices = [[[NSUserDefaults standardUserDefaults] arrayForKey:kFavoriteDevices] mutableCopy];
    if (!favoriteDevices) {
        favoriteDevices = [NSMutableArray array];
    }

    [favoriteDevices removeAllObjects];
    [favoriteDevices addObject:deviceAddress];

    [[NSUserDefaults standardUserDefaults] setObject:favoriteDevices forKey:kFavoriteDevices];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSArray *)getFavoriteDevices
{
    NSArray *favoriteDevices = [[NSUserDefaults standardUserDefaults] arrayForKey:kFavoriteDevices];
    return favoriteDevices;
}

+ (void)savePassword:(NSString *)password forUser:(NSString *)uid
{
    NSMutableDictionary *userInfo = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kUserInfo] mutableCopy];
    if (!userInfo) {
        userInfo = [NSMutableDictionary dictionary];
    }

    NSData *plainData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSData *encryptedData = [RNEncryptor encryptData:plainData
                                        withSettings:kRNCryptorAES256Settings
                                            password:kDeviceKeeperKey
                                               error:NULL];

    [userInfo setObject:encryptedData forKey:uid];

    [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:kUserInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getPasswordForUser:(NSString *)uid
{
    NSMutableDictionary *userInfo = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:kUserInfo] mutableCopy];
    if (userInfo) {
        NSData *encryptedData = [userInfo objectForKey:uid];
        if (encryptedData) {
            NSData *decryptedData = [RNDecryptor decryptData:encryptedData
                                                withPassword:kDeviceKeeperKey
                                                       error:NULL];
            if (decryptedData) {
                NSString *password = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
                return password;
            }
        }
    }

    return nil;
}

@end
