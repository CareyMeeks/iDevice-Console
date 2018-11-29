//
//  NIFConsoleWindowController.h
//  iDevice Console
//
//  Created by Terry Lewis on 24/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NIFConsoleSplitViewController.h"
#import "NIFFixedStateToolbarItem.h"

@interface NIFConsoleWindowController : NSWindowController

@property (weak) IBOutlet NIFFixedStateToolbarItem * toggleDeviceListItem;
@property (weak) IBOutlet NSToolbarItem *clearItem;
@property (weak) IBOutlet NSToolbarItem *reloadItem;
@property (weak) IBOutlet NSToolbarItem *optionsItem;
@property (weak) IBOutlet NSToolbarItem *insertMarkerItem;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSSearchFieldCell *searchFieldCell;
@property (weak) IBOutlet NSToolbar *toolBar;

@property (nullable, strong) NIFConsoleSplitViewController *contentViewController;

+ (nonnull instancetype)sharedController;

- (void)contactDeveloperButtonClicked:(nullable id)sender;
- (void)donateButtonClicked:(nullable id)sender;

- (void)previousMarkerClicked:(nullable id)sender;
- (void)nextMarkerButtonClicked:(nullable id)sender;
- (void)showFontsButtonClicked:(nullable id)sender;
- (void)showColoursButtonClicked:(nullable id)sender;
- (void)showMarkerColoursButtonClicked:(nullable id)sender;

@end
