//
//  AppDelegate.m
//  iDevice Console
//
//  Created by Terry Lewis on 23/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "AppDelegate.h"
#import "NIFConsoleWindowController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if ([NSFontPanel sharedFontPanel].isVisible){
        [[NSFontPanel sharedFontPanel] orderOut:self];
    }
    if ([NSColorPanel sharedColorPanel].isVisible) {
        [[NSColorPanel sharedColorPanel] orderOut:self];
    }
    // Insert code here to initialize your application
//    NSLog(@"%@", [NIFConsoleWindowController sharedController]);
    [_contactDeveloperButton setTarget:[NIFConsoleWindowController sharedController]];
    [_contactDeveloperButton setAction:@selector(contactDeveloperButtonClicked:)];
    [_donateButton setTarget:[NIFConsoleWindowController sharedController]];
    [_donateButton setAction:@selector(donateButtonClicked:)];
    [_previousMarkerButton setTarget:[NIFConsoleWindowController sharedController]];
    [_previousMarkerButton setAction:@selector(previousMarkerClicked:)];
    [_nextMarkerButton setTarget:[NIFConsoleWindowController sharedController]];
    [_nextMarkerButton setAction:@selector(nextMarkerButtonClicked:)];
    
    [_showFontsButton setTarget:[NIFConsoleWindowController sharedController]];
    [_showFontsButton setAction:@selector(showFontsButtonClicked:)];
    [_showColoursButton setTarget:[NIFConsoleWindowController sharedController]];
    [_showColoursButton setAction:@selector(showColoursButtonClicked:)];
    [_showMarkerColoursButton setTarget:[NIFConsoleWindowController sharedController]];
    [_showMarkerColoursButton setAction:@selector(showMarkerColoursButtonClicked:)];
    
    
    [_insertMarkerButton setTarget:[NIFConsoleWindowController sharedController].contentViewController];
    [_insertMarkerButton setAction:@selector(insertMarkerButtonClicked:)];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag{
    [[NIFConsoleWindowController sharedController] showWindow:[NIFConsoleWindowController sharedController]];
    return YES;
}

@end
