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

@property (nonatomic, strong) IOBluetoothDevice *tmpSelectedDevice;

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

    self.tmpSelectedDevice = [MGMonitorController sharedMonitorController].selectedDevice;
    self.infoLabel.stringValue = self.tmpSelectedDevice ? self.tmpSelectedDevice.name : @"Please select a device";
    self.tfMacPassword.stringValue = [MGMonitorController sharedMonitorController].password ? : @"";
}

#pragma mark - UI action

- (IBAction)didClickSelectDevice:(id)sender
{
    IOBluetoothDevice *newSelectedDevice = [[MGMonitorController sharedMonitorController] selectDevice];

    if (newSelectedDevice) {
        self.tmpSelectedDevice = newSelectedDevice;

        DDLogInfo(@"select device: %@ [%@]", self.tmpSelectedDevice.name, self.tmpSelectedDevice.addressString);
        self.infoLabel.stringValue = self.tmpSelectedDevice.name;

    } else {
        DDLogInfo(@"no device selected");
    }
}

- (IBAction)didClickStop:(id)sender
{
    [[DeviceTracker sharedTracker] stopMonitoring];
    [(AppDelegate *)[NSApplication sharedApplication].delegate updateStatusOfStatusBar];
}

- (IBAction)saveAndRestart:(id)sender
{
    if (!self.tmpSelectedDevice) {
        DDLogError(@"please select a device");
        return;
    }

    if (self.tfMacPassword.stringValue.length <= 0) {
        DDLogError(@"please input the login password of Mac");
        return;
    }

    [[DeviceTracker sharedTracker] stopMonitoring];
    [(AppDelegate *)[NSApplication sharedApplication].delegate updateStatusOfStatusBar];
    
    // save device and password
    [MGMonitorController sharedMonitorController].selectedDevice = self.tmpSelectedDevice;
    [MGMonitorController sharedMonitorController].password = self.tfMacPassword.stringValue;
    [DeviceKeeper saveFavoriteDevice:[MGMonitorController sharedMonitorController].selectedDevice.addressString];
    [DeviceKeeper setThresholdRSSI:kDefaultInRangeThreshold forDevice:[MGMonitorController sharedMonitorController].selectedDevice.addressString];
    [DeviceKeeper savePassword:[MGMonitorController sharedMonitorController].password forUser:[MGMonitorController sharedMonitorController].userUID];

    // leave some time for stop
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMGMonitorTrackerTimeInteval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DeviceTracker sharedTracker] startMonitoring];
        [(AppDelegate *)[NSApplication sharedApplication].delegate updateStatusOfStatusBar];
    });

    [self.window close];
}

#pragma mark - authorization view delegate

-(void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    // need manually active app, because the app is agent, and the system unlock UI will lock focus.
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
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
