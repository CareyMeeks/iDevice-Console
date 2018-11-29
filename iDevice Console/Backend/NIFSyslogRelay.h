//
//  NIFSyslogRelay.h
//  iDevice Console
//
//  Created by Terry Lewis on 30/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMDevice, NIFSyslogRelay, NIFSyslogOutput;

@protocol NIFSyslogRelayDelegate <NSObject>

@required
- (void)syslogRelay:(NIFSyslogRelay *)relay recievedMessage:(NIFSyslogOutput *)message;

@end

@interface NIFSyslogRelay : NSObject

+ (instancetype)relayForWithDevice:(AMDevice *)device;
+ (NSMutableArray *)allInstances;

//@property (nonatomic, weak) id<NIFSyslogRelayDelegate> delegate;
//@property (nonatomic, strong) NSArray *observers;
@property (nonatomic, readonly) AMDevice *device;
@property (nonatomic, retain) NSArray *syslog;
@property (nonatomic, readonly) BOOL isValid;

- (void)clearPreviousEntries;
- (void)reloadAllMessages;
- (void)insertMarker;
- (void)addListener:(id<NIFSyslogRelayDelegate>)listener;
- (void)removeListener:(id<NIFSyslogRelayDelegate>)listener;

@end
