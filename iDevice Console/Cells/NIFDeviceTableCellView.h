//
//  NIFDeviceTableCellView.h
//  iDevice Console
//
//  Created by Terry Lewis on 30/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NIFDeviceTableCellView : NSTableCellView
@property (weak) IBOutlet NSImageView *iconImageView;
@property (weak) IBOutlet NSTextField *deviceNameLabel;

@end
