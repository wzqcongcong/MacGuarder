//
//  LogFormatter.m
//  MacGuarder
//
//  Created by user on 3/3/15.
//  Copyright (c) 2015 TrendMicro. All rights reserved.
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
    switch (logMessage->logFlag)
    {
        case LOG_FLAG_ERROR : logLevel = @"[ERRO]"; break;
        case LOG_FLAG_WARN  : logLevel = @"[WARN]"; break;
        case LOG_FLAG_INFO  : logLevel = @"[INFO]"; break;
        default             : logLevel = @"[VERB]"; break;
    }

    NSString *dateAndTime = [self.dateFormat stringFromDate:(logMessage->timestamp)];

    return [NSString stringWithFormat:@"%@, %@, %@", dateAndTime, logLevel, logMessage->logMsg];
}

@end
