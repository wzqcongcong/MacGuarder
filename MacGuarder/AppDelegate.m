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

/*
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
*/

@implementation AppDelegate

#pragma mark - UI action

- (IBAction)didClickSelectDevice:(id)sender
{
    self.lbSelectedDevice.stringValue = @"Selecting Device";
    [[DeviceTracker sharedTracker] selectDevice];
    
    if ([DeviceTracker sharedTracker].device) {
        if (![DeviceKeeper deviceExists:[DeviceTracker sharedTracker].device.addressString]) {
            // save config for this device
            NSLog(@"save threshold of device %@: %d", [DeviceTracker sharedTracker].device.name, kDefaultInRangeThreshold);
            [DeviceKeeper setThresholdRSSI:kDefaultInRangeThreshold ofDevice:[DeviceTracker sharedTracker].device.addressString forUser:nil];
        }
        
        self.btSaveDevice.Enabled = YES;
        self.btStart.Enabled = YES;
        self.btStop.Enabled = NO;
        self.lbSelectedDevice.stringValue = [DeviceTracker sharedTracker].device.name;
        NSLog(@"select device: %@ [%@]", [DeviceTracker sharedTracker].device.name, [DeviceTracker sharedTracker].device.addressString);
        
    } else {
        self.lbSelectedDevice.stringValue = @"No Device Selected";
    }
}

- (IBAction)didClickSaveDevice:(id)sender {
    if ([DeviceTracker sharedTracker].device) {
        [DeviceKeeper saveFavoriteDevice:[DeviceTracker sharedTracker].device.addressString forUser:nil];
    }
    [DeviceKeeper savePassword:self.tfMacPassword.stringValue forUser:self.user];
}

- (IBAction)didClickStart:(id)sender
{
    self.btStart.Enabled = NO;
    self.btSelectDevice.Enabled = NO;
    self.btSaveDevice.Enabled = NO;
    [self.tfMacPassword setEditable:NO];
    
    [MacGuarderHelper setPassword:self.tfMacPassword.stringValue];
    if (![[DeviceTracker sharedTracker] isMonitoring]) {
        [[DeviceTracker sharedTracker] startMonitoring];
    }
    
    self.btStop.Enabled = YES;
}

- (IBAction)didClickStop:(id)sender
{
    self.btStop.Enabled = NO;
    
    [[DeviceTracker sharedTracker] stopMonitoring];
    
    [self.tfMacPassword setEditable:YES];
    self.btStart.Enabled = YES;
    self.btSelectDevice.Enabled = YES;
    self.btSaveDevice.Enabled = YES;
}

- (IBAction)didClickQuit:(id)sender
{
    [[DeviceTracker sharedTracker] stopMonitoring];
    [[NSRunningApplication currentApplication] terminate];
}

- (IBAction)testService:(id)sender {
    [[DeviceTracker sharedTracker] testService];
}

#pragma mark - startup

- (void)trackFavoriteDevicesNow
{
    NSArray *favoriteDevices = [DeviceKeeper getFavoriteDevicesForUser:nil];
    if (favoriteDevices) {
        NSString *theFavoriteDevice = [favoriteDevices firstObject];
        
        if (theFavoriteDevice) {
            // construct favorite device
            BluetoothDeviceAddress *deviceAddress = malloc(sizeof(BluetoothDeviceAddress));
            IOBluetoothNSStringToDeviceAddress(theFavoriteDevice, deviceAddress);
            [DeviceTracker sharedTracker].device = [IOBluetoothDevice deviceWithAddress:deviceAddress];
            if (deviceAddress) free(deviceAddress);
            
            if ([DeviceTracker sharedTracker].device) {
                NSLog(@"tracking favorite device: %@ [%@]", [DeviceTracker sharedTracker].device.name, theFavoriteDevice);
                
                self.lbSelectedDevice.stringValue = [DeviceTracker sharedTracker].device.name; // cache
                self.btSelectDevice.Enabled = NO;
                self.btSaveDevice.Enabled = NO;
                self.btStart.Enabled = NO;
                
                self.tfMacPassword.stringValue = [DeviceKeeper getPasswordForUser:self.user];
                [self.tfMacPassword setEditable:NO];
                [MacGuarderHelper setPassword:self.tfMacPassword.stringValue];
                
                if (![[DeviceTracker sharedTracker] isMonitoring]) {
                    [[DeviceTracker sharedTracker] startMonitoring];
                }
                self.btStop.Enabled = YES;
                
            } else {
                NSLog(@"no favorite device to track");
            }
        }
    }
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
    self.btSelectDevice.Enabled = YES;
    self.btSaveDevice.Enabled = NO;
    self.btStart.Enabled = NO;
    self.btStop.Enabled = NO;
    
    [DeviceTracker sharedTracker].deviceSelectedBlock = ^(DeviceTracker *tracker){
        // TODO
    };
    [DeviceTracker sharedTracker].deviceRangeStatusUpdateBlock = ^(DeviceTracker *tracker){
        if (tracker.deviceInRange) {
            if ([MacGuarderHelper isScreenLocked]) {
                NSLog(@"unlock Mac");
                [MacGuarderHelper unlock];
            } else {
                NSLog(@"Mac was unlocked already, do Enabledthing.");
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
    
    // startup
    self.user = [NSString stringWithFormat:@"%d", getuid()];
    [self trackFavoriteDevicesNow];
    //*/
    
}

@end
