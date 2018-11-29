//
//  ViewController.m
//  iDevice Console
//
//  Created by Terry Lewis on 23/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFConsoleSplitViewController.h"
#import "NIFDeviceConsoleOutputStream.h"
#import "NS(Attributed)String+Geometrics.h"
#import "NIFConsoleWindowController.h"
#import "NIFSyslogOutput.h"
#import "NIFDeviceTableCellView.h"
#import <tgmath.h>
#import "NIFConsoleWindowControllerModel.h"
#import "NIFOptionsPopoverViewController.h"
#import <AppKit/AppKit.h>
#import "MobileDeviceAccess.h"
#import <objc/runtime.h>
#import "NIFDeviceOutlineView.h"
#import "NIFConsoleSettingsManager.h"

@interface NSButton (NIFAdditions)

@property (nonatomic, strong) id nif_customObject;

@end

@implementation NSSplitView (DMAdditions)

- (CGFloat)positionOfDividerAtIndex:(NSInteger)dividerIndex {
    // It looks like NSSplitView relies on its subviews being ordered left->right or top->bottom so we can too.
    // It also raises w/ array bounds exception if you use its API with dividerIndex > count of subviews.
    while (dividerIndex >= 0 && [self isSubviewCollapsed:[[self subviews] objectAtIndex:dividerIndex]])
        dividerIndex--;
    if (dividerIndex < 0)
        return 0.0f;
    
    NSRect priorViewFrame = [[[self subviews] objectAtIndex:dividerIndex] frame];
    return [self isVertical] ? NSMaxX(priorViewFrame) : NSMaxY(priorViewFrame);
}

@end

@implementation NSButton (NIFAdditions)

- (void)setNif_customObject:(id)nif_customObject{
    objc_setAssociatedObject(self, @selector(nif_customObject), nif_customObject, OBJC_ASSOCIATION_RETAIN);
}

- (id)nif_customObject{
    return objc_getAssociatedObject(self, @selector(nif_customObject));
}

@end

@implementation NSString (Safety)

- (NSString *)stringValue{
    return self;
}

@end

@interface NIFConsoleSplitViewController () <NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSplitViewDelegate, NIFOptionsPopoverViewControllerDelegate>{
    CGFloat _savedDeviceListWidth;
    NIFConsoleWindowControllerModel *_model;
    NSPopover *_optionsPopover;
    NSMenu *_deviceListContextMenu;
}

@property (nonatomic, strong) NSMutableDictionary *cellRowHeightsCache;
@property (nonatomic) BOOL showingOptionsBar;

@end

@implementation NIFConsoleSplitViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)filterButtonClicked:(NSButton *)sender{
}

- (void)crashReporterCheckBoxClicked:(NSButton *)sender{
    if (sender.state == NSOnState) {
        _model.showReportCrashProcess = YES;
    }else{
        _model.showReportCrashProcess = NO;
    }
}

- (void)toggleDeviceListButtonClicked:(NSButton *)sender{
    [self setDeviceListHidden:![self deviceListIsHidden]];
}

- (void)insertMarkerButtonClicked:(NSToolbarItem *)sender{
    [_model insertMarker];
    [self.tableView reloadData];
    [self scrollToEndIfSuitable];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    _model = [[NIFConsoleWindowControllerModel alloc] initWithController:self];
    _deviceList.model = _model;
    _deviceList.menu = _deviceListContextMenu;
    
    self.showingOptionsBar = NO;
    _deviceList.dataSource = self;
    _deviceList.delegate = self;
    
    _splitView.delegate = self;
    
    [_crashReporterCheckBox setTarget:self];
    [_crashReporterCheckBox setAction:@selector(crashReporterCheckBoxClicked:)];
    
    _filterTextField.delegate = self;
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:) name:NSWindowDidResizeNotification object:nil];
    
    _cellRowHeightsCache = [NSMutableDictionary dictionary];
    self.tableView.font = _model.font;
    
    for (NSTableColumn *col in self.tableView.tableColumns) {
        NSCell *cell = ((NSCell *)col.dataCell);
        cell.font = _model.font;
        cell.lineBreakMode = NSLineBreakByCharWrapping;
    }
    
    [self.tableView  setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
    
    [self.tableView sizeLastColumnToFit];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewDidAppear{
    [super viewDidAppear];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"SIZE");
        [self reloadCellsDueToResize];
    });
}

