//
//  ConfigManager.m
//  MacGuarder
//
//  Created by GoKu on 14-7-24.
//  Copyright (c) 2014年 GoKuStudio. All rights reserved.
//

#import "ConfigManager.h"
#import "LogFormatter.h"
#import "RNCryptor-Swift.h"
#import "Valet.h"

NSString * const kLoginItemBundleID = @"com.gokustudio.MacGuarderLoginItem";

NSInteger const kDefaultInRangeThreshold    = -60;

static NSString * const kLoginItemEnabled   = @"LoginItemEnabled";

static NSString * const kAutoStartMonitor   = @"AutoStartMonitor";

static NSString * const kDeviceSettings     = @"DeviceSettings"; // {"addressString": dicSettings}
static NSString * const kThresholdRSSI      = @"MacGuarderThresholdRSSI";

static NSString * const kFavoriteDevices    = @"FavoriteDevices"; // ["addressString"]

// stored with encryption
static NSString * const kUserInfo           = @"UserInfo"; // {"uid": "password"}

static NSString * const kDeviceKeeperKey    = @"com.GoKuStudio.MacGuarder.DeviceKeeperKey";

@implementation ConfigManager

+ (void)setLoginItemEnabled:(BOOL)enabled
{
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kLoginItemEnabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)loginItemEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kLoginItemEnabled];
}

+ (void)setAutoStartMonitor:(BOOL)autoStart
{
    [[NSUserDefaults standardUserDefaults] setBool:autoStart forKey:kAutoStartMonitor];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)isAutoStartMonitor
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAutoStartMonitor];
}

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
    VALValet *myValet = [[VALValet alloc] initWithIdentifier:kDeviceKeeperKey accessibility:VALAccessibilityAfterFirstUnlock];

    NSData *plainData = [password dataUsingEncoding:NSUTF8StringEncoding];

    RNEncryptor *encryptor = [[RNEncryptor alloc] initWithPassword:kDeviceKeeperKey];
    NSData *encryptedData = [encryptor encryptData:plainData];
    

    [myValet setObject:encryptedData forKey:[NSString stringWithFormat:@"%@_%@", kUserInfo, uid]];
}

+ (NSString *)getPasswordForUser:(NSString *)uid
{
    VALValet *myValet = [[VALValet alloc] initWithIdentifier:kDeviceKeeperKey accessibility:VALAccessibilityAfterFirstUnlock];
    NSData *encryptedData = [myValet objectForKey:[NSString stringWithFormat:@"%@_%@", kUserInfo, uid]];
    if (encryptedData) {
        RNDecryptor *decryptor = [[RNDecryptor alloc] initWithPassword:kDeviceKeeperKey];
        NSData *decryptedData = [decryptor decryptData:encryptedData error:nil];
        if (decryptedData) {
            NSString *password = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
            return password;
        }
    }

    return nil;
}

@end
