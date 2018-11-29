//
//  NIFConsoleWindowControllerModel.m
//  iDevice Console
//
//  Created by Terry Lewis on 2/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFConsoleWindowControllerModel.h"
#import "NIFConsoleSplitViewController.h"
#import "NIFFilteredDataSource.h"
#import "NIFDeviceOutlineView.h"
#import "NIFConsoleSettingsManager.h"

@interface NIFConsoleWindowControllerModel () <NIFDeviceConsoleOutputStreamDelegate, NIFFilteredDataSourceDelegate>

@end

@interface AMDevice (Private)

- (bool)deviceDisconnect;

@end

@implementation NIFConsoleWindowControllerModel{
    NSMutableDictionary *_deviceDataSources;
    NSArray *_dataSource;
    NIFFilteredDataSource *_filteredDataSource;
}

- (instancetype)init{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithController:(NIFConsoleSplitViewController *)controller{
    if (self = [self init]) {
        _controller = controller;
    }
    return self;
}

- (void)commonInit{
    _filteredDataSource = [[NIFFilteredDataSource alloc] init];
    _filteredDataSource.highlightColour = [[NSColor yellowColor] colorWithAlphaComponent:0.5f];
    _filteredDataSource.delegate = self;
    _deviceDataSources = [NSMutableDictionary dictionary];
    
    _font = [NSFont fontWithName:@"Courier" size:12];
    _boldFont = [[NSFontManager sharedFontManager] fontWithFamily:@"Courier"
                                                           traits:NSBoldFontMask
                                                           weight:NSFontWeightBold
                                                             size:12];
    
    _consoleOutputStream = [[NIFDeviceConsoleOutputStream alloc] init];
    _consoleOutputStream.delegate = self;
    _consoleOutputStream.font = _font;
    _consoleOutputStream.boldFont = _boldFont;
    _consoleOutputStream.outputAttributedStrings = YES;
    [_consoleOutputStream startStreaming];
    
    [NIFConsoleSettingsManager sharedManager].associatedModel = self;
}

- (void)connectToDeviceIfPossible:(AMDevice *)device successful:(BOOL *)successful{
    BOOL isOpened = NO;
    [_consoleOutputStream tryToCreateSyslogForDevice:device successful:&isOpened];
    if (successful) {
        *successful = isOpened;
    }
}

//- (AMDevice *)currentDevice{
//    NSLog(@"%li", _selectedDeviceIndex);
//    if (_selectedDeviceIndex > _consoleOutputStream.devices.count) {
//        return nil;
//    }
//    return [_consoleOutputStream.devices objectAtIndex:_selectedDeviceIndex];
//}

- (void)_setupDataSource{
    _dataSource = [_consoleOutputStream syslogForDevice:_selectedDevice];
    _filteredDataSource.relay = [_consoleOutputStream syslogRelayForDevice:_selectedDevice];
}

- (void)setSelectedDevice:(AMDevice *)selectedDevice{
    _selectedDevice = selectedDevice;
    [self _setupDataSource];
}

- (void)deviceConsole:(NIFDeviceConsoleOutputStream *)deviceConsole receivedOutput:(NIFSyslogOutput *)output{
    [self manageAdditionToDataSource:output];
}

- (AMDevice *)deviceAtIndex:(NSInteger)index{
    if (index > _consoleOutputStream.devices.count-1) {
        return [_consoleOutputStream.devices firstObject];
    }
    return _consoleOutputStream.devices[index];
}

- (void)manageAdditionToDataSource:(NIFSyslogOutput *)addition{
    if (_filteredDataSource.searching) {
        return;
    }
    
//    [_controller.tableView reloadData];
    [_controller insertNewRow];
}

- (BOOL)inputMatchesSearchQuery:(NSAttributedString *)input{
    NSString *workingString = input.string.lowercaseString;
    BOOL matches = [workingString rangeOfString:_searchQuery].location != NSNotFound;
    if (matches) {
        return matches;
    }
    matches = [workingString rangeOfString:[NIFDeviceConsoleOutputStream crashReporterProcessNameLowercase]].location != NSNotFound;
    return matches;
}

- (void)insertMarker{
    [[_consoleOutputStream syslogRelayForDevice:_selectedDevice] insertMarker];
}

- (void)clearLogListForCurrentDevice{
    [[_consoleOutputStream syslogRelayForDevice:_selectedDevice] clearPreviousEntries];
    if (_filteredDataSource.searching) {
        [_filteredDataSource clearPreviousEntries];
    }
//    the pointer address has changed, we need to update it
    [self _setupDataSource];
}

- (void)reloadLogListForCurrentDevice{
//    [self.selectedDevice post]
//    return;
    [[_consoleOutputStream syslogRelayForDevice:_selectedDevice] reloadAllMessages];
    if (_filteredDataSource.searching) {
        [_filteredDataSource reloadAllMessages];
    }
    //    the pointer address has changed, we need to update it
    [self _setupDataSource];
}

- (NSArray *)connectedDeviceDataSource{
    return _consoleOutputStream.devices;
}

- (NSArray *)consoleLogDataSource{
    if (_filteredDataSource.searching) {
        return _filteredDataSource.filteredOutput;
    }
//    if (!_dataSource) {
//        return [_consoleOutputStream syslogForDevice:_selectedDevice];
//    }
    return _dataSource;
}

- (void)setShowReportCrashProcess:(BOOL)showReportCrashProcess{
    _showReportCrashProcess = showReportCrashProcess;
    _filteredDataSource.showCrashReporterProcess = _showReportCrashProcess;
}

#pragma mark - NIFDeviceConsoleOutputStreamDelegate

- (void)deviceConsoleConnectionStatusChanged:(NIFDeviceConsoleOutputStream *)deviceConsole{
    [_controller.deviceList reloadData];
    [_controller deviceConnectionStatusChanged];
}

- (void)deviceConsole:(NIFDeviceConsoleOutputStream *)deviceConsole deviceIsProtected:(AMDevice *)device{
    [_controller showAlertForProtectedDevice:device];
}

- (void)setSearchedProcessName:(NSString *)searchedProcessName{
    _filteredDataSource.processName = searchedProcessName;
}

- (void)setSearchQuery:(NSString *)searchQuery{
    [_filteredDataSource setSearchTerm:searchQuery];
}

#pragma mark - NIFSyslogRelayDelegate

- (void)filteredDataSource:(NIFFilteredDataSource *)dataSource acceptedAddition:(NIFSyslogOutput *)addition{
//    [_controller.tableView reloadData];
    [_controller insertNewRow];
}

- (void)filteredDataSourceIssuedChangeRequiringUIUpdate:(NIFFilteredDataSource *)dataSource{
    [_controller.tableView reloadData];
}

- (NSString *)UDIDForDevice:(AMDevice *)device{
    return [device udid];
}

- (NSImage *)screenshotForDevice:(AMDevice *)device{
    AMScreenshotService *screenshotService = [device newAMScreenshotService];
    NSImage *screenshot = [screenshotService getScreenshot];
    screenshotService = nil;
    return screenshot;
}

- (void)ejectDevice:(AMDevice *)device{
    [device deviceDisconnect];
}

- (void)deviceCopyUDID:(NSMenuItem *)sender{
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObject:NSPasteboardTypeString] owner:nil];
    [pasteBoard setString:self.selectedDevice.udid forType:NSPasteboardTypeString];
}

