//
//  NIFOptionsPopoverViewController.m
//  iDevice Console
//
//  Created by Terry Lewis on 4/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFOptionsPopoverViewController.h"

@interface NIFOptionsPopoverViewController ()
@end

@implementation NIFOptionsPopoverViewController{
    NSString *_cachedProcessName;
    NSInteger _cachedCheckboxValue;
    NSPopover *_popover;
}

- (instancetype)initWithStoryboard:(NSStoryboard *)storyboard popover:(NSPopover *)popover{
    self = [storyboard instantiateControllerWithIdentifier:@"NIFOptionsPopoverViewController"];
    if (self) {
        _popover = popover;
    }
    return self;
}

+ (instancetype)viewControllerWithStoryboard:(NSStoryboard *)storyboard popover:(NSPopover *)popover{
    return [[NIFOptionsPopoverViewController alloc] initWithStoryboard:storyboard popover:popover];
}

- (void)viewWillAppear{
    [super viewWillAppear];
    _crashReporterCheckbox.state = _cachedCheckboxValue;
    _processNameTextField.stringValue = _cachedProcessName ? _cachedProcessName : @"";
}

- (BOOL)acceptsFirstResponder{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    _processNameTextField.target = self;
    _processNameTextField.action = @selector(applyButtonClicked:);
    
    _applyButton.target = self;
    _applyButton.action = @selector(applyButtonClicked:);
    
    _cancelButton.target = self;
    _cancelButton.action = @selector(cancelButtonClicked:);
}

- (BOOL)showReportCrashProcess{
    return _cachedCheckboxValue == 1;
}

- (NSString *)processName{
    return _cachedProcessName;
}

- (void)applyButtonClicked:(id)sender{
    _cachedCheckboxValue = _crashReporterCheckbox.state;
    _cachedProcessName = _processNameTextField.stringValue;
    [self.delegate optionsPopoverViewControllerSettingsChanged:self];
    [self cancelButtonClicked:sender];
}

- (void)cancelButtonClicked:(id)sender{
    [_popover close];
}

- (void)keyDown:(NSEvent *)theEvent{
    [super keyDown:theEvent];
    if (theEvent.keyCode == 36) {
        [self applyButtonClicked:nil];
    }
}

@end
