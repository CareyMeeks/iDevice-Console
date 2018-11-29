//
//  ViewController.h
//  iDevice Console
//
//  Created by Terry Lewis on 23/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NIFConsoleWindowController, AMDevice, NIFDeviceOutlineView;

@interface NIFConsoleSplitViewController : NSViewController

@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet NIFDeviceOutlineView *deviceList;
@property (weak) IBOutlet NSTableView *tableView;
@property (nonatomic) BOOL searching;
@property (weak) IBOutlet NSLayoutConstraint *optionsBarHeightConstraint;
@property (weak) IBOutlet NSView *extraToolBar;

@property (weak) IBOutlet NSTextField *filterTextField;
@property (weak) IBOutlet NSButton *crashReporterCheckBox;
@property (nonatomic, strong) NSColor *highlightColour;
@property (nonatomic, weak) NIFConsoleWindowController *windowController;

- (void)clearButtonClicked:(NSToolbarItem *)sender;
- (void)reloadButtonClicked:(NSToolbarItem *)sender;
- (void)optionsButtonClicked:(NSToolbarItem *)sender;
- (void)insertMarkerButtonClicked:(NSToolbarItem *)sender;
- (void)toggleDeviceListButtonClicked:(NSButton *)sender;
- (void)showFilterPopoverRelativeToView:(NSView *)view;

- (void)beginSearching:(id)sender;
- (void)endSearching:(id)sender;
- (void)performSearchWithSearchField:(NSSearchField *)searchField;
- (void)performCopyAction:(id)sender;

- (void)scrollToEndIfSuitable;
- (void)showAlertForProtectedDevice:(AMDevice *)device;
- (void)deviceConnectionStatusChanged;

- (void)navigateToPreviousMarker;
- (void)navigateToNextMarker;

- (void)invalidateCellHeightsAndReloadTableView;

- (void)insertNewRow;

@end

