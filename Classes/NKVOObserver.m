//
//  NKVOObserver.m
//  NestedKVO
//
//  Created by Sasha Zats on 8/1/14.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import "NKVOObserver.h"

#import "NKVOMacros.h"
#import <KVOController/FBKVOController.h>

@interface NKVOObserver ()

@property (nonatomic, weak) id object;
@property (nonatomic, copy) NSArray *keyPathes;

@property (nonatomic, readonly, getter=isRootObserver) BOOL rootObserver;
@property (nonatomic, readonly, getter=isLeafObserver) BOOL leafObserver;
@property (nonatomic, strong) FBKVOController *observerController;
@property (nonatomic, copy) NSSet *observers;
@property (nonatomic, weak) NKVOObserver *parentObserver;

@end

@implementation NKVOObserver

- (instancetype)initWithObject:(id)object keyPathes:(NSArray *)keyPath {
    NSParameterAssert(object);
    NSParameterAssert(keyPath.count);
    self = [super init];
    if (!self) {
        return nil;
    }
    self.object = object;
    self.keyPathes = keyPath;
    self.observers = [NSSet set];

    return self;
}

- (instancetype)init {
    return [self initWithObject:nil keyPathes:nil];
}

- (BOOL)isRootObserver {
    return self.parentObserver == nil;
}

- (BOOL)isLeafObserver {
    return self.keyPathes.count == 1;
}

- (NSUInteger)observersCount {
    return self.observers.count;
}

- (void)startObserving {
    [self willChangeValueForKey:NKVOSelfKeyPath(isObserving)];
    
    FBKVOController *controller = [FBKVOController controllerWithObserver:self];
    [controller observe:self.object
                keyPath:[self.keyPathes firstObject]
                options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                 action:@selector(_handleChanges:object:)];
    
    for (NKVOObserver *observer in self.observers) {
        [observer startObserving];
    }
    
    self.observerController = controller;
    [self didChangeValueForKey:NKVOSelfKeyPath(isObserving)];
}

- (void)stopObserving {
    [self willChangeValueForKey:NKVOSelfKeyPath(isObserving)];
    
    [self.observerController unobserveAll];
    self.observerController = nil;
    
    for (NKVOObserver *observer in self.observers) {
        [observer stopObserving];
    }
    
    [self didChangeValueForKey:NKVOSelfKeyPath(isObserving)];
}

- (BOOL)isObserving {
    return self.observerController != nil;
}

#pragma mark - Private

- (void)_handleChanges:(NSDictionary *)change object:(id)object {
    if (self.isLeafObserver) {
        [self _handleLeafChange:change object:object];
    } else {
        [self _handleIntermediateChange:change];
    }
}

- (void)_handleLeafChange:(NSDictionary *)change object:(id)object {
    [self _delegateDidObserveChange:change withObject:object];
}

- (void)_delegateDidObserveChange:(NSDictionary *)change withObject:(id)object {
    if (self.isRootObserver) {
        [self.delegate observer:self didObserveChange:change object:object];
    } else {
        [self.parentObserver _delegateDidObserveChange:change withObject:object];
    }
}

- (void)_handleIntermediateChange:(NSDictionary *)change {
    NSKeyValueChange type = [change[NSKeyValueChangeKindKey] intValue];
    switch (type) {
        case NSKeyValueChangeSetting:
            // remove previous observers
            [self _removeObserverFromOldValues:change[NSKeyValueChangeOldKey]];
            // add new observers
            [self _addObserverForNewValue:change[NSKeyValueChangeNewKey]];
            break;
            
        case NSKeyValueChangeInsertion:
            // add new observers
            [self _addObserverForNewValue:change[NSKeyValueChangeNewKey]];
            break;
            
        case NSKeyValueChangeRemoval:
            [self _removeObserverFromOldValues:change[NSKeyValueChangeOldKey]];
            break;
            
        case NSKeyValueChangeReplacement:
            break;
    }
}

#pragma mark - Removing observers

- (void)_removeObserverFromOldValues:(id)object {
    if (!object) {
        return;
    }
    
    if ([object isKindOfClass:[NSSet class]] ||
        [object isKindOfClass:[NSArray class]]) {
        [self _removeObserverForCollection:object];
    } else {
        [self _removeObserverFromOldValues:object];
    }
}

- (void)_removeObserverForCollection:(id<NSFastEnumeration>)collection {
    for (id object in collection) {
        [self _removeObservationForObject:object];
    }
}

- (void)_removeObservationForObject:(id)object {
    NKVOObserver *observer = nil;
    for (NKVOObserver *observerr in self.observers) {
        if (observerr.object == object) {
            observer = observerr;
            break;
        }
    }
    NSAssert(observer, @"Observer was not registered for object %@", object);
    [[self mutableSetValueForKey:NKVOSelfKeyPath(observers)] removeObject:observer];
    [observer stopObserving];
    observer.delegate = nil;
}

#pragma mark - Private adding observers

- (void)_addObserverForNewValue:(id)object {
    if ([object isKindOfClass:[NSSet class]] ||
        [object isKindOfClass:[NSArray class]]) {
        [self _addObserversForCollection:object];
    } else {
        [self _addObserverForNextKeyPath:object];
    }
}

- (void)_addObserversForCollection:(id)collection {
    for (id object in collection) {
        [self _addObserverForNextKeyPath:object];
    }
}

- (void)_addObserverForNextKeyPath:(id)object {
    NSAssert(!self.isLeafObserver, @"Can not add further observer as I am a leaf observer: %@", self.keyPathes);
    NSArray *nextKeyPathes = [self.keyPathes subarrayWithRange:NSMakeRange(1, self.keyPathes.count - 1)];
    NKVOObserver *observer = [[[self class] alloc] initWithObject:object
                                                        keyPathes:nextKeyPathes];
    [[self mutableSetValueForKey:NKVOSelfKeyPath(observers)] addObject:observer];
    observer.parentObserver = self;
    
    if ([self isObserving]) {
        [observer startObserving];
    }
}

@end