- (void)deviceCopyScreenshot:(NSMenuItem *)sender{
    NSImage *image = [self screenshotForDevice:self.selectedDevice];
    NSLog(@"%@", image);
    CGImageRef cgRef = [image CGImageForProposedRect:NULL
                                             context:nil
                                               hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[image size]];
    //    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    id n;
    NSData *imgData = [newRep representationUsingType:NSPNGFileType properties:n];
    [pasteBoard declareTypes:[NSArray arrayWithObject:NSPasteboardTypePNG] owner:nil];
    [pasteBoard setData:imgData forType:NSPasteboardTypePNG];
}

- (void)deviceEject:(NSMenuItem *)sender{
    [self ejectDevice:self.selectedDevice];
}

- (NSMenu *)menuForSelectedDevice{
    NSMenu *deviceListContextMenu = [[NSMenu alloc] init];
    NSMenuItem *copyUDIDItem = [[NSMenuItem alloc] initWithTitle:@"Copy UDID" action:@selector(deviceCopyUDID:) keyEquivalent:@"U"];
    copyUDIDItem.target = self;
    [deviceListContextMenu addItem:copyUDIDItem];
    
    NSMenuItem *copyScreenshotItem = [[NSMenuItem alloc] initWithTitle:@"Copy Screenshot" action:@selector(deviceCopyScreenshot:) keyEquivalent:@"C"];
    copyScreenshotItem.target = self;
    [deviceListContextMenu addItem:copyScreenshotItem];
    
    NSMenuItem *ejectDeviceItem = [[NSMenuItem alloc] initWithTitle:@"Eject" action:@selector(deviceEject:) keyEquivalent:@"E"];
    ejectDeviceItem.target = self;
    [deviceListContextMenu addItem:ejectDeviceItem];
    
    return deviceListContextMenu;
}

static BOOL should_search(NSUInteger current, NSUInteger max, NIFSearchDirection direction){
//    NSLog(@"%li %li", current, max);
    switch (direction) {
        case NIFSearchDirectionBackward:
            if (current > max) {
                return YES;
            }
            break;
        case NIFSearchDirectionForward:
            if (current < max) {
                return YES;
            }
            break;
    }
    return NO;
}

- (NSUInteger)indexOfMarkerFromIndex:(NSInteger)index direction:(NIFSearchDirection)direction{
    if (index < 0) {
        if (direction == NIFSearchDirectionBackward) {
            return NSNotFound;
        }
        index = 0;
    }
    NSArray *dataSourceCopy = [[self consoleLogDataSource] copy];
    int increment;
    NSUInteger max;
    switch (direction) {
        case NIFSearchDirectionBackward:
            increment = -1;
            max = 0;
            index--;
            if (index < max) {
                return NSNotFound;
            }
            break;
        case NIFSearchDirectionForward:
            increment = 1;
            max = dataSourceCopy.count - 1;
            index++;
            if (index > max) {
                return NSNotFound;
            }
            break;
    }
//    index may be zero, thus it needs to check if its equal or greater than, otherwise we could increment the
    NSUInteger currentIndex = index;
    while (should_search(currentIndex, max, direction)) {
        NIFSyslogOutput *output = dataSourceCopy[currentIndex];
        if (output.isMarker) {
            return currentIndex;
        }
        currentIndex += increment;
    }
    return NSNotFound;
//    NSUInteger i = 0;
}

- (void)changeFont:(id)sender{
    NSArray *allSyslogs = [_consoleOutputStream allSyslogRelays];
    for (NIFSyslogRelay *relay in allSyslogs) {
        [relay changeFont:sender];
    }
    [_controller invalidateCellHeightsAndReloadTableView];
}

@end
