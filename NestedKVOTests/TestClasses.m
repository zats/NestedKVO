//
//  TestClasses.m
//  NestedKVO
//
//  Created by Sasha Zats on 8/1/14.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "TestClasses.h"

#import "NKVOMacros.h"

@implementation CartSection
- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.products = [NSSet set];
    return self;
}
- (void)addProduct:(Product *)object {
    [[self mutableSetValueForKey:NKVOSelfKeyPath(products)] addObject:object];
}
- (void)removeProduct:(Product *)object {
    [[self mutableSetValueForKey:NKVOSelfKeyPath(products)] removeObject:object];
}
@end

@implementation Cart
- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.sections = [NSSet set];
    return self;
}
- (void)addSection:(CartSection *)object {
    [[self mutableSetValueForKey:NKVOSelfKeyPath(sections)] addObject:object];
}
- (void)removeSection:(CartSection *)object {
    [[self mutableSetValueForKey:NKVOSelfKeyPath(sections)] removeObject:object];
}
@end

@implementation Product @end
