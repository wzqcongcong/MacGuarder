//
//  MGSettingsWindowController.m
//  MacGuarder
//
//  Created by user on 8/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "MGSettingsWindowController.h"
#import "LogFormatter.h"
#import <SecurityInterface/SFAuthorizationView.h>
#import "MGMonitorController.h"
#import "AppDelegate.h"
//#import "GCDWebServer.h"
//#import "GCDWebServerDataResponse.h"

extern int ddLogLevel;

static NSString * const kAUTH_RIGHT_CONFIG_MODIFY   = @"com.GoKuStudio.MacGuarder";

@interface MGSettingsWindowController ()

@property (weak) IBOutlet NSTextField *infoLabel;
@property (weak) IBOutlet NSButton *btSelectDevice;

@property (weak) IBOutlet NSSecureTextField *tfMacPassword;
@property (weak) IBOutlet SFAuthorizationView *authorizationView;

@property (weak) IBOutlet NSButton *btStart;
@property (weak) IBOutlet NSButton *btStop;

@end

@implementation MGSettingsWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:@"MGSettingsWindowController"];
    if (self) {
    }
    return self;
}

- (void)windowDidLoad
{
    // request a default admin user right
    // PS:
    // 1. This default admin user right is shared with other app, like Apple's Preferences->Sharing,
    //    this means the lock they use are in sync mode.
    //    Once the admin user logins Mac, this kind of right is got, and their locks are automatically unlocked.
    // 2. But Apple's Preferences->Users & Groups app uses a higher super root user right,
    //    even the admin user logins Mac, this kind of right is still not got, need to input password to get it.

    [_authorizationView setString:[kAUTH_RIGHT_CONFIG_MODIFY UTF8String]];
    [_authorizationView setAutoupdate:YES];
    [_authorizationView setDelegate:self];

    // mannually sync lock status of admin user rights
    [self.authorizationView updateStatus:self.authorizationView];
}

#pragma mark - UI action

- (IBAction)didClickSelectDevice:(id)sender
{
    [MGMonitorController sharedMonitorController].selectedDevice = [[DeviceTracker sharedTracker] selectDevice];

    if ([MGMonitorController sharedMonitorController].selectedDevice) {
        if (![DeviceKeeper deviceExists:[MGMonitorController sharedMonitorController].selectedDevice.addressString]) {
            // save config for this device
            DDLogInfo(@"save threshold of device %@: %ld", [MGMonitorController sharedMonitorController].selectedDevice.name, kDefaultInRangeThreshold);
            [DeviceKeeper setThresholdRSSI:kDefaultInRangeThreshold ofDevice:[MGMonitorController sharedMonitorController].selectedDevice.addressString forUser:nil];
        }

        DDLogInfo(@"select device: %@ [%@]", [MGMonitorController sharedMonitorController].selectedDevice.name, [MGMonitorController sharedMonitorController].selectedDevice.addressString);

    } else {
        DDLogWarn(@"no device selected");
    }
}

- (IBAction)saveAndRestart:(id)sender
{
    // process password

    if ([MGMonitorController sharedMonitorController].selectedDevice) {
        [[DeviceTracker sharedTracker] stopMonitoring];

        [DeviceKeeper saveFavoriteDevice:[MGMonitorController sharedMonitorController].selectedDevice.addressString forUser:nil];

        [DeviceKeeper savePassword:self.tfMacPassword.stringValue
                           forUser:[MGMonitorController sharedMonitorController].userUID];

        [MacGuarderHelper setPassword:self.tfMacPassword.stringValue];

        [[DeviceTracker sharedTracker] startMonitoring];

        [(AppDelegate *)[NSApplication sharedApplication].delegate updateStatusOfStatusBar];

    } else {
        DDLogWarn(@"no device");
    }
}

- (IBAction)didClickStop:(id)sender
{
    [[DeviceTracker sharedTracker] stopMonitoring];
}

#pragma mark - authorization view delegate

-(void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    self.tfMacPassword.enabled = YES;

    AuthorizationRights *rights = self.authorizationView.authorizationRights;
    AuthorizationItem *items = rights->items;
    for (int i=0; i < rights->count; ++i) {
        DDLogVerbose(@"%s", items[i].name);
    }
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{
    self.tfMacPassword.enabled = NO;
}

@end