- (void)showAlertForProtectedDevice:(AMDevice *)device{
    
    static NSString *appName = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id temp = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleDisplayName"];
        appName = temp ? : @"iDevice Console";
    });
    NSString *deviceName = [device deviceName];
    NSString *deviceClass = [device deviceClass];
    NSString *message = [NSString stringWithFormat:@"%@ could not connect to the %@ “%@” because it is locked with a passcode. You must enter your passcode on the %@ before it can be used with %@.", appName, deviceClass, deviceName, deviceClass, appName];
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = message;
    [alert addButtonWithTitle:@"Try Again"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"More Information"];
    
    NSButton *tryAgainButton = [[alert buttons] objectAtIndex:0];
    tryAgainButton.target = self;
    tryAgainButton.action = @selector(tryAgainButtonClicked:);
    tryAgainButton.nif_customObject = @{@"Alert" : alert, @"Device" : device};
    
    NSInteger result = [alert runModal];
    if(result == NSAlertThirdButtonReturn){
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://support.apple.com/HT204306"]];
    }
}

- (void)tryAgainButtonClicked:(NSButton *)button{
    NSDictionary *dict = button.nif_customObject;
    NSAlert *alert = [dict objectForKey:@"Alert"];
    AMDevice *device = [dict objectForKey:@"Device"];
    BOOL successful = NO;
    [_model connectToDeviceIfPossible:device successful:&successful];
    if (successful) {
        [alert.window close];
    }
//    [self.windowController.window.attachedSheet close];
}

- (NSUInteger)selectedDeviceListIndex{
    return [_deviceList.selectedRowIndexes firstIndex];
}

- (void)clearConsole{
    [_model clearLogListForCurrentDevice];
    [self _clearCellRowHeightsCache];
}

- (NSPredicate *)_predicateWithSearchTerm:(NSString *)searchTerm{
    NSPredicate *predicate = nil;
    predicate = [NSPredicate predicateWithFormat:@"SELF.string CONTAINS[cd] %@", searchTerm];
    return predicate;
}

- (void)clearButtonClicked:(NSToolbarItem *)sender{
    [self clearConsole];
}

- (void)reloadButtonClicked:(NSToolbarItem *)sender{
    [_model reloadLogListForCurrentDevice];
    [self.tableView reloadData];
    [self.tableView scrollToEndOfDocument:nil];
}

- (void)optionsButtonClicked:(NSToolbarItem *)sender{
    self.showingOptionsBar = !self.showingOptionsBar;
}

- (void)_fadeToolbarSubviewsToVisibleState:(BOOL)visible{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = 0.3f;
        for (NSView *view in _extraToolBar.subviews) {
            view.animator.alphaValue = visible ? 1.0f : 0.0f;
        }
    } completionHandler:nil];
}

- (void)showFilterPopoverRelativeToView:(NSView *)view{
    if (!_optionsPopover) {
        _optionsPopover = [[NSPopover alloc] init];
        _optionsPopover.behavior = NSPopoverBehaviorTransient;
        NIFOptionsPopoverViewController *controller = [NIFOptionsPopoverViewController viewControllerWithStoryboard:self.storyboard popover:_optionsPopover];
        controller.delegate = self;
        _optionsPopover.contentViewController = controller;
    }
    [_optionsPopover showRelativeToRect:view.bounds ofView:view preferredEdge:NSRectEdgeMaxY];
    [_optionsPopover.contentViewController becomeFirstResponder];
}

