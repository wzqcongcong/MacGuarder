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


#define kAUTH_RIGHT_CONFIG_MODIFY    "com.trendmicro.iTIS.MacGuarder"


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
    self.tfMacPassword.Enabled = NO;
    
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
    
    self.tfMacPassword.Enabled = YES;
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
                self.tfMacPassword.Enabled = NO;
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

-(void)awakeFromNib
{
    // request a default admin user right
    // PS:
    // 1. This default admin user right is shared with other app, like Apple's Preferences->Sharing,
    //    this means the lock they use are in sync mode.
    //    Once the admin user logins Mac, this kind of right is got, and their locks are automatically unlocked.
    // 2. But Apple's Preferences->Users & Groups app uses a higher super root user right,
    //    even the admin user logins Mac, this kind of right is still not got, need to input password to get it.
    [_authorizationView setString:kAUTH_RIGHT_CONFIG_MODIFY];
    
    // setup
    [_authorizationView setAutoupdate:YES];
    [_authorizationView setDelegate:self];
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
    
    // mannually sync lock status of admin user rights
    [self.authorizationView updateStatus:nil];
    
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

#pragma mark - delegate

-(void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    _tfMacPassword.Enabled = YES;
    
    AuthorizationRights *rights = self.authorizationView.authorizationRights;
    AuthorizationItem *items = rights->items;
    for (int i=0; i < rights->count; ++i) {
        NSLog(@"%s", items[i].name);
    }
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{
    _tfMacPassword.Enabled = NO;
}

@end
