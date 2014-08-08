//
//  AppDelegate.h
//  MacGuarder
//
//  Created by user on 14-7-23.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SecurityInterface/SFAuthorizationView.h>


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    __weak SFAuthorizationView *_authorizationView;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSButton *btSelectDevice;
@property (weak) IBOutlet NSButton *btSaveDevice;
@property (weak) IBOutlet NSTextField *lbSelectedDevice;
@property (weak) IBOutlet NSSecureTextField *tfMacPassword;
@property (weak) IBOutlet NSButton *btStart;
@property (weak) IBOutlet NSButton *btStop;
@property (weak) IBOutlet NSButton *btQuit;

@property (weak) IBOutlet SFAuthorizationView *authorizationView;

@property (strong) NSString *user;  // uid of current user

@end
