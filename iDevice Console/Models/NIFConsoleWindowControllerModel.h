//
//  NIFConsoleWindowControllerModel.h
//  iDevice Console
//
//  Created by Terry Lewis on 2/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIFDeviceConsoleOutputStream.h"

typedef enum{
    NIFSearchDirectionBackward,
    NIFSearchDirectionForward
} NIFSearchDirection;

@class NIFConsoleSplitViewController;

@interface NIFConsoleWindowControllerModel : NSObject

- (instancetype)initWithController:(NIFConsoleSplitViewController *)controller;

@property (nonatomic, readonly) NSFont *font, *boldFont;
@property (nonatomic, strong) NIFConsoleSplitViewController *controller;
@property (nonatomic, strong) NSString *searchQuery;
@property (nonatomic, readonly) NIFDeviceConsoleOutputStream *consoleOutputStream;
@property (nonatomic, strong) NSString *searchedProcessName;
@property (nonatomic) BOOL showReportCrashProcess;

@property (nonatomic, retain) AMDevice *selectedDevice;
@property (nonatomic, readonly) NSArray *consoleLogDataSource;
@property (nonatomic, readonly) NSArray *connectedDeviceDataSource;

- (AMDevice *)deviceAtIndex:(NSInteger)index;

- (void)insertMarker;
- (void)clearLogListForCurrentDevice;
- (void)reloadLogListForCurrentDevice;
- (void)attemptToConnectDevice:(AMDevice *)device;
- (void)connectToDeviceIfPossible:(AMDevice *)device successful:(BOOL *)successful;
- (NSMenu *)menuForSelectedDevice;

- (NSString *)UDIDForDevice:(AMDevice *)device;
- (NSImage *)screenshotForDevice:(AMDevice *)device;
- (void)ejectDevice:(AMDevice *)device;

- (NSUInteger)indexOfMarkerFromIndex:(NSInteger)index direction:(NIFSearchDirection)direction;

@end
