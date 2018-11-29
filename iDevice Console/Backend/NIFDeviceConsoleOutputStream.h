//
//  NIFDeviceConsoleOutputStream.h
//  iDevice Console
//
//  Created by Terry Lewis on 23/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileDeviceAccess.h>
#import "NIFSyslogOutput.h"
#import "NIFSyslogRelay.h"

@class NIFDeviceConsoleOutputStream;

extern NSString *NIFDeviceAttributeName;
extern NSString *NIFDeviceAttributeVersion;
extern NSString *NIFDeviceAttributeBuild;
extern NSString *NIFDeviceAttributeConnectionStatus;

@protocol NIFDeviceConsoleOutputStreamDelegate <NSObject>

//- (void)deviceConsole:(NIFDeviceConsoleOutputStream *)deviceConsole receivedOutput:(NSString *)output;
- (void)deviceConsole:(NIFDeviceConsoleOutputStream *)deviceConsole receivedOutput:(NIFSyslogOutput *)output;
- (void)deviceConsoleConnectionStatusChanged:(NIFDeviceConsoleOutputStream *)deviceConsole;
- (void)deviceConsole:(NIFDeviceConsoleOutputStream *)deviceConsole deviceIsProtected:(AMDevice *)device;

@end

@interface NIFDeviceConsoleOutputStream : NSObject

+ (instancetype)sharedInstance;
+ (NSString *)crashReporterProcessName;
+ (NSString *)crashReporterProcessNameLowercase;

@property (nonatomic, weak) id<NIFDeviceConsoleOutputStreamDelegate> delegate;
@property (nonatomic, strong) NSFont *font, *boldFont;
@property (nonatomic) BOOL outputAttributedStrings;

@property (nonatomic) BOOL forceDisplayOfCrashReporter;
@property (nonatomic, strong) NSString *processName;
@property (nonatomic, retain, readonly) NSArray *devices;
@property (nonatomic, readonly) NSArray *allSyslogRelays;

- (void)startStreaming;
- (void)stopStreaming;

- (NSArray *)syslogForDevice:(AMDevice *)device;
- (NIFSyslogRelay *)syslogRelayForDevice:(AMDevice *)device;
- (void)tryToCreateSyslogForDevice:(AMDevice *)device successful:(BOOL *)successful;

@end
