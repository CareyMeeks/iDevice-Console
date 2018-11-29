//
//  NIFDevice.h
//  iDevice Console
//
//  Created by Terry Lewis on 5/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "MobileDeviceAccess.h"

@interface NIFDevice : AMDevice

@property (nonatomic, readonly, strong) AMScreenshotService *screenshotService;
@property (nonatomic, readonly) BOOL hasScreenshotServiceAvailable;

@end