- (void)setShowingOptionsBar:(BOOL)showingOptionsBar{
    _showingOptionsBar = showingOptionsBar;
    static CGFloat visibleToolBarHeight = 30.0f;
    
    [self _fadeToolbarSubviewsToVisibleState:showingOptionsBar];
    if (showingOptionsBar) {
        [self.windowController.toolBar setShowsBaselineSeparator:!showingOptionsBar];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            context.duration = 0.3f;
            _optionsBarHeightConstraint.animator.constant = visibleToolBarHeight;
        } completionHandler:^{
            [self.windowController.toolBar setShowsBaselineSeparator:!showingOptionsBar];
        }];
        _model.searchedProcessName = _filterTextField.stringValue;
        _crashReporterCheckBox.enabled = YES;
        _filterTextField.enabled = YES;
    }else{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            context.duration = 0.3f;
            _optionsBarHeightConstraint.animator.constant = 0.0f;
        } completionHandler:^{
            if (_optionsBarHeightConstraint.constant == 0.0f) {
                [self.windowController.toolBar setShowsBaselineSeparator:!showingOptionsBar];
            }
        }];
        _model.searchedProcessName = nil;
        _crashReporterCheckBox.enabled = NO;
        _filterTextField.enabled = NO;
    }
}

- (void)beginSearching:(id)sender{
    [self setSearching:YES];
}

- (void)endSearching:(id)sender{
    [self setSearching:NO];
    _model.searchQuery = nil;
}

- (void)setSearching:(BOOL)searching{
    _searching = searching;
    [self _clearCellRowHeightsCache];
    [self.tableView reloadData];
}

- (void)performSearchWithSearchField:(NSSearchField *)searchField{
    _model.searchQuery = searchField.stringValue.lowercaseString;
    [self _clearCellRowHeightsCache];
    [self.tableView reloadData];
}

- (void)_clearCellRowHeightsCache{
    [_cellRowHeightsCache removeAllObjects];
}

- (void)invalidateCellHeightsAndReloadTableView{
    [self _clearCellRowHeightsCache];
    [self.tableView reloadData];
}

- (void)performCopyAction:(id)sender{
    NSMutableString *copiedString = [[NSMutableString alloc] init];
    NSIndexSet *indexes = [self.tableView selectedRowIndexes];
    __block NSUInteger count = indexes.count;
    __block NSUInteger currentIndex = 1;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSAttributedString *derivedString = [_model.consoleLogDataSource[idx] attributedMessage];
        if (currentIndex == count) {
            [copiedString appendFormat:@"%@", [derivedString string]];
        }else{
            [copiedString appendFormat:@"%@\n", [derivedString string]];
        }
        currentIndex++;
    }];
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    [pasteBoard setString:copiedString forType:NSPasteboardTypeString];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
    if ([control isEqual:_filterTextField]) {
        _model.searchedProcessName = _filterTextField.stringValue;
    }
    return YES;
}

- (void)deviceConnectionStatusChanged{
    if ([self selectedDeviceListIndex] == NSNotFound) {
        AMDevice *newDevice = _model.connectedDeviceDataSource.firstObject;
//        NSLog(@"%@", _model.connectedDeviceDataSource);
        [_deviceList reloadData];
        if (newDevice) {
            [_model setSelectedDevice:newDevice];
            [_deviceList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        }
        
        NSInteger dividerIndex = 0;
        CGFloat currentPosition = [self.splitView positionOfDividerAtIndex:dividerIndex];
//        this is a hack we have to change it slightly
        [self.splitView setPosition:currentPosition+1 ofDividerAtIndex:dividerIndex];
//        now we can change it to the old value
        [self.splitView setPosition:currentPosition ofDividerAtIndex:dividerIndex];
//        suddenly, the outline view is properly selected!
    }
}

- (void)_navigateToMarkerNext:(BOOL)next{
    NSInteger selectedRow = [self.tableView selectedRow];
    NIFSearchDirection direction = next ? NIFSearchDirectionForward : NIFSearchDirectionBackward;
    NSInteger nextMarkerIndex = [_model indexOfMarkerFromIndex:selectedRow direction:direction];
    if (nextMarkerIndex != NSNotFound) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:nextMarkerIndex] byExtendingSelection:NO];
        [self.tableView scrollRowToVisible:nextMarkerIndex];
    }
}

- (void)navigateToPreviousMarker{
    [self _navigateToMarkerNext:NO];
}

- (void)navigateToNextMarker{
    [self _navigateToMarkerNext:YES];
}

