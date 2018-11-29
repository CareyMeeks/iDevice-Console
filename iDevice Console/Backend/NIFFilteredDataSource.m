//
//  NIFFilteredDataSource.m
//  iDevice Console
//
//  Created by Terry Lewis on 3/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFFilteredDataSource.h"
#import "NIFSyslogOutput.h"

@interface NIFFilteredDataSource () <NIFSyslogRelayDelegate>

@end

static NSString *kReportCrashProcessName = @"ReportCrash";

@implementation NIFFilteredDataSource{
    NSMutableArray *_filteredDataSource;
    NSPredicate *_searchPredicate;
}

- (instancetype)init{
    if (self = [super init]) {
        _filteredDataSource = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)_reloadAllData{
    [self _determineSearchState];
    [_filteredDataSource removeAllObjects];
    NSArray *syslog = [_relay.syslog copy];
    NSLog(@"%@", syslog);
    for (NIFSyslogOutput *output in syslog) {
        if ([self syslogOutputMatchesFilters:output]) {
            [_filteredDataSource addObject:output];
            [self highlightAttributedString:output.attributedMessage];
        }
    }
    [self.delegate filteredDataSourceIssuedChangeRequiringUIUpdate:self];
}

- (void)setRelay:(NIFSyslogRelay *)relay{
//    remove old listener
    [_relay removeListener:self];
    
    _relay = relay;
//    add new listener
    [_relay addListener:self];
    [self _reloadAllData];
    
}

- (void)_determineSearchState{
    if (!_processName && !_searchTerm) {
//        if (_searching) {
//            [self removeAllHighlightsAndReload:YES];
//        }
        _searching = NO;
    }else{
        _searching = YES;
    }
//    if (!_searching) {
//        [self removeAllHighlightsAndReload:YES];
//    }
}

- (void)setProcessName:(NSString *)processName{
    if (processName && processName.length > 0) {
        _processName = processName;
    }else{
        _processName = nil;
    }
    [self _reloadAllData];
}

- (void)setSearchTerm:(NSString *)searchTerm{
    if (searchTerm && searchTerm.length > 0) {
        _searchTerm = searchTerm;
    }else{
        _searchTerm = nil;
    }
    [self removeAllHighlightsAndReload:YES];
    _searchPredicate = [NSPredicate predicateWithBlock:^BOOL(NSString  *_Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject.lowercaseString rangeOfString:_searchTerm].location != NSNotFound;
    }];
    [self _reloadAllData];
}

- (BOOL)hasProcessName{
    return _processName != nil && _processName.length > 0;
}

- (BOOL)syslogOutputMatchesFilters:(NIFSyslogOutput *)output{
    if([self hasProcessName] && ((_showCrashReporterProcess == YES && [kReportCrashProcessName isEqualToString:output.processName] == NO) || _showCrashReporterProcess == NO) && [_processName isEqualToString:output.processName] == NO){
//    if ((_processName) && (![_processName isEqualToString:output.processName] && (_showCrashReporterProcess == YES && ![kReportCrashProcessName isEqualToString:output.processName]))) {
        return NO;
    }
    if (_searchTerm && ![_searchPredicate evaluateWithObject:output.message]) {
        return NO;
    }
    if (_showCrashReporterProcess) {
        
    }
    return YES;
}

- (void)setHighlightColor:(NSColor *)colour term:(NSString *)term inAttributedString:(NSMutableAttributedString *)mutableAttributedString {
    if (!colour) {
        return;
    }
    
    NSUInteger count = 0, length = [mutableAttributedString length];
    NSRange range = NSMakeRange(0, length);
    
    while(range.location != NSNotFound)
    {
        range = [[mutableAttributedString string] rangeOfString:term options:NSCaseInsensitiveSearch range:range];
        if(range.location != NSNotFound) {
            NSRange wordRange = NSMakeRange(range.location, [term length]);
            
            [mutableAttributedString addAttribute:NSBackgroundColorAttributeName value:colour range:wordRange];
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
}

- (void)highlightAttributedString:(NSMutableAttributedString *)attributedString{
    if (!_searchTerm) {
        return;
    }
    [self setHighlightColor:_highlightColour term:_searchTerm inAttributedString:attributedString];
}

- (void)removeAllHighlightsAndReload:(BOOL)reload{
    for (NIFSyslogOutput *output in _filteredDataSource) {
        NSMutableAttributedString *attributedString = output.attributedMessage;
        [attributedString beginEditing];
        [attributedString enumerateAttribute:NSBackgroundColorAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
            [attributedString removeAttribute:NSBackgroundColorAttributeName range:range];
        }];
        [attributedString endEditing];
    }
    if (reload) {
        [self.delegate filteredDataSourceIssuedChangeRequiringUIUpdate:self];
    }
}

- (void)clearPreviousEntries{
    [_filteredDataSource removeAllObjects];
}

- (void)reloadAllMessages{
    [self _reloadAllData];
}

#pragma mark - NIFSyslogRelayDelegate

- (void)syslogRelay:(NIFSyslogRelay *)relay recievedMessage:(NIFSyslogOutput *)message{
    if ([self syslogOutputMatchesFilters:message]) {
        [_filteredDataSource addObject:message];
        [self highlightAttributedString:message.attributedMessage];
        [self.delegate filteredDataSource:self acceptedAddition:message];
    }
}

- (NSArray *)filteredOutput{
    return _filteredDataSource;
}

@end
