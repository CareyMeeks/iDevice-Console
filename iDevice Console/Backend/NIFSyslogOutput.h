//
//  NIFSyslogOutput.h
//  iDevice Console
//
//  Created by Terry Lewis on 30/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMDevice;

@interface NIFSyslogOutput : NSObject

+ (instancetype)outputWithDevice:(AMDevice *)device message:(NSString *)message;
+ (instancetype)markerForDevice:(AMDevice *)device;

- (instancetype)initWithDevice:(AMDevice *)device message:(NSString *)message;

- (instancetype)initWithMarkerForDevice:(AMDevice *)device;

@property (nonatomic, readonly) NSString *message;
@property (nonatomic, readonly) NSMutableAttributedString *attributedMessage;
@property (nonatomic, readonly) AMDevice *device;
@property (nonatomic, readonly) NSString *processAndPIDString;
@property (nonatomic, readonly) NSString *processName;
@property (nonatomic, readonly) BOOL isMarker;

@end
