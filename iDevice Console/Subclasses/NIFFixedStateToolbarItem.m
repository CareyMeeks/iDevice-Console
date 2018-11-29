//
//  NIFToolbarItem.m
//  iDevice Console
//
//  Created by Terry Lewis on 1/12/2015.
//  Copyright © 2015 Terry Lewis. All rights reserved.
//

#import "NIFFixedStateToolbarItem.h"

@interface NSToolbarItem (Private)

@property (nonatomic) id _allPossibleLabelsToFit;
- (void)_setAllPossibleLabelsToFit:(id)arg1;

@end

@implementation NIFFixedStateToolbarItem

- (void)setLabelUsingIndexedVariant:(NSInteger)index{
    self.label = _variableLabels[index];
    _currentIndex = index;
}

- (void)setVariableLabels:(NSArray *)variableLabels{
    _variableLabels = variableLabels;
    if ([self respondsToSelector:@selector(_setAllPossibleLabelsToFit:)]) {
        [self _setAllPossibleLabelsToFit:variableLabels];
    }
}

@end
