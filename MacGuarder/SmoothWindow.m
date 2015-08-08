//
//  SmoothWindow.m
//  MacGuarder
//
//  Created by GoKu on 8/8/15.
//  Copyright (c) 2015 GoKuStudio. All rights reserved.
//

#import "SmoothWindow.h"

@implementation SmoothWindow

- (NSTimeInterval)animationResizeTime:(NSRect)newWindowFrame
{
    // can control the animation duration in @selector(setFrame:display:animate:)
    // default value: 0.2
    return 1.0;
}

@end
