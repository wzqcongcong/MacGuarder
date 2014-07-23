//
//  MacGuarderHelper.m
//  MacGuarder
//
//  Created by user on 14-7-23.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import "MacGuarderHelper.h"


NSString *password;


@implementation MacGuarderHelper

+ (BOOL)isScreenLocked
{
    BOOL locked = NO;
    id o = [(NSDictionary*)CGSessionCopyCurrentDictionary() objectForKey:@"CGSSessionScreenIsLocked"];
    if (o) {
        locked = [o boolValue];
    }
    return locked;
}

+ (void)lock
{
    if ([MacGuarderHelper isScreenLocked]) return;

    int screensaverDelay = [MacGuarderHelper getScreensaverDelay];
    BOOL screensaverAskForPassword = [MacGuarderHelper getScreensaverAskForPassword];

    [MacGuarderHelper setScreensaverDelay:0];
    [MacGuarderHelper setScreensaverAskForPassword:YES];

    io_registry_entry_t r = IORegistryEntryFromPath(kIOMasterPortDefault,
                                                    "IOService:/IOResources/IODisplayWrangler");
    if (r) {
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanTrue);
        IOObjectRelease(r);
    }

    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        io_registry_entry_t r = IORegistryEntryFromPath(kIOMasterPortDefault,
                                                        "IOService:/IOResources/IODisplayWrangler");
        if (r) {
            IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanFalse);
            IOObjectRelease(r);
        }

        [MacGuarderHelper setScreensaverDelay:screensaverDelay];
        [MacGuarderHelper setScreensaverAskForPassword:screensaverAskForPassword];
    });
}

+ (void)unlock
{
    while(![MacGuarderHelper isScreenLocked]) {};

    io_registry_entry_t r = IORegistryEntryFromPath(kIOMasterPortDefault,
                                                    "IOService:/IOResources/IODisplayWrangler");
    if (r) {
        IORegistryEntrySetCFProperty(r, CFSTR("IORequestIdle"), kCFBooleanFalse);
        IOObjectRelease(r);
    }

    NSString *s = @"tell application \"System Events\" to keystroke \"%@\"\n\
                    tell application \"System Events\" to keystroke return";

    NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:s, password]] autorelease];
    [script executeAndReturnError:nil];
}

+ (void)setPassword:(NSString*)p
{
    if (password) {
        [password release];
    }

    password = [p copy];
}

+ (NSString*)getPassword
{
    return [[password copy] autorelease];
}


#pragma mark - inner

+ (int)getScreensaverDelay
{
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.screensaver"];
    return [[prefs objectForKey:@"askForPasswordDelay"] intValue];
}

+ (BOOL)getScreensaverAskForPassword
{
    NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.screensaver"];
    return [[prefs objectForKey:@"askForPassword"] boolValue];
}

+ (void)setScreensaverDelay:(int)value
{
    NSArray *arguments = @[@"write",@"com.apple.screensaver",@"askForPasswordDelay", [NSString stringWithFormat:@"%i", value]];
    NSTask *resetDelayTask = [[[NSTask alloc] init] autorelease];
    [resetDelayTask setArguments:arguments];
    [resetDelayTask setLaunchPath: @"/usr/bin/defaults"];
    [resetDelayTask launch];
}

+ (void)setScreensaverAskForPassword:(BOOL)value
{
    NSArray *arguments = @[@"write",@"com.apple.screensaver",@"askForPassword", [NSString stringWithFormat:@"%i", value]];
    NSTask *resetDelayTask = [[[NSTask alloc] init] autorelease];
    [resetDelayTask setArguments:arguments];
    [resetDelayTask setLaunchPath: @"/usr/bin/defaults"];
    [resetDelayTask launch];

    NSAppleScript *kickSecurityPreferencesScript = [[[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"tell application \"System Events\" to tell security preferences to set require password to wake to %@", value ? @"true" : @"false"]] autorelease];
    [kickSecurityPreferencesScript executeAndReturnError:nil];
}

@end
