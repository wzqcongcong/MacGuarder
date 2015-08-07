//
//  MacGuarderHelper.m
//  MacGuarder
//
//  Created by GoKu on 14-7-23.
//  Copyright (c) 2014年 GoKuStudio. All rights reserved.
//

#import "MacGuarderHelper.h"
#import "LogFormatter.h"

static NSString *password;

extern int ddLogLevel;

@implementation MacGuarderHelper

+ (void)setPassword:(NSString *)p
{
    password = [p copy];
}

+ (BOOL)isScreenLocked
{
    BOOL locked = NO;
    
    CFDictionaryRef CGSessionCurrentDictionary = CGSessionCopyCurrentDictionary();
    id o = [(__bridge NSDictionary *)CGSessionCurrentDictionary objectForKey:@"CGSSessionScreenIsLocked"];
    if (o) {
        locked = [o boolValue];
    }
    CFRelease(CGSessionCurrentDictionary);
    
    return locked;
}

+ (void)lock
{
    if ([MacGuarderHelper isScreenLocked]) return;

    // get user's old setting
    BOOL screensaverAskForPassword = [MacGuarderHelper getScreensaverAskForPassword];
    NSInteger screensaverDelay = [MacGuarderHelper getScreensaverDelay];
    
    // set the new setting for locking operation
    [MacGuarderHelper setScreensaverAskForPassword:YES];    // ask for password to unlock
    [MacGuarderHelper setScreensaverDelay:0];               // show login window immediately

    // shutdown display to idle status
    io_registry_entry_t r = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if (r) {
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanTrue);
        IOObjectRelease(r);
    }

    // show login window 1s after display idle
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // wakeup display from idle status to show login window
        io_registry_entry_t r = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
        if (r) {
            IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanFalse);
            IOObjectRelease(r);
        }

        // restore user's old setting, the old setting only takes effect after next display idle.
        [MacGuarderHelper setScreensaverAskForPassword:screensaverAskForPassword];
        [MacGuarderHelper setScreensaverDelay:screensaverDelay];
    });
}

+ (void)unlock
{
    if (![MacGuarderHelper isScreenLocked]) return;

    // wakeup display from idle status to show login window
    io_registry_entry_t r = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler");
    if (r) {
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanFalse);
        IOObjectRelease(r);
    }

    // use Apple Script to input password and unlock Mac
    NSString *s = @"tell application \"System Events\" to keystroke \"%@\"\n\
                    tell application \"System Events\" to keystroke return";

    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:s, password]];
    [script executeAndReturnError:nil];
}

#pragma mark - inner

+ (NSInteger)getScreensaverDelay
{
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.screensaver"];
    return [[prefs objectForKey:@"askForPasswordDelay"] intValue];
}

+ (BOOL)getScreensaverAskForPassword
{
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.screensaver"];
    return [[prefs objectForKey:@"askForPassword"] boolValue];
}

+ (void)setScreensaverDelay:(NSInteger)value
{
    NSArray *arguments = @[@"write", @"com.apple.screensaver", @"askForPasswordDelay", [NSString stringWithFormat:@"%li", value]];
    NSTask *resetDelayTask = [[NSTask alloc] init];
    [resetDelayTask setArguments:arguments];
    [resetDelayTask setLaunchPath: @"/usr/bin/defaults"];
    [resetDelayTask launch];
}

+ (void)setScreensaverAskForPassword:(BOOL)value
{
    NSArray *arguments = @[@"write", @"com.apple.screensaver", @"askForPassword", [NSString stringWithFormat:@"%i", value]];
    NSTask *resetDelayTask = [[NSTask alloc] init];
    [resetDelayTask setArguments:arguments];
    [resetDelayTask setLaunchPath: @"/usr/bin/defaults"];
    [resetDelayTask launch];

    NSAppleScript *kickSecurityPreferencesScript = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"System Events\" to tell security preferences to set require password to wake to %@", value ? @"true" : @"false"]];
    [kickSecurityPreferencesScript executeAndReturnError:nil];
}

@end
