//
//  MacGuarderHelper.h
//  MacGuarder
//
//  Created by GoKu on 14-7-23.
//  Copyright (c) 2014年 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MacGuarderHelper : NSObject

+ (BOOL)isScreenLocked;                     // check if Mac is locked

+ (void)lock;                               // lock the Mac
+ (void)unlock;                             // unlock the Mac

+ (void)setPassword:(NSString *)password;   // set Mac password

@end
