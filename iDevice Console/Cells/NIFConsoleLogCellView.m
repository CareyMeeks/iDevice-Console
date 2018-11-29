//
//  NIFConsoleLogCellView.m
//  iConsole
//
//  Created by Terry Lewis on 10/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFConsoleLogCellView.h"

@interface NIFConsoleLogCellView () <NSTextFieldDelegate>

@end

@implementation NIFConsoleLogCellView

- (instancetype)initWithCoder:(NSCoder *)coder{
    if (self = [super initWithCoder:coder]) {
    }
    return self;
}

- (void)setTextField:(NSTextField *)textField{
    [super setTextField:textField];
    self.textField.delegate = self;
    [self.textField setRefusesFirstResponder:YES];
//    self.textField.drawsBackground = YES;
//    self.textField.backgroundColor = [NSColor redColor];
}

#pragma mark - textField

//- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor{
//    self.textField.drawsBackground = YES;
//    self.textField.backgroundColor = [NSColor whiteColor];
//    return NO;
//}
//
//- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
//    self.layer.backgroundColor = [NSColor clearColor].CGColor;
//    self.textField.drawsBackground = NO;
//    return NO;
//}

- (NSBackgroundStyle)backgroundStyle{
    return NSBackgroundStyleLowered;
}

@end
