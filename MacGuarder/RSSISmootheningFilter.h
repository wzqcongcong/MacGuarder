//
//  RSSISmootheningFilter.h
//
//  Created by Bogdan Covaci on 29.11.2013.
//  Copyright (c) 2013 Alex Covaci. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDefaultNumberOfSamples     5

@interface RSSISmootheningFilter : NSObject

@property (nonatomic, assign) int numberOfSamples;

+ (RSSISmootheningFilter*)sharedInstance;
- (void)addSample:(int)value;
- (void)reset;
- (int)getMedianValue;
- (int)getMaximumVariation;
- (BOOL)isFilterFull;

@end
