//
//  LogFormatter.m
//  MacGuarder
//
//  Created by GoKu on 3/3/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "LogFormatter.h"

DDLogLevel ddLogLevel = DDLogLevelInfo;

@interface LogFormatter ()

@property (nonatomic, strong) NSDateFormatter *dateFormat;

@end

@implementation LogFormatter

+ (void)setupLog
{
    LogFormatter *logFormatter = [[LogFormatter alloc] init];

    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    [aslLogger setLogFormatter:logFormatter];
    [DDLog addLogger:aslLogger];

    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormatter];
    [DDLog addLogger:ttyLogger];

    NSString *logDir = [NSString stringWithFormat:@"%@/Library/Logs/%@", NSHomeDirectory(), [NSBundle mainBundle].bundleIdentifier];
    DDLogFileManagerDefault *logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logDir];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:(logFileManager)];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [fileLogger setLogFormatter:logFormatter];
    [DDLog addLogger:fileLogger];
}

+ (void)updateLogLevel:(DDLogLevel)newLogLevel
{
    ddLogLevel = newLogLevel;
}

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
