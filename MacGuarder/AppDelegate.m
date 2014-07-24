//
//  AppDelegate.m
//  MacGuarder
//
//  Created by user on 14-7-23.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import "AppDelegate.h"
#import "MacGuarderHelper.h"
#import "DeviceTracker.h"
#import "DeviceKeeper.h"

#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"


@implementation AppDelegate

- (IBAction)didClickSelectDevice:(id)sender
{
    self.lbSelectedDevice.stringValue = @"Selecting Device";
    [[DeviceTracker sharedTracker] selectDevice];
    
    if ([DeviceTracker sharedTracker].device) {
        if (![DeviceKeeper deviceExists:[DeviceTracker sharedTracker].device.addressString]) {
            // save this device
            NSLog(@"save threshold of device %@: %d", [DeviceTracker sharedTracker].device.name, kDefaultInRangeThreshold);
            [DeviceKeeper setThresholdRSSI:kDefaultInRangeThreshold forDevice:[DeviceTracker sharedTracker].device.addressString];
        }
        
        self.btStart.Hidden = NO;
        self.lbSelectedDevice.stringValue = [DeviceTracker sharedTracker].device.name;
        NSLog(@"select device: %@ [%@]", [DeviceTracker sharedTracker].device.name, [DeviceTracker sharedTracker].device.addressString);
    } else {
        self.lbSelectedDevice.stringValue = @"No Device Selected";
    }
}

- (IBAction)didClickStart:(id)sender
{
    self.btSelectDevice.Hidden = YES;
    self.btStart.Hidden = YES;
    [self.tfMacPassword setEditable:NO];
    [MacGuarderHelper setPassword:self.tfMacPassword.stringValue];
    if (![[DeviceTracker sharedTracker] isMonitoring]) {
        [[DeviceTracker sharedTracker] startMonitoring];
    }
    self.btStop.Hidden = NO;
}

- (IBAction)didClickStop:(id)sender
{
    self.btStop.Hidden = YES;
    [[DeviceTracker sharedTracker] stopMonitoring];
    [self.tfMacPassword setEditable:YES];
    self.btStart.Hidden = NO;
    self.btSelectDevice.Hidden = NO;
}

- (IBAction)didClickQuit:(id)sender
{
    [[DeviceTracker sharedTracker] stopMonitoring];
    [[NSRunningApplication currentApplication] terminate];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    /* By Web Server
    @autoreleasepool {
         
        // create server
        GCDWebServer* webServer = [[GCDWebServer alloc] init];
        
        // lock
        [webServer addHandlerForMethod:@"GET"
                                  path:@"/lock"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                              NSDictionary *requestDic = [request query];
                              if (requestDic && [[requestDic valueForKey:@"user"] isEqualToString:@"goku"]) {
                                  [MacGuarderHelper lock];
                                  return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Locked!</p></body></html>"];
                              } else {
                                  return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Error</p></body></html>"];
                              }
                          }];
        // unlock
        [webServer addHandlerForMethod:@"GET"
                                  path:@"/unlock"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                              NSDictionary *requestDic = [request query];
                              if (requestDic && [[requestDic valueForKey:@"user"] isEqualToString:@"goku"]) {
                                  [MacGuarderHelper setPassword:@"goku"];   // set password to unlock
                                  [MacGuarderHelper unlock];
                                  return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Unlocked!</p></body></html>"];
                              } else {
                                  return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Error</p></body></html>"];
                              }
                          }];
        
        // run server in main thread, until SIGINT (Ctrl-C in Terminal) or SIGTERM is received.
        [webServer runWithPort:1234 bonjourName:nil];
        NSLog(@"Visit %@ in your web browser", webServer.serverURL);
    }
    //*/


    //* By BLE
    self.btStart.Hidden = YES;
    self.btStop.Hidden = YES;
    
    [DeviceTracker sharedTracker].deviceSelectedBlock = ^(DeviceTracker *tracker){
        // TODO
    };
    [DeviceTracker sharedTracker].deviceRangeStatusUpdateBlock = ^(DeviceTracker *tracker){
        if (tracker.deviceInRange) {
            if ([MacGuarderHelper isScreenLocked]) {
                NSLog(@"unlock Mac");
                [MacGuarderHelper unlock];
            } else {
                NSLog(@"Mac was unlocked already, do nothing.");
            }
        } else {
            if (![MacGuarderHelper isScreenLocked]) {
                NSLog(@"lock Mac");
                [MacGuarderHelper lock];
            } else {
                NSLog(@"Mac was locked already, do nothing.");
            }
        }
    };
    //*/
    
}

@end
