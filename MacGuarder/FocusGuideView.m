//
//  FocusInfoGuideView.m
//  MacGuarder
//
//  Created by user on 8/14/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "FocusGuideView.h"
#import "QuartzCore/QuartzCore.h"
#import "NS(Attributed)String+Geometrics.h"

static NSUInteger const padding = 4;
static NSUInteger const margin = 12;
static NSUInteger const fontSize = 14;

@interface FocusGuideView ()

@property (nonatomic, strong) CALayer *focusLayer;
@property (nonatomic, strong) CATextLayer *focusTitleLayer;

@property (nonatomic, strong) NSString *focusTitle;
@property (nonatomic, assign) NSUInteger focusTitleHeight;
@property (nonatomic, strong) NSColor *focusColor;
@property (nonatomic, assign) NSInteger repeatTimes;

@property (nonatomic, copy) void(^callback)();

@end

@implementation FocusGuideView

- (void)focusOnView:(NSView *)focusView
    withRepeatTimes:(NSInteger)repeatTimes
         focusTitle:(NSString *)focusTitle
         focusColor:(NSColor *)focusColor
           callback:(void(^)())callback
{
    [self stopShaking];

    self.focusTitle = focusTitle;
    self.focusColor = focusColor ? : [NSColor redColor];
    self.repeatTimes = repeatTimes;
    self.callback = callback;

    NSRect frame = focusView.frame;

    self.focusTitleHeight = [focusTitle heightForWidth:(frame.size.width + 2*margin) font:[NSFont systemFontOfSize:fontSize]] + (margin - padding);

    frame.origin.x -= margin;
    frame.origin.y -= (margin + self.focusTitleHeight);
    frame.size.width += 2*margin;
    frame.size.height += (2*margin + self.focusTitleHeight);

    self.frame = frame;
    [focusView.superview addSubview:self];

    [self startShaking];
}

- (void)manuallyUnfocus
{
    [self stopShaking];

    [self removeFromSuperview];

    if (self.callback) {
        self.callback();
    }
}

- (void)startShaking
{
    [self stopShaking];

    self.layer.borderWidth = 0;
    self.layer.cornerRadius = margin;
    self.layer.backgroundColor = [self.focusColor colorWithAlphaComponent:0.4].CGColor;

    self.focusLayer = [[CALayer alloc] init];
    self.focusLayer.bounds = CGRectMake(0, 0, self.bounds.size.width - 2*(margin - padding), self.bounds.size.height - self.focusTitleHeight - 2*(margin - padding));
    self.focusLayer.borderWidth = 0;
    self.focusLayer.cornerRadius = padding;
    self.focusLayer.borderColor = self.focusColor.CGColor;
    self.focusLayer.position = CGPointMake(self.bounds.size.width/2, self.focusTitleHeight + (self.bounds.size.height - self.focusTitleHeight)/2);
    [self.layer addSublayer:self.focusLayer];

    self.focusTitleLayer = [[CATextLayer alloc] init];
    self.focusTitleLayer.bounds = CGRectMake(0, 0, self.focusLayer.bounds.size.width, self.focusTitleHeight - (margin - padding));
    self.focusTitleLayer.position = CGPointMake(self.bounds.size.width/2, (margin - padding) + self.focusTitleLayer.bounds.size.height/2);
    self.focusTitleLayer.cornerRadius = padding;
    self.focusTitleLayer.alignmentMode = @"center";
    self.focusTitleLayer.wrapped = YES;
    self.focusTitleLayer.truncationMode = @"end";
    self.focusTitleLayer.font = (__bridge CFTypeRef)([NSFont systemFontOfSize:0]);
    self.focusTitleLayer.fontSize = fontSize;
    self.focusTitleLayer.contentsScale = [[NSScreen mainScreen] backingScaleFactor];
    self.focusTitleLayer.foregroundColor = self.focusColor.CGColor;
    self.focusTitleLayer.backgroundColor = [NSColor whiteColor].CGColor;
    self.focusTitleLayer.string = self.focusTitle;
    [self.layer addSublayer:self.focusTitleLayer];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"borderWidth"];
    animation.fromValue = @1;
    animation.toValue = @(padding);
    animation.duration = 0.5;
    animation.autoreverses = YES;
    animation.repeatCount = self.repeatTimes;
    [self.focusLayer addAnimation:animation forKey:@"shake"];

    if (self.repeatTimes != HUGE_VAL) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((self.repeatTimes + 1) * 0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.superview) {
                [self manuallyUnfocus];
            }
        });
    }
}

- (void)stopShaking
{
    [self.focusLayer removeAllAnimations];
    [self.focusLayer removeFromSuperlayer];
    self.focusLayer = nil;

    [self.focusTitleLayer removeFromSuperlayer];
    self.focusTitleLayer = nil;
}

- (instancetype)init {
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        self.layer = [[CALayer alloc] init];
        self.wantsLayer = YES;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

// !!! do not use mouseDown here !!!
//   if self is focused on a button (button's action is to open a model panel),
//     then mouseDown: is firstly captured by self, then pass to button by [super mouseUp:theEvent].
//     but self is stuck right between [super mouseUp:theEvent] and [self manuallyUnfocus], because it is waiting for model panel to return.
//     after model panel returns, self has already released because of our dispatch_after, then when it comes to [self manuallyUnfocus], self is BAD_ACCESS.
//   for mouseUp:, self will not capture this event, it is ate by button.
//
- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];

    [self manuallyUnfocus];
}

@end
