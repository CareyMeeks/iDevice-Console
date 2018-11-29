//
//  NIFConsoleSettingsManager.h
//  iConsole
//
//  Created by Terry Lewis on 10/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class NIFConsoleWindowControllerModel;

extern NSString *kNIFConsoleFontChangeNotification;

extern NSString *kNIFBaseFont;
extern NSString *kNIFBoldFont;

@interface NIFConsoleSettingsManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, weak) NIFConsoleWindowControllerModel *associatedModel;
@property (nonatomic, strong) NSColor *textColour, *markerColour;

//+ (void)setFont:(NSFont *)font;
//+ (NSFont *)boldFont;
//+ (NSFont *)font;

- (NSFont *)font;
- (NSFont *)boldFont;
- (void)setFont:(NSFont *)font;

@end
