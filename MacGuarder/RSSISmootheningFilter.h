
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
