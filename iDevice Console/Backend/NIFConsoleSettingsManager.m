//
//  NIFConsoleSettingsManager.m
//  iConsole
//
//  Created by Terry Lewis on 10/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFConsoleSettingsManager.h"
#import <AppKit/AppKit.h>
#import "NIFConsoleWindowControllerModel.h"
#import "NIFConsoleSplitViewController.h"

@implementation NIFConsoleSettingsManager{
    NSFont *_boldFont;
    NSFont *_font;
    NSFont *_defaultFont;
    CGFloat _fontSize;
}

NSString *kNIFBaseFont = @"NIFBaseFont";
NSString *kNIFBoldFont = @"NIFBoldFont";
NSString *kNIFConsoleFontChangeNotification = @"NIFConsoleFontChangeNotification";

NSString *kNIFSavedFontName = @"FontName";
NSString *kNIFSavedFontSize = @"FontSize";
NSString *kNIFSavedFontColour = @"FontColour";
NSString *kNIFSavedMarkerColour = @"MarkerColour";

+ (instancetype)sharedManager{
    static NIFConsoleSettingsManager *sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[NIFConsoleSettingsManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init{
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (void)loadFontSize{
    NSNumber *tmp = [[NSUserDefaults standardUserDefaults] objectForKey:kNIFSavedFontSize];
    if ([tmp isKindOfClass:[NSNumber class]]) {
        _fontSize = [tmp floatValue];
        if (_fontSize < 1.0f) {
            _fontSize = 1.0f;
        }
    }else{
        _fontSize = 12.0f;
    }
}

- (NSColor *)loadColourSavedAsKey:(NSString *)key fallback:(NSColor *)fallback{
    NSData *colourData = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (colourData) {
        NSColor *colour = [NSKeyedUnarchiver unarchiveObjectWithData:colourData];
        if ([colour isKindOfClass:[NSColor class]]) {
            return colour;
        }
    }
    return fallback;
}

- (void)saveColour:(NSColor *)colour asKey:(NSString *)key{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:colour];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
}

- (void)loadTextColour{
    _textColour = [self loadColourSavedAsKey:kNIFSavedFontColour fallback:[NSColor blackColor]];
    _markerColour = [self loadColourSavedAsKey:kNIFSavedMarkerColour fallback:[NSColor lightGrayColor]];
}

- (void)commonInit{
    [self loadFontSize];
    [self loadTextColour];
    
    _defaultFont = [NSFont fontWithName:@"Courier" size:_fontSize];
    if (!_defaultFont) {
//        so they've deleted Courier, OKAY.
//        if they don't have the system font, they're got bigger problems anyway.
        _defaultFont = [NSFont systemFontOfSize:_fontSize];
    }
    NSString *savedFontName = [[NSUserDefaults standardUserDefaults] stringForKey:kNIFSavedFontName];
    NSFont *savedFont = [NSFont fontWithName:savedFontName size:_fontSize];
    
    if (savedFont) {
        [self _setFont:savedFont];
    }else{
        [self _setFont:_defaultFont];
    }
}

- (void)setFont:(NSFont *)font{
    if (font.familyName) {
        [[NSUserDefaults standardUserDefaults] setObject:font.familyName forKey:kNIFSavedFontName];
        [[NSUserDefaults standardUserDefaults] setFloat:font.pointSize forKey:kNIFSavedFontSize];
        _fontSize = font.pointSize;
    }
    [self _setFont:font];
    
    [_associatedModel changeFont:self];
}

- (void)_setFont:(NSFont *)font{
    if (!font) {
        font = _defaultFont;
    }
    _font = font;
    _boldFont = [[NSFontManager sharedFontManager] fontWithFamily:_font.familyName
                                                           traits:NSBoldFontMask
                                                           weight:NSFontWeightBold
                                                             size:_fontSize];
}

- (void)setMarkerColour:(NSColor *)markerColour{
    _markerColour = markerColour;
    [self saveColour:_markerColour asKey:kNIFSavedMarkerColour];
    [_associatedModel.controller.tableView reloadData];
}

- (void)setTextColour:(NSColor *)textColour{
    _textColour = textColour;
    [self saveColour:_textColour asKey:kNIFSavedFontColour];
    [_associatedModel.controller.tableView reloadData];
}

- (NSFont *)font{
    return _font;
}

- (NSFont *)boldFont{
    return _boldFont;
}

@end
