//
//  LogFormatter.m
//  MacGuarder
//
//  Created by GoKu on 3/3/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "LogFormatter.h"

@interface LogFormatter ()

@property (nonatomic, strong) NSDateFormatter *dateFormat;

@end

@implementation LogFormatter

- (id)init
{
    self = [super init];
    if (self) {
        _dateFormat = [[NSDateFormatter alloc] init];
        [_dateFormat setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
        [_dateFormat setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *logLevel;
    switch (logMessage->_flag)
    {
        case DDLogFlagError     : logLevel = @"[ERRO]"; break;
        case DDLogFlagWarning   : logLevel = @"[WARN]"; break;
        case DDLogFlagInfo      : logLevel = @"[INFO]"; break;
        default                 : logLevel = @"[VERB]"; break;
    }

    NSString *dateAndTime = [self.dateFormat stringFromDate:(logMessage->_timestamp)];

    return [NSString stringWithFormat:@"%@, %@, %@", dateAndTime, logLevel, logMessage->_message];
}

@end
