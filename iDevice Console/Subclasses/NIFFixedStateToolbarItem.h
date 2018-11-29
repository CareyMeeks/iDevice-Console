//
//  NIFToolbarItem.h
//  iDevice Console
//
//  Created by Terry Lewis on 1/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NIFFixedStateToolbarItem : NSToolbarItem

@property (nonatomic, strong) NSArray *variableLabels;
@property (nonatomic) NSInteger currentIndex;
- (void)setLabelUsingIndexedVariant:(NSInteger)index;

@end
