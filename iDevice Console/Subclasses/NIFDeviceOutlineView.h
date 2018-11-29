//
//  NIFDeviceOutlineView.h
//  iDevice Console
//
//  Created by Terry Lewis on 5/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NIFConsoleWindowControllerModel;

@interface NIFDeviceOutlineView : NSOutlineView

@property (nonatomic, strong) NIFConsoleWindowControllerModel *model;

@end
