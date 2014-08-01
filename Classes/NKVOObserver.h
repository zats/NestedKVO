//
//  NKVOObserver.h
//  NestedKVO
//
//  Created by Sasha Zats on 8/1/14.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NKVOObserverDelegate;

@interface NKVOObserver : NSObject

@property (nonatomic, readonly) NSUInteger observersCount;
@property (nonatomic, weak, readonly) id object;
@property (nonatomic, copy, readonly) NSArray *keyPathes;

@property (nonatomic, weak) id<NKVOObserverDelegate> delegate;

- (instancetype)initWithObject:(id)object keyPathes:(NSArray *)keyPath;

- (void)startObserving;
- (void)stopObserving;

- (BOOL)isObserving;

@end

@protocol NKVOObserverDelegate <NSObject>

- (void)observer:(NKVOObserver *)observer didObserveChange:(NSDictionary *)change object:(id)object;

@end
