//
//  FocusInfoGuideView.h
//  MacGuarder
//
//  Created by user on 8/14/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FocusGuideView : NSView

- (instancetype)init;

- (void)focusOnView:(NSView *)focusView
    withRepeatTimes:(NSInteger)repeatTimes
         focusTitle:(NSString *)focusTitle
         focusColor:(NSColor *)focusColor
           callback:(void(^)())callback;

- (void)manuallyUnfocus;

@end
