//
//  NIFSyslogRelay.m
//  iDevice Console
//
//  Created by Terry Lewis on 30/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFSyslogRelay.h"
#import <MobileDeviceAccess.h>
#import "NIFSyslogOutput.h"

static const NSInteger kMessageLimit = 500;

@implementation NIFSyslogRelay{
    AMDevice *_device;
    AMSyslogRelay *_relay;
    NSMutableArray *_messages, *_scratchMessages;
    NSMutableArray *_listeners;
}

+ (instancetype)relayForWithDevice:(AMDevice *)device{
    return [[NIFSyslogRelay alloc] initWithDevice:device];
}

+ (NSMutableArray *)allInstances{
    static NSMutableArray *allInstances = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allInstances = [[NSMutableArray alloc] init];
    });
    return allInstances;
}

- (BOOL)isValid{
    return _relay != nil;
}

- (void)dealloc{
    [[NIFSyslogRelay allInstances] removeObject:self];
}

- (instancetype)initWithDevice:(AMDevice *)device{
    if (self = [super init]) {
        _listeners = [[NSMutableArray alloc] init];
        _messages = [[NSMutableArray alloc] init];
        _scratchMessages = [[NSMutableArray alloc] init];
        _device = device;
        _relay = [_device newAMSyslogRelay:self message:@selector(messageReceieved:)];
        [[NIFSyslogRelay allInstances] addObject:self];
    }
    return self;
}

- (void)enumerateListenersPerformingBlock:(void (^)(id<NIFSyslogRelayDelegate> listener))block{
    for (id listener in _listeners) {
        block(listener);
    }
}

- (void)messageReceieved:(NSString *)message{
    NIFSyslogOutput *output = [NIFSyslogOutput outputWithDevice:_device message:message];
    [self appendSyslogOutput:output scratchOnly:NO];
}

- (void)appendSyslogOutput:(NIFSyslogOutput *)output scratchOnly:(BOOL)scratchOnly{
    if (!scratchOnly) {
        if (_messages.count >= kMessageLimit) {
            [_messages removeObjectAtIndex:0];
        }
        [_messages addObject:output];
    }
    if (_scratchMessages.count >= kMessageLimit) {
        [_scratchMessages removeObjectAtIndex:0];
    }
    [_scratchMessages addObject:output];
    [self enumerateListenersPerformingBlock:^(id<NIFSyslogRelayDelegate> listener) {
        [listener syslogRelay:self recievedMessage:output];
    }];
}

- (AMDevice *)device{
    return _device;
}

- (NSArray *)syslog{
    return _scratchMessages;
}

- (void)clearPreviousEntries{
    [_scratchMessages removeAllObjects];
}

- (void)reloadAllMessages{
    _scratchMessages = [_messages mutableCopy];
}

- (void)insertMarker{
    [self appendSyslogOutput:[NIFSyslogOutput markerForDevice:_device] scratchOnly:YES];
}

- (void)addListener:(id<NIFSyslogRelayDelegate>)listener{
    [_listeners addObject:listener];
}
- (void)removeListener:(id<NIFSyslogRelayDelegate>)listener{
    [_listeners removeObject:listener];
}

- (void)changeFont:(id)sender{
    for (NIFSyslogOutput *output in _messages) {
        [output changeFont:sender];
    }
}

@end
