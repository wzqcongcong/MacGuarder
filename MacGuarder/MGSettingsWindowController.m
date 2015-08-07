//
//  MGSettingsWindowController.m
//  MacGuarder
//
//  Created by user on 8/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "MGSettingsWindowController.h"
#import <SecurityInterface/SFAuthorizationView.h>
#import "MacGuarderHelper.h"
#import "DeviceTracker.h"
#import "DeviceKeeper.h"
#import "LogFormatter.h"

/*
 #import "GCDWebServer.h"
 #import "GCDWebServerDataResponse.h"
*/

extern int ddLogLevel;

static NSString * const kAUTH_RIGHT_CONFIG_MODIFY   = @"com.GoKuStudio.MacGuarder";

@interface MGSettingsWindowController ()

@property (weak) IBOutlet NSTextField *infoLabel;
@property (weak) IBOutlet NSButton *btSelectDevice;
@property (weak) IBOutlet NSButton *btSaveDevice;

@property (weak) IBOutlet NSSecureTextField *tfMacPassword;
@property (weak) IBOutlet SFAuthorizationView *authorizationView;

@property (weak) IBOutlet NSButton *btStart;
@property (weak) IBOutlet NSButton *btStop;
@property (weak) IBOutlet NSButton *btQuit;

@property (nonatomic, strong) NSString *userUID;  // uid of current user

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

    self.btSelectDevice.enabled = YES;
    self.btSaveDevice.enabled = NO;
    self.btStart.enabled = NO;
    self.btStop.enabled = NO;

    self.userUID = [NSString stringWithFormat:@"%d", getuid()];

    [self setupDeviceTracker];
}

- (void)setupDeviceTracker
{
    [DeviceTracker sharedTracker].deviceSelectedBlock = ^(DeviceTracker *tracker){

    };

    [DeviceTracker sharedTracker].deviceRangeStatusUpdateBlock = ^(DeviceTracker *tracker){
        if (tracker.deviceInRange) {
            if ([MacGuarderHelper isScreenLocked]) {
                DDLogInfo(@"unlock Mac");
                [MacGuarderHelper unlock];

            } else {
                DDLogInfo(@"Mac was unlocked already, do nothing.");
            }

        } else {
            if (![MacGuarderHelper isScreenLocked]) {
                DDLogInfo(@"lock Mac");
                [MacGuarderHelper lock];

            } else {
                DDLogInfo(@"Mac was locked already, do nothing.");
            }
        }
    };
}

- (void)startMonitor
{
    [self trackFavoriteDevicesNow];
}

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
            if (deviceAddress) {
                free(deviceAddress);
            }

            if ([DeviceTracker sharedTracker].device) {
                DDLogInfo(@"tracking favorite device: %@ [%@]", [DeviceTracker sharedTracker].device.name, theFavoriteDevice);

                self.infoLabel.stringValue = [DeviceTracker sharedTracker].device.name;
                self.btSelectDevice.enabled = NO;
                self.btSaveDevice.enabled = NO;
                self.btStart.enabled = NO;
                self.btStop.enabled = YES;

                self.tfMacPassword.stringValue = [DeviceKeeper getPasswordForUser:self.userUID];
                self.tfMacPassword.enabled = NO;
                [MacGuarderHelper setPassword:self.tfMacPassword.stringValue];

                if (![[DeviceTracker sharedTracker] isMonitoring]) {
                    [[DeviceTracker sharedTracker] startMonitoring];
                }

            } else {
                DDLogWarn(@"no favorite device to track");
            }
        }
    }
}

/*
- (void)trackFavoriteDevicesNowByWebServer
{
    @autoreleasepool {
        // create server
        GCDWebServer* webServer = [[GCDWebServer alloc] init];

        // lock
        [webServer addHandlerForMethod:@"GET"
                                  path:@"/lock"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                              NSDictionary *requestDic = [request query];
                              if (requestDic && [[requestDic valueForKey:@"user"] isEqualToString:@"GoKu"]) {
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
                              if (requestDic && [[requestDic valueForKey:@"user"] isEqualToString:@"GoKu"]) {
                                  [MacGuarderHelper setPassword:@"goku"];   // set password to unlock
                                  [MacGuarderHelper unlock];
                                  return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Unlocked!</p></body></html>"];
                              } else {
                                  return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Error</p></body></html>"];
                              }
                          }];

        // run server in main thread, until SIGINT (Ctrl-C in Terminal) or SIGTERM is received.
        [webServer runWithPort:1234 bonjourName:nil];
        
        DDLogInfo(@"Visit %@ in your web browser", webServer.serverURL);
    }
}
//*/

#pragma mark - UI action

- (IBAction)didClickSelectDevice:(id)sender
{
    self.infoLabel.stringValue = @"Selecting Device";
    [[DeviceTracker sharedTracker] selectDevice];

    if ([DeviceTracker sharedTracker].device) {
        if (![DeviceKeeper deviceExists:[DeviceTracker sharedTracker].device.addressString]) {
            // save config for this device
            DDLogInfo(@"save threshold of device %@: %ld", [DeviceTracker sharedTracker].device.name, kDefaultInRangeThreshold);
            [DeviceKeeper setThresholdRSSI:kDefaultInRangeThreshold ofDevice:[DeviceTracker sharedTracker].device.addressString forUser:nil];
        }

        self.btSaveDevice.enabled = YES;
        self.btStart.enabled = YES;
        self.btStop.enabled = NO;
        self.infoLabel.stringValue = [DeviceTracker sharedTracker].device.name;
        DDLogInfo(@"select device: %@ [%@]", [DeviceTracker sharedTracker].device.name, [DeviceTracker sharedTracker].device.addressString);

    } else {
        self.infoLabel.stringValue = @"No Device Selected";
    }
}

- (IBAction)didClickSaveDevice:(id)sender {
    if (self.tfMacPassword.stringValue.length == 0) {
        self.infoLabel.stringValue = @"Please input your login passwork!";
        return;
    } else {
        self.infoLabel.stringValue = [DeviceTracker sharedTracker].device.name;
    }

    if ([DeviceTracker sharedTracker].device) {
        [DeviceKeeper saveFavoriteDevice:[DeviceTracker sharedTracker].device.addressString forUser:nil];
    }
    [DeviceKeeper savePassword:self.tfMacPassword.stringValue forUser:self.userUID];
}

- (IBAction)didClickStart:(id)sender
{
    if (self.tfMacPassword.stringValue.length == 0) {
        self.infoLabel.stringValue = @"Please input your login passwork!";
        return;
    } else {
        self.infoLabel.stringValue = [DeviceTracker sharedTracker].device.name;
    }

    self.btStart.enabled = NO;
    self.btSelectDevice.enabled = NO;
    self.btSaveDevice.enabled = NO;
    self.tfMacPassword.enabled = NO;
    self.btStop.enabled = YES;

    [MacGuarderHelper setPassword:self.tfMacPassword.stringValue];
    if (![[DeviceTracker sharedTracker] isMonitoring]) {
        [[DeviceTracker sharedTracker] startMonitoring];
    }
}

- (IBAction)didClickStop:(id)sender
{
    self.btStop.enabled = NO;
    self.tfMacPassword.enabled = YES;
    self.btStart.enabled = YES;
    self.btSelectDevice.enabled = YES;
    self.btSaveDevice.enabled = YES;

    [[DeviceTracker sharedTracker] stopMonitoring];
}

- (IBAction)didClickQuit:(id)sender
{
    [[DeviceTracker sharedTracker] stopMonitoring];
    [[NSRunningApplication currentApplication] terminate];
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
