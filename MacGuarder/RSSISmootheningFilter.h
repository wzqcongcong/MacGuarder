
#import <Foundation/Foundation.h>

@interface RSSISmootheningFilter : NSObject

@property (nonatomic, assign) NSInteger numberOfSamples;

+ (RSSISmootheningFilter *)sharedInstance;

- (void)addSample:(NSInteger)value;
- (void)reset;
- (NSInteger)getMedianValue;
- (NSInteger)getMaximumVariation;
- (BOOL)isFilterFull;

@end