#pragma mark - NSOutlineViewDataSource

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    if ([item isKindOfClass:[NSDictionary class]]) {
        return YES;
    }else {
        return NO;
    }
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    if (item == nil) { //item is nil when the outline view wants to inquire for root level items
        return [_model.connectedDeviceDataSource count];
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
    if (item == nil) { //item is nil when the outline view wants to inquire for root level items
        return [_model.connectedDeviceDataSource objectAtIndex:index];
    }
    
    return nil;
}

//- (NSImage *)imageForDeviceType:(NSString *)deviceType{
//    NSString *dev = deviceType.lowercaseString;
//    NSString *imageName = nil;
//    if ([dev rangeOfString:@"ipad"].location != NSNotFound) {
//        imageName = @"iPad";
//    }else{
//        imageName = @"iPhone";
//    }
//    return [NSImage imageNamed:imageName];;
//}

- (NSImage *)imageForDevice:(AMDevice *)device{
    NSString *dev = device.deviceClass.lowercaseString;
    NSString *imageName = nil;
    if ([dev rangeOfString:@"ipad"].location != NSNotFound) {
        imageName = @"iPad";
    }else{
        imageName = @"iPhone";
    }
    return [NSImage imageNamed:imageName];;
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NIFDeviceTableCellView *)cell forTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item{
    NSAttributedString *string = [self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
    cell.deviceNameLabel.attributedStringValue = string;
}

- (nullable NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(AMDevice *)item{
    NIFDeviceTableCellView *view = [outlineView makeViewWithIdentifier:@"NIFDeviceTableCellView" owner:self];
    NSString *string = item.deviceName;
    view.deviceNameLabel.stringValue = string;
    view.iconImageView.image = [self imageForDevice:item];
    
    return view;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item{
    _model.selectedDevice = [_model deviceAtIndex:[self.deviceList rowForItem:item]];
    [self _clearCellRowHeightsCache];
    [self.tableView reloadData];
    [self.tableView scrollToEndOfDocument:nil];
    return YES;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [_model consoleLogDataSource].count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    
    NIFSyslogOutput *output = _model.consoleLogDataSource[row];
//    NSLog(@"%@", output);
    return output.attributedMessage;
}

#pragma mark - NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView willDisplayCell:(NSTextFieldCell *)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    cell.drawsBackground = YES;
    cell.textColor = [[NIFConsoleSettingsManager sharedManager] textColour];
    NIFSyslogOutput *output = _model.consoleLogDataSource[row];
    if ([output isMarker]) {
        cell.backgroundColor = [[NIFConsoleSettingsManager sharedManager] markerColour];
    }else{
        cell.backgroundColor = [NSColor clearColor];
    }
}

//- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
//    NSTableCellView *view = [tableView makeViewWithIdentifier:@"NIFLogCellView" owner:self];
//    NSAttributedString *output = [self tableView:tableView objectValueForTableColumn:tableColumn row:row];
//    view.textField.attributedStringValue = output;
////    view.textField.stringValue = @"Test";
//    NSLog(@"%@", view);
//    
//    return view;
//}

//- (nullable NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row{
//    NSTextFieldCell *cell = [tableView makeC]
//}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    static NSTextField *baseTextField = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        baseTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, self.tableView.frame.size.width, 100)];
//        baseTextField.font = [NIFConsoleSettingsManager font];
        baseTextField.bezeled = NO;
    });
    
    CGFloat minimumHeight = tableView.rowHeight;
    NSNumber *cachedHeight;
    
    NSNumber *cacheKey = @(row);
    CGFloat height = minimumHeight;
    
    if ((cachedHeight = [self.cellRowHeightsCache objectForKey:cacheKey])) {
        return [cachedHeight floatValue];
    }
    if (height < minimumHeight) height = minimumHeight; // ensure minimum
    if (height > minimumHeight) {
        // look out for fudge factor by checking mod of minimum
        CGFloat remainder = fmod(height, minimumHeight);
        height += remainder;
    }
    NIFSyslogOutput *output = _model.consoleLogDataSource[row];
    baseTextField.attributedStringValue = output.attributedMessage;
    
    height = [baseTextField sizeThatFits:NSMakeSize(self.tableView.frame.size.width, FLT_MAX)].height;
    
    [self.cellRowHeightsCache setObject:[NSNumber numberWithFloat:height]
                                 forKey:cacheKey];
    return height;
}

