//
//  NIFDevice.m
//  iDevice Console
//
//  Created by Terry Lewis on 5/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFDevice.h"

@implementation NIFDevice{
    BOOL _determinedIfScreenshotServiceIsAvailable;
    AMScreenshotService *_screenshotService;
}

- (AMScreenshotService *)screenshotService{
    if (!_determinedIfScreenshotServiceIsAvailable) {
        _determinedIfScreenshotServiceIsAvailable = YES;
        _screenshotService = [self newAMScreenshotService];
    }
    return _screenshotService;
}

- (BOOL)hasScreenshotServiceAvailable{
    return self.screenshotService != nil;
}

@end
