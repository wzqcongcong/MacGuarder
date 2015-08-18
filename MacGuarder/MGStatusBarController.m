//
//  MGStatusBarController.m
//  MacGuarder
//
//  Created by user on 8/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "MGStatusBarController.h"
#import "LogFormatter.h"
#import "MGMonitorController.h"
#import "AppDelegate.h"

extern int ddLogLevel;

@interface MGStatusBarController ()

@property (nonatomic, strong) NSStatusItem *statusItem;

@property (strong) IBOutlet NSMenu *statusBarMenu;
@property (weak) IBOutlet NSMenuItem *menuItemSettings;
@property (weak) IBOutlet NSMenuItem *menuItemStart;
@property (weak) IBOutlet NSMenuItem *menuItemStop;
@property (weak) IBOutlet NSMenuItem *menuItemQuit;

@end

@implementation MGStatusBarController

- (instancetype)init
{
    self = [super initWithNibName:@"MGStatusBarController" bundle:nil];
    if (self) {
        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    self.statusItem.toolTip = @"MacGuarder";
//    self.statusItem.title = self.statusItem.toolTip;
    self.statusItem.image = [NSImage imageNamed:@"monitor.idle"];
    [self.statusItem.image setTemplate:YES];
    self.statusItem.menu = self.statusBarMenu;
}

- (void)updateStatusOfStatusBar
{
    self.statusItem.image = [DeviceTracker sharedTracker].isMonitoring ? [NSImage imageNamed:@"monitor.working"] : [NSImage imageNamed:@"monitor.idle"];
    [self.statusItem.image setTemplate:YES];
    [self.statusBarMenu update];
}

- (IBAction)clickMenuItemSettings:(id)sender {
    [(AppDelegate *)[NSApplication sharedApplication].delegate showSettingsWindow];
}

- (IBAction)clickMenuItemStart:(id)sender {
    if ((![DeviceTracker sharedTracker].isMonitoring) && [[MGMonitorController sharedMonitorController] isPreparedToStartMonitor]) {
        [[DeviceTracker sharedTracker] startMonitoring];
        [self updateStatusOfStatusBar];
    }
}

- (IBAction)clickMenuItemStop:(id)sender {
    [[DeviceTracker sharedTracker] stopMonitoring];
    [self updateStatusOfStatusBar];
}

- (IBAction)clickMenuItemQuit:(id)sender {
    [[DeviceTracker sharedTracker] stopMonitoring];
    [[NSRunningApplication currentApplication] terminate];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem == self.menuItemSettings || menuItem == self.menuItemQuit) {
        return YES;
    } else if (menuItem == self.menuItemStart) {
        return (![DeviceTracker sharedTracker].isMonitoring) && [[MGMonitorController sharedMonitorController] isPreparedToStartMonitor];
    } else if (menuItem == self.menuItemStop) {
        return [DeviceTracker sharedTracker].isMonitoring;
    } else {
        return NO;
    }
}

@end
