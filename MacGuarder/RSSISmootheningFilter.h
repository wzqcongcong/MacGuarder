//
//  RSSISmootheningFilter.h
//
//  Created by Bogdan Covaci on 29.11.2013.
//  Copyright (c) 2013 Alex Covaci. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RSSISmootheningFilter : NSObject

+ (RSSISmootheningFilter*)sharedInstance;
- (void)addSample:(int)value;
- (void)reset;
- (int)getMedianValue;
- (int)getMaximumVariation;
- (BOOL)isFilterFull;

@property (nonatomic, assign) int numberOfSamples;

@end
