//
//  AppDelegate.m
//  MacGuarder
//
//  Created by GoKu on 14-7-23.
//  Copyright (c) 2014年 GoKuStudio. All rights reserved.
//

#import "AppDelegate.h"
#import "LogFormatter.h"
#import "MGMonitorController.h"
#import "MGStatusBarController.h"
#import "MGSettingsWindowController.h"

@interface AppDelegate ()

@property (nonatomic, strong) MGStatusBarController *statusBarController;
@property (nonatomic, strong) MGSettingsWindowController *settingsWindowController;

@end

@implementation AppDelegate

- (BOOL)setupLoginItem
{
    BOOL ret = SMLoginItemSetEnabled((__bridge CFStringRef)kLoginItemBundleID, [ConfigManager loginItemEnabled]);
    return ret;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [LogFormatter setupLog];

    [MGMonitorController sharedMonitorController]; // just init MGMonitorController

    self.statusBarController = [[MGStatusBarController alloc] init];
    self.statusBarController.view.hidden = YES; // load status bar menu
    [self updateStatusOfStatusBar];

    if ([ConfigManager isAutoStartMonitor]) {
        if ([[MGMonitorController sharedMonitorController] isPreparedToStartMonitor]) {
            [[MGMonitorController sharedMonitorController] automaticallyStartMonitor];
            [self updateStatusOfStatusBar];
        }
    }

//    [self showSettingsWindow];

    [self setupLoginItem];
}

- (void)showSettingsWindow
{
    if (!self.settingsWindowController) {
        self.settingsWindowController = [[MGSettingsWindowController alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(settingWindowWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:self.settingsWindowController.window];
    }

    // show dock
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    [self.settingsWindowController showWindow:self];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.settingsWindowController.window orderFront:self];
}

- (void)updateStatusOfStatusBar
{
    [self.statusBarController updateStatusOfStatusBar];
}

-(void)settingWindowWillClose:(NSNotification*)notification
{
    NSWindow *sender = [notification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSWindowWillCloseNotification
                                                  object:sender];
    self.settingsWindowController = nil;
}

@end
