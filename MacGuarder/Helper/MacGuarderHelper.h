//
//  MacGuarderHelper.h
//  MacGuarder
//
//  Created by user on 14-7-23.
//  Copyright (c) 2014年 TrendMicro. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MacGuarderHelper : NSObject

+ (void)lock;
+ (void)unlock;

+ (NSString*)getPassword;
+ (void)setPassword:(NSString*)password;

@end
