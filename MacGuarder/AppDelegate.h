//
//  AppDelegate.h
//  MacGuarder
//
//  Created by user on 14-7-23.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSButton *btSelectDevice;
@property (assign) IBOutlet NSTextField *lbSelectedDevice;
@property (assign) IBOutlet NSSecureTextField *tfMacPassword;
@property (assign) IBOutlet NSButton *btStart;
@property (assign) IBOutlet NSButton *btStop;
@property (assign) IBOutlet NSButton *btQuit;

@end
