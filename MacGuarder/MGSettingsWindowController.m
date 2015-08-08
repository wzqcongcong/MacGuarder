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

@property (weak) IBOutlet NSToolbarItem *toolbarGeneral;
@property (weak) IBOutlet NSToolbarItem *toolbarApp;

@property (strong) IBOutlet NSView *settingGeneralView;
@property (weak) IBOutlet NSTextField *infoLabel;
@property (weak) IBOutlet NSButton *btSelectDevice;
@property (weak) IBOutlet NSSecureTextField *tfMacPassword;
@property (weak) IBOutlet SFAuthorizationView *authorizationView;
@property (weak) IBOutlet NSButton *btStop;
@property (weak) IBOutlet NSButton *btSaveAndRestart;
@property (nonatomic, strong) IOBluetoothDevice *tmpSelectedDevice;

@property (strong) IBOutlet NSView *settingAppView;
@property (weak) IBOutlet NSButton *checkAutoStartMonitor;

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

    // show General by default
    self.window.toolbar.selectedItemIdentifier = self.toolbarGeneral.itemIdentifier;
    [self clickTabSettingGeneral:self.toolbarGeneral];
}

- (void)switchToTabView:(NSView *)settingView withAnimation:(BOOL)animation
{
    NSView *windowView = self.window.contentView;
    CGFloat oldHeight = windowView.frame.size.height;

    for (NSView *view in windowView.subviews) {
        [view removeFromSuperview];
    }

    [windowView addSubview:settingView];
    CGFloat newHeight = settingView.frame.size.height;

    NSPoint origin = settingView.frame.origin;
    origin.y += (oldHeight - newHeight);
    [settingView setFrameOrigin:origin];

    NSRect frame = self.window.frame;
    frame.size.height += (newHeight - oldHeight);
    frame.origin.y -= (newHeight - oldHeight);
    [self.window setFrame:frame display:YES animate:animation];

    /* constraint can not create the animation effect
    [windowView.animator addConstraints:@[[NSLayoutConstraint constraintWithItem:settingView
                                                                       attribute:NSLayoutAttributeTop
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:windowView
                                                                       attribute:NSLayoutAttributeTop
                                                                      multiplier:1
                                                                        constant:0],
                                          [NSLayoutConstraint constraintWithItem:settingView
                                                                       attribute:NSLayoutAttributeBottom
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:windowView
                                                                       attribute:NSLayoutAttributeBottom
                                                                      multiplier:1
                                                                        constant:0],
                                          [NSLayoutConstraint constraintWithItem:settingView
                                                                       attribute:NSLayoutAttributeLeading
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:windowView
                                                                       attribute:NSLayoutAttributeLeading
                                                                      multiplier:1
                                                                        constant:0],
                                          [NSLayoutConstraint constraintWithItem:settingView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:windowView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1
                                                                        constant:0]]];
    //*/
}

#pragma mark - UI action

- (IBAction)clickTabSettingGeneral:(id)sender {
    self.tmpSelectedDevice = [MGMonitorController sharedMonitorController].selectedDevice;
    self.infoLabel.stringValue = self.tmpSelectedDevice ? self.tmpSelectedDevice.name : @"Please select a device";
    self.tfMacPassword.stringValue = [MGMonitorController sharedMonitorController].password ? : @"";

    [self switchToTabView:self.settingGeneralView withAnimation:YES];
}

- (IBAction)clickTabSettingApp:(id)sender {
    self.checkAutoStartMonitor.state = [ConfigManager isAutoStartMonitor] ? NSOnState : NSOffState;

    [self switchToTabView:self.settingAppView withAnimation:YES];
}

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

- (IBAction)stop:(id)sender
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
    [ConfigManager saveFavoriteDevice:[MGMonitorController sharedMonitorController].selectedDevice.addressString];
    [ConfigManager setThresholdRSSI:kDefaultInRangeThreshold forDevice:[MGMonitorController sharedMonitorController].selectedDevice.addressString];
    [ConfigManager savePassword:[MGMonitorController sharedMonitorController].password forUser:[MGMonitorController sharedMonitorController].userUID];

    // leave some time for stop
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kMGMonitorTrackerTimeInteval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[DeviceTracker sharedTracker] startMonitoring];
        [(AppDelegate *)[NSApplication sharedApplication].delegate updateStatusOfStatusBar];
    });

    [self.window close];
}

- (IBAction)clickCheckAutoStartMonitor:(id)sender {
    BOOL autoStart = (self.checkAutoStartMonitor.state == NSOnState);
    [ConfigManager setAutoStartMonitor:autoStart];
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