#pragma mark - NSSplitViewDelegate

- (BOOL)deviceListIsHidden{
    return [_splitView isSubviewCollapsed:_splitView.subviews[0]];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification{
    [self reloadCellsDueToResize];
}

- (void)reloadCellsDueToResize{
    [self _clearCellRowHeightsCache];
    CGFloat deviceListWidth = _splitView.subviews[0].frame.size.width;
    if (deviceListWidth > [self splitView:_splitView constrainMinCoordinate:100 ofSubviewAt:0]) {
        _savedDeviceListWidth = deviceListWidth;
    }
    [self _updateToggleDeviceListButtonLabelText];
    [self.tableView reloadData];
}

- (void)_updateToggleDeviceListButtonLabelText{
    BOOL deviceListHidden = [self deviceListIsHidden];
    NSInteger index;
    if (deviceListHidden) {
        index = 0;
    }else{
        index = 1;
    }
    
    [self.windowController.toggleDeviceListItem setLabelUsingIndexedVariant:index];
    
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex{
//    NSLog(@"%f", proposedMinimumPosition);
    return 100;
//    return 25 + 8 + 8 + splitView.dividerThickness;
}
//
//

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    NSUInteger index = [[splitView subviews] indexOfObject:subview];
    if (index == 0){
        return NO;
    }
    return YES;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex{
//    NSLog(@"%f", proposedMaximumPosition);
    return self.view.frame.size.width - 100;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex{
    if (dividerIndex == 0) {
        return YES;
    }
    return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview{
    NSView* leftView = [[splitView subviews] objectAtIndex:0];
    return ([subview isEqual:leftView]);
}

- (void)setDeviceListHidden:(BOOL)hidden{
    NSView *deviceView = [[_splitView subviews] objectAtIndex:0];
    NSView *consoleView = [[_splitView subviews] objectAtIndex:1];
    
    
    deviceView.hidden = hidden;
    
    NSRect leftFrame = [consoleView frame];
    NSRect overallFrame = [_splitView frame];
    
    if (hidden) {
        [deviceView setHidden:YES];
        [consoleView setFrameSize:NSMakeSize(overallFrame.size.width,leftFrame.size.height)];
    }else{
        [deviceView setHidden:NO];
        CGFloat dividerThickness = [_splitView dividerThickness];
        // get the different frames
        NSRect rightFrame = [deviceView frame];
        // Adjust left frame size
        leftFrame.size.width = (leftFrame.size.width-rightFrame.size.width-dividerThickness);
        rightFrame.origin.x = leftFrame.size.width + dividerThickness;
        [consoleView setFrameSize:leftFrame.size];
        [deviceView setFrame:rightFrame];
    }
    [_splitView display];
}

- (void)scrollToEndIfSuitable{
    CGRect visibleRect = self.tableView.enclosingScrollView.contentView.visibleRect;
    NSRange range = [self.tableView rowsInRect:visibleRect];
    
    NSInteger index = [_model consoleLogDataSource].count;
    if (range.length + range.location == index-1) {
        [self.tableView scrollToEndOfDocument:nil];
    }
}

#pragma mark - NIFOptionsPopoverViewControllerDelegate

- (void)optionsPopoverViewControllerSettingsChanged:(NIFOptionsPopoverViewController *)optionsPopoverViewController{
    _model.searchedProcessName = optionsPopoverViewController.processName;
    _model.showReportCrashProcess = optionsPopoverViewController.showReportCrashProcess;
    [self _clearCellRowHeightsCache];
    [self.tableView reloadData];
}

//- (void)keyDown:(NSEvent *)theEvent{
//    if (_optionsPopover.shown) {
//        [_optionsPopover.contentViewController keyDown:theEvent];
//    }else{
//        [super keyDown:theEvent];
//    }
//}

- (void)insertNewRow{
//    NSInteger index = _model.consoleLogDataSource.count-1;
    [self.tableView reloadData];
//    [self.tableView beginUpdates];
//    [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:0];
//    [self.tableView endUpdates];
    [self scrollToEndIfSuitable];
}

@end
