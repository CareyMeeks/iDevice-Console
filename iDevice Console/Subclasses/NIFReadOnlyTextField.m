//
//  NIFReadOnlyTextField.m
//  iDevice Console
//
//  Created by Terry Lewis on 24/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFReadOnlyTextField.h"

@interface NIFReadOnlyTextField () <NSTextFieldDelegate>
@end

@implementation NIFReadOnlyTextField

- (instancetype)initWithFrame:(NSRect)frameRect{
    if (self = [super initWithFrame:frameRect]) {
        self.delegate = self;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL)textShouldBeginEditing:(NSText *)textObject{
    return NO;
}

@end
