//
//  NIFBottomHairlineView.m
//  iDevice Console
//
//  Created by Terry Lewis on 24/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFBottomHairlineView.h"

@implementation NIFBottomHairlineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
//    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    static CGFloat channel = 170.0f/255.0f;
    static CGFloat y = 0.5f;
    [[NSColor colorWithRed:channel green:channel blue:channel alpha:1.0f] set];
    [NSBezierPath setDefaultLineWidth:0.0f];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(0, y)
                              toPoint:NSMakePoint(dirtyRect.size.width, y)];
}

@end
