//
//  NIFDeviceOutlineView.m
//  iDevice Console
//
//  Created by Terry Lewis on 5/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFDeviceOutlineView.h"
#import "NIFConsoleWindowControllerModel.h"

@implementation NIFDeviceOutlineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (NSMenu *)menu{
    return [_model menuForSelectedDevice];
}

- (BOOL)acceptsFirstResponder{
    return NO;
}

@end
