//
//  NIFDeviceConsoleOutputStream.m
//  iDevice Console
//
//  Created by Terry Lewis on 23/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFDeviceConsoleOutputStream.h"
#import "NIFSyslogRelay.h"
#import <AppKit/AppKit.h>
#import "NIFSyslogOutput.h"

NSString *NIFDeviceAttributeName =  @"NIFDeviceAttributeName";
NSString *NIFDeviceAttributeVersion = @"NIFDeviceAttributeVersion";
NSString *NIFDeviceAttributeBuild = @"NIFDeviceAttributeBuild";
NSString *NIFDeviceAttributeConnectionStatus = @"NIFDeviceAttributeConnectionStatus";
static const char * CRASH_REPORTER_PROCESS_NAME = "ReportCrash";

@interface NIFDeviceConsoleOutputStream () <MobileDeviceAccessListener, NIFSyslogRelayDelegate>

@end

@implementation NIFDeviceConsoleOutputStream{
    NSMutableArray *_output;
    BOOL _initialised, _streaming;
    MobileDeviceAccess *_access;
    NSMutableDictionary *_syslogs;
    NSMutableDictionary *_screenshotServices;
    NSMutableArray *_mutableDevices;
}

+ (void)load{
    [super load];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self _commonInit];
    }
    return self;
}

+ (instancetype)sharedInstance{
    static NIFDeviceConsoleOutputStream *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NIFDeviceConsoleOutputStream alloc] init];
    });
    return sharedInstance;
}

- (void)_commonInit{
    if (_initialised) {
        return;
    }
    _initialised = YES;
    _forceDisplayOfCrashReporter = YES;
    
    _syslogs = [[NSMutableDictionary alloc] init];
    _access = [MobileDeviceAccess singleton];
    _mutableDevices = [NSMutableArray array];
    
    [_access setListener:self];
}

- (BOOL)_streaming{
    return _streaming;
}

- (void)startStreaming{
    _streaming = YES;
}

- (void)stopStreaming{
    _streaming = NO;
}

- (void)setProcessName:(NSString *)processName{
    _processName = processName.length > 0 ? processName : nil;
}

+ (NSString *)crashReporterProcessName{
    static NSString *crashReporterProcessName = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        crashReporterProcessName = [NSString stringWithUTF8String:CRASH_REPORTER_PROCESS_NAME];
    });
    return crashReporterProcessName;
}

+ (NSString *)crashReporterProcessNameLowercase{
    static NSString *crashReporterProcessNameLowercase = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        crashReporterProcessNameLowercase = [NIFDeviceConsoleOutputStream crashReporterProcessName].lowercaseString;
    });
    return crashReporterProcessNameLowercase;
}

- (NSArray *)devices{
    return [_mutableDevices copy];
}

- (void)tryToCreateSyslogForDevice:(AMDevice *)device successful:(BOOL *)successful useDelegateCallback:(BOOL)useCallback{
    if (!device.udid) {
        return;
    }
//    [device newAMMobileDiagnosticsRelay]
//    static AMIOSDiagnosticsRelay *prox = nil;
//    prox = [device newAMIOSDiagnosticsRelay];
//    com.apple.mobilesafari
//    com.apple.springboard
//    NSLog(@"%@", [device installedApplications]);
    
    NIFSyslogRelay *relay = [NIFSyslogRelay relayForWithDevice:device];
    if (successful) {
        *successful = [relay isValid];
    }
    if ([relay isValid] == NO) {
        relay = nil;
        if (useCallback) {
            [self.delegate deviceConsole:self deviceIsProtected:device];
        }
    }else{
        [relay addListener:self];
//        [self logDeviceInfoForDevice:device];
        [_syslogs setObject:relay forKey:device.udid];
        [_mutableDevices addObject:device];
        [self.delegate deviceConsoleConnectionStatusChanged:self];
    }
}

- (void)tryToCreateSyslogForDevice:(AMDevice *)device successful:(BOOL *)successful{
    [self tryToCreateSyslogForDevice:device successful:successful useDelegateCallback:NO];
}

#pragma mark - MobileDeviceAccessListener

- (void)logDeviceInfoForDevice:(AMDevice *)device{
    NSLog(@"UDID: %@\nNAME: %@\nCLASS: %@\nLAST ERROR: %@\nALL DEVICE VALUES: %@", device.udid, device.deviceName, device.deviceClass, device.lasterror, [device allDeviceValuesForDomain:nil]);
}

/// This method will be called whenever a device is connected
- (void)deviceConnected:(AMDevice*)device{
    [self tryToCreateSyslogForDevice:device successful:NULL useDelegateCallback:YES];
}

/// This method will be called whenever a device is disconnected
- (void)deviceDisconnected:(AMDevice*)device{
    if (!device.udid) {
        return;
    }
    [self _handleDeviceDisconnected:device];
}

- (void)_handleDeviceDisconnected:(AMDevice *)device{
    [_syslogs removeObjectForKey:device.udid];
    [_mutableDevices removeObject:device];
    [self.delegate deviceConsoleConnectionStatusChanged:self];
}

#pragma mark - NIFSyslogRelayDelegate

- (void)syslogRelay:(NIFSyslogRelay *)relay recievedMessage:(NIFSyslogOutput *)message{
    [self.delegate deviceConsole:self receivedOutput:message];
}

- (NSArray *)syslogForDevice:(AMDevice *)device{
    return [self syslogRelayForDevice:device].syslog;
}

- (NIFSyslogRelay *)syslogRelayForDevice:(AMDevice *)device{
    return [_syslogs objectForKey:device.udid];
}

- (NSArray *)allSyslogRelays{
    return [[_syslogs allValues] copy];
}

@end
