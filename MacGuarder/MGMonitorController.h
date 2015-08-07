//
//  MGMonitorController.h
//  MacGuarder
//
//  Created by user on 8/7/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DeviceKeeper.h"
#import "DeviceTracker.h"
#import "MacGuarderHelper.h"

@interface MGMonitorController : NSObject

@property (nonatomic, readonly, strong) NSString *userUID;  // uid of current user
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) IOBluetoothDevice *selectedDevice;

+ (MGMonitorController *)sharedMonitorController;

- (BOOL)isReadyToManuallyStartMonitor;
- (void)automaticallyStartMonitor;

@end
