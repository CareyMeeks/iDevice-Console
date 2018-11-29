//
//  NIFFilteredDataSource.h
//  iDevice Console
//
//  Created by Terry Lewis on 3/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NIFSyslogOutput.h"
#import "NIFSyslogRelay.h"
#import <AppKit/AppKit.h>

@class NIFFilteredDataSource;

@protocol NIFFilteredDataSourceDelegate <NSObject>

- (void)filteredDataSource:(NIFFilteredDataSource *)dataSource acceptedAddition:(NIFSyslogOutput *)addition;
- (void)filteredDataSourceIssuedChangeRequiringUIUpdate:(NIFFilteredDataSource *)dataSource;

@end

@interface NIFFilteredDataSource : NSObject

@property (nonatomic, strong) NSString *searchTerm, *processName;
@property (nonatomic) BOOL showCrashReporterProcess;
@property (nonatomic, strong) NIFSyslogRelay *relay;
@property (nonatomic, readonly) BOOL searching;
@property (nonatomic, weak) id<NIFFilteredDataSourceDelegate> delegate;
@property (nonatomic, strong) NSColor *highlightColour;

- (NSArray *)filteredOutput;
- (void)clearPreviousEntries;
- (void)reloadAllMessages;

@end
