//
//  NIFOptionsPopoverViewController.h
//  iDevice Console
//
//  Created by Terry Lewis on 4/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NIFOptionsPopoverViewController;

@protocol NIFOptionsPopoverViewControllerDelegate <NSObject>

- (void)optionsPopoverViewControllerSettingsChanged:(NIFOptionsPopoverViewController *)optionsPopoverViewController;

@end

@interface NIFOptionsPopoverViewController : NSViewController

+ (instancetype)viewControllerWithStoryboard:(NSStoryboard *)storyboard popover:(NSPopover *)popover;

@property (weak) IBOutlet NSTextField *processNameTextField;
@property (weak) IBOutlet NSButton *crashReporterCheckbox;
@property (weak) IBOutlet NSButton *applyButton;
@property (weak) IBOutlet NSButton *cancelButton;

@property (nonatomic, weak) id<NIFOptionsPopoverViewControllerDelegate> delegate;

@property (nonatomic, weak) NSString *processName;
@property (nonatomic) BOOL showReportCrashProcess;

@end
