//
//  MGMonitorController.m
//  MacGuarder
//
//  Created by user on 8/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "MGMonitorController.h"
#import "LogFormatter.h"

extern int ddLogLevel;

@interface MGMonitorController ()

@property (nonatomic, readwrite, strong) NSString *userUID;

@end

@implementation MGMonitorController

+ (MGMonitorController *)sharedMonitorController
{
    static MGMonitorController *sharedInstance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MGMonitorController alloc] init];
        sharedInstance.userUID = [NSString stringWithFormat:@"%d", getuid()];

        [sharedInstance setupDeviceTracker];
    });
    return sharedInstance;
}

- (void)setupDeviceTracker
{
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

- (BOOL)isReadyToManuallyStartMonitor
{
    return (self.password.length > 0) && (self.selectedDevice || [DeviceKeeper getFavoriteDevicesForUser:nil].count > 0);
}

- (void)automaticallyStartMonitor
{
    [self trackFavoriteDevicesNow];
}

- (void)trackFavoriteDevicesNow
{
    if (!self.selectedDevice) {
        NSArray *favoriteDevices = [DeviceKeeper getFavoriteDevicesForUser:nil];

        if (favoriteDevices && (favoriteDevices.count > 0)) {
            NSString *theFavoriteDevice = [favoriteDevices firstObject];

            // construct favorite device
            BluetoothDeviceAddress *deviceAddress = malloc(sizeof(BluetoothDeviceAddress));
            IOBluetoothNSStringToDeviceAddress(theFavoriteDevice, deviceAddress);
            self.selectedDevice = [IOBluetoothDevice deviceWithAddress:deviceAddress];
            if (deviceAddress) {
                free(deviceAddress);
            }
        }
    }

    if (!self.selectedDevice) {
        DDLogWarn(@"no favorite device to monitor automatically");
        return;
    }

    [DeviceTracker sharedTracker].device = self.selectedDevice;
    DDLogInfo(@"monitoring favorite device: %@ [%@]", [DeviceTracker sharedTracker].device.name, [DeviceTracker sharedTracker].device.addressString);

    [MacGuarderHelper setPassword:[DeviceKeeper getPasswordForUser:self.userUID]];

    if (![[DeviceTracker sharedTracker] isMonitoring]) {
        [[DeviceTracker sharedTracker] startMonitoring];
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

@end
