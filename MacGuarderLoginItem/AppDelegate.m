//
//  AppDelegate.m
//  MacGuarderLoginItem
//
//  Created by GoKu on 9/13/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    [self quitAfterLaunchWrapperApp];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)quitAfterLaunchWrapperApp
{
    NSString *wrapperAppBundleID = [self wrapperAppBundleID];
    if (![self isAppRunning:wrapperAppBundleID]) {
        [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:wrapperAppBundleID
                                                             options:NSWorkspaceLaunchDefault
                                      additionalEventParamDescriptor:nil
                                                    launchIdentifier:NULL];
    }

    [[NSApplication sharedApplication] terminate:self];
}

- (NSString *)wrapperAppBundleID
{
    NSString *bundleID = nil;

    NSString *wrapperAppBundlePath = [NSBundle mainBundle].bundlePath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSBundle *wrapperAppBundle = [NSBundle bundleWithPath:wrapperAppBundlePath];
    if (wrapperAppBundle) {
        bundleID = wrapperAppBundle.bundleIdentifier;
        NSLog(@"%@", bundleID);
    }

    return bundleID;
}

- (BOOL)isAppRunning:(NSString *)appBundleID
{
    if (appBundleID.length > 0) {
        NSArray *runningApp = [NSRunningApplication runningApplicationsWithBundleIdentifier:appBundleID];
        if (runningApp.count > 0) {
            return YES;
        }
        return NO;

    } else {
        NSLog(@"invalid app bundleID: %@", appBundleID);
        return NO;
    }
}

@end
