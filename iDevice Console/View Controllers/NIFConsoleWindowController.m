//
//  NIFConsoleWindowController.m
//  iDevice Console
//
//  Created by Terry Lewis on 24/11/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFConsoleWindowController.h"
#import "NIFConsoleSettingsManager.h"

@interface NIFConsoleWindowController () <NSSearchFieldDelegate, NSOpenSavePanelDelegate, NSWindowDelegate>

@end

@interface NSToolbarItem (Private)

- (NSButton *)_button;

@end

@implementation NSView (Debug)

- (NSArray *)allSubviews {
    NSMutableArray *allSubviews = [NSMutableArray arrayWithObject:self];
    NSArray *subviews = [self subviews];
    for (NSView *view in subviews) {
        [allSubviews addObjectsFromArray:[view allSubviews]];
    }
    return [allSubviews copy];
}

- (void)logViewHierarchy{
    NSLog(@"%@", self);
    for (NSView *subview in self.subviews)
    {
        [subview logViewHierarchy];
    }
}

@end

@implementation NIFConsoleWindowController{
    BOOL _toolbarItemContainsValidButton;
    NSFontPanel *_fontPanel;
    NSColorPanel *_colourPanel;
}

@dynamic contentViewController;

static NIFConsoleWindowController *sharedController;

+ (instancetype)sharedController{
    return sharedController;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    sharedController = self;
    self.contentViewController.windowController = self;
    
    [_clearItem setTarget:self.contentViewController];
    [_clearItem setAction:@selector(clearButtonClicked:)];
    
    [_reloadItem setTarget:self.contentViewController];
    [_reloadItem setAction:@selector(reloadButtonClicked:)];
    
    [_insertMarkerItem setTarget:self.contentViewController];
    [_insertMarkerItem setAction:@selector(insertMarkerButtonClicked:)];
    
    [_toggleDeviceListItem setVariableLabels:@[@"Show Device List", @"Hide Device List"]];
    
    [_toggleDeviceListItem setTarget:self];
    [_toggleDeviceListItem setAction:@selector(toggleSidebar:)];
    
    [self setupOptionsButton];
    
    _searchField.delegate = self;
    
    
    NSFontManager *manager = [NSFontManager sharedFontManager];
    [manager setTarget:self];
//    [manager setAction:@selector(changeDefaultFont:)];
    manager.delegate = self;
    
    _fontPanel = [manager fontPanel:YES];
    [_fontPanel setPanelFont:[[NIFConsoleSettingsManager sharedManager] font] isMultiple:NO];
    _fontPanel.delegate = self;
    
    _colourPanel = [NSColorPanel sharedColorPanel];
    _colourPanel.color = [[NIFConsoleSettingsManager sharedManager] textColour];
    [_colourPanel setTarget:self];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)setupOptionsButton{
    if ([_optionsItem respondsToSelector:@selector(_button)]) {
        NSButton *button = [_optionsItem _button];
        if ([button respondsToSelector:@selector(bounds)]) {
            _toolbarItemContainsValidButton = YES;
        }
    }
    if (!_toolbarItemContainsValidButton) {
        NSButton *fallbackButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
        fallbackButton.image = _optionsItem.image;
        fallbackButton.bordered = NO;
        _optionsItem.view = fallbackButton;
    }
    
    [_optionsItem setTarget:self];
    [_optionsItem setAction:@selector(optionsButtonClicked:)];
}

- (void)optionsButtonClicked:(NSToolbarItem *)item{
    id button = nil;
    if (_toolbarItemContainsValidButton) {
        button = [item performSelector:@selector(_button)];
    }else{
        button = (NSButton *)item;
    }
//    NSLog(@"%@", [NIFReflectionAnalyser instanceMethodsForClass:[button class]]);
    [self.contentViewController showFilterPopoverRelativeToView:button];
}

- (void)toggleSidebar:(NSButton *)item{
//    NSLog(@"%@", NSStringFromRect(_toggleDeviceListItem.button.frame));
    [self.contentViewController toggleDeviceListButtonClicked:item];
//    [_toggleDeviceListItem.button logViewHierarchy];
//    NSButton *button = _toggleDeviceListItem.button;
//    button.alphaValue = 0;
    
//    NSLog(@"%@", NSStringFromSize([button sizeThatFits:NSMakeSize(FLT_MAX, FLT_MAX)]));
}

- (void)searchFieldDidStartSearching:(NSSearchField *)sender{
    [self.contentViewController beginSearching:sender];
}

- (void)searchFieldDidEndSearching:(NSSearchField *)sender{
    [self.contentViewController endSearching:sender];
}

- (void)controlTextDidChange:(NSNotification *)obj{
    [self.contentViewController performSearchWithSearchField:obj.object];
}

- (void)copy:(id)sender{
//    NSLog(@"COPY");
    [self.contentViewController performCopyAction:sender];
}

- (void)contactDeveloperButtonClicked:(id)sender{
    NSString *recipient = @"<redacted>";
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *versionString = [infoDict valueForKey: @"CFBundleShortVersionString"];
    NSString *nameString = [infoDict valueForKey: @"CFBundleName"];
    
    NSString *mailBody = [NSString stringWithFormat:@"Name: %@\nVersion: %@", nameString, versionString];
    NSString *mailtoAddress = [[NSString stringWithFormat:@"mailto:%@?Subject=%@&body=%@",recipient, @"iConsole Support", mailBody] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:mailtoAddress]];
}

- (void)donateButtonClicked:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=DCPZ7LNKWPN6W&lc=AU&item_name=Terry%20Lewis&currency_code=AUD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted"]];
}

- (void)previousMarkerClicked:(nullable id)sender{
    [self.contentViewController navigateToPreviousMarker];
}

- (void)nextMarkerButtonClicked:(nullable id)sender{
    [self.contentViewController navigateToNextMarker];
}

- (void)showFontsButtonClicked:(nullable id)sender{
    [_fontPanel makeKeyAndOrderFront:nil];
    [_fontPanel setPanelFont:[[NIFConsoleSettingsManager sharedManager] font] isMultiple:NO];
}

- (void)showColoursButtonClicked:(nullable id)sender{
    [_colourPanel makeKeyAndOrderFront:nil];
    [_colourPanel setAction:@selector(changeTextColour:)];
    _colourPanel.color = [[NIFConsoleSettingsManager sharedManager] textColour];
}

- (void)showMarkerColoursButtonClicked:(nullable id)sender{
    [_colourPanel makeKeyAndOrderFront:nil];
    [_colourPanel setAction:@selector(changeMarkerColour:)];
    _colourPanel.color = [[NIFConsoleSettingsManager sharedManager] markerColour];
}

- (void)changeFont:(NSFontManager *)fontManager{
    NSFont *font = [[NIFConsoleSettingsManager sharedManager] font];

    font = [fontManager convertFont:font];
    if (font) {
        [[NIFConsoleSettingsManager sharedManager] setFont:font];
    }
}

- (void)changeTextColour:(NSColorPanel *)sender{
    [[NIFConsoleSettingsManager sharedManager] setTextColour:[sender color]];
}

- (void)changeMarkerColour:(NSColorPanel *)sender{
    [[NIFConsoleSettingsManager sharedManager] setMarkerColour:[sender color]];
}

#pragma mark - NSOpenSavePanelDelegate

- (NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel{
    return NSFontPanelSizeModeMask|NSFontPanelCollectionModeMask|NSFontPanelTextColorEffectModeMask;
}

@end
