//
//  LogFormatter.h
//  MacGuarder
//
//  Created by GoKu on 3/3/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

extern DDLogLevel ddLogLevel;

@interface LogFormatter :  NSObject <DDLogFormatter>

+ (void)setupLog;
+ (void)updateLogLevel:(DDLogLevel)newLogLevel;

@end
