//
//  AppDelegate.h
//  iDevice Console
//
//  Created by Terry Lewis on 23/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSMenuItem *contactDeveloperButton;
@property (weak) IBOutlet NSMenuItem *donateButton;
@property (weak) IBOutlet NSMenuItem *previousMarkerButton;
@property (weak) IBOutlet NSMenuItem *nextMarkerButton;
@property (weak) IBOutlet NSMenuItem *showFontsButton;
@property (weak) IBOutlet NSMenuItem *insertMarkerButton;
@property (weak) IBOutlet NSMenuItem *showColoursButton;
@property (weak) IBOutlet NSMenuItem *showMarkerColoursButton;

@end

