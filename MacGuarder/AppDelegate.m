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

int ddLogLevel = DDLogLevelInfo;

@interface AppDelegate ()

@property (nonatomic, strong) MGStatusBarController *statusBarController;
@property (nonatomic, strong) MGSettingsWindowController *settingsWindowController;

@end

@implementation AppDelegate

+ (void)setupLog
{
    LogFormatter *logFormatter = [[LogFormatter alloc] init];

    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    [aslLogger setLogFormatter:logFormatter];
    [DDLog addLogger:aslLogger];

    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormatter];
    [DDLog addLogger:ttyLogger];

    NSString *logDir = [NSString stringWithFormat:@"%@/Library/Logs/GoKuStudio/MacGuarder", NSHomeDirectory()];
    DDLogFileManagerDefault *logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logDir];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:(logFileManager)];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [fileLogger setLogFormatter:logFormatter];
    [DDLog addLogger:fileLogger];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [AppDelegate setupLog];

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
}

- (void)showSettingsWindow
{
    if (!self.settingsWindowController) {
        self.settingsWindowController = [[MGSettingsWindowController alloc] init];
    }

    [self.settingsWindowController showWindow:self];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.settingsWindowController.window orderFront:self];
}

- (void)updateStatusOfStatusBar
{
    [self.statusBarController updateStatusOfStatusBar];
}

@end
