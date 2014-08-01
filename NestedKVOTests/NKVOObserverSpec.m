//
//  NKVOObserverSpec.m
//  NestedKVO
//
//  Created by Sasha Zats on 8/1/14.
//  Copyright 2014 Sash Zats. All rights reserved.
//

#import "NestedKVO.h"

#import "TestClasses.h"

SpecBegin(NKVOObserver)

describe(@"NKVOObserver", ^{
    
    describe(@"initialization", ^{
        it(@"should raise an exception when created without object", ^{
            expect(^{
                __unused id observer = [[NKVOObserver alloc] initWithObject:nil
                                                                  keyPathes:@[@"stub"]];
            }).to.raiseAny();
        });
        
        it(@"should raise an exception when created without keyPathes", ^{
            expect(^{
                __unused id observer = [[NKVOObserver alloc] initWithObject:@0
                                                                  keyPathes:nil];
            }).to.raiseAny();
        });
        
        it(@"should raise an exception when created with empty keyPathes", ^{
            expect(^{
                __unused id observer = [[NKVOObserver alloc] initWithObject:@0
                                                                  keyPathes:@[]];
            }).to.raiseAny();
        });
    });
    
    describe(@"observation", ^{
        describe(@"first level of nestedness", ^{
            __block Cart *cart;
            __block NKVOObserver *observer;

            beforeEach(^{
                cart = [Cart new];
                observer = [[NKVOObserver alloc] initWithObject:cart keyPathes:@[ NKVOTypedKeyPath(Cart, sections) ]];
            });
            
            it(@"should call delegate upon start of observation", ^{
                id<NKVOObserverDelegate> delegate = mockProtocol(@protocol(NKVOObserverDelegate));
                observer.delegate = delegate;
                [observer startObserving];
                [MKTVerify(delegate) observer:observer
                             didObserveChange:anything()
                                       object:cart];
            });
            
            it(@"should not call delegate if startObserving was not called", ^{
                id<NKVOObserverDelegate> delegate = mockProtocol(@protocol(NKVOObserverDelegate));
                observer.delegate = delegate;
                [MKTVerifyCount(delegate, never()) observer:observer
                                           didObserveChange:anything()
                                                     object:cart];
            });


            it(@"should call delegate upon mutating of a collection", ^{
                [observer startObserving];
                
                id<NKVOObserverDelegate> delegate = mockProtocol(@protocol(NKVOObserverDelegate));
                observer.delegate = delegate;
                
                [cart addSection:[CartSection new]];

                [MKTVerify(delegate) observer:observer
                             didObserveChange:anything()
                                       object:cart];
            });
        });
        
        describe(@"second level of nestedness", ^{
            __block Cart *cart;
            __block NKVOObserver *observer;
            
            beforeEach(^{
                cart = [Cart new];
                observer = [[NKVOObserver alloc] initWithObject:cart keyPathes:@[
                    NKVOTypedKeyPath(Cart, sections),
                    NKVOTypedKeyPath(CartSection, products)
                ]];
            });
            
            it(@"should not call delegate if composite keyPath did not match anything", ^{
                id<NKVOObserverDelegate> delegate = mockProtocol(@protocol(NKVOObserverDelegate));
                observer.delegate = delegate;
                [observer startObserving];
                [MKTVerifyCount(delegate, never()) observer:observer
                                           didObserveChange:anything()
                                                     object:anything()];
            });

            it(@"should not call delegate if startObserving was not called", ^{
                [cart addSection:[CartSection new]];

                id<NKVOObserverDelegate> delegate = mockProtocol(@protocol(NKVOObserverDelegate));
                observer.delegate = delegate;
                
                [cart addSection:[CartSection new]];
                
                [MKTVerifyCount(delegate, never()) observer:anything()
                                           didObserveChange:anything()
                                                     object:anything()];
            });
            
            it(@"should call delegate upon settings a value collection", ^{
                [observer startObserving];
                
                id<NKVOObserverDelegate> delegate = mockProtocol(@protocol(NKVOObserverDelegate));
                observer.delegate = delegate;
                
                CartSection *section = [CartSection new];
                [cart addSection:section];
                
                [MKTVerify(delegate) observer:observer
                             didObserveChange:anything()
                                       object:anything()];
            });

            it(@"should call delegate upon mutating of a collection", ^{
                id<NKVOObserverDelegate> delegate = mockProtocol(@protocol(NKVOObserverDelegate));
                
                CartSection *section = [CartSection new];
                [cart addSection:section];
                
                [observer startObserving];
                observer.delegate = delegate;
                
                Product *product = [Product new];
                [section addProduct:product];
                
                MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
                [MKTVerify(delegate) observer:observer
                             didObserveChange:anything()
                                       object:[argument capture]];
                expect([argument value]).equal(section);
            });
        });
        
        describe(@"nested keyPath with a non collection property at the end", ^{
            __block Cart *cart;
            __block NKVOObserver *observer;
            __block id<NKVOObserverDelegate> delegate;
            
            beforeEach(^{
                cart = [Cart new];
                
                observer = [[NKVOObserver alloc] initWithObject:cart keyPathes:@[
                    NKVOTypedKeyPath(Cart, sections),
                    NKVOTypedKeyPath(CartSection, products),
                    NKVOTypedKeyPath(Product, name)
                ]];
                
                delegate = mockProtocol(@protocol(NKVOObserverDelegate));
                observer.delegate = delegate;
            });
            
            it(@"should report just the final change", ^{
                [observer startObserving];
                
                CartSection *section1 = [CartSection new];
                [cart addSection:section1];
                Product *product1 = [Product new];
                [section1 addProduct:product1];
                
                CartSection *section2 = [CartSection new];
                [cart addSection:section2];
                Product *product2 = [Product new];
                [section2 addProduct:product2];
                product2.name = @"T-shirt";
                
                [cart addSection:[CartSection new]];
                
                MKTArgumentCaptor *argument = [MKTArgumentCaptor new];
                [MKTVerifyCount(delegate, times(3)) observer:observer
                                            didObserveChange:[argument capture]
                                                      object:anything()];
                expect([argument allValues][0][NSKeyValueChangeNewKey]).equal([NSNull null]);
                expect([argument allValues][1][NSKeyValueChangeNewKey]).equal([NSNull null]);
                expect([argument allValues][2][NSKeyValueChangeNewKey]).equal(@"T-shirt");
            });
            
            it(@"should stop reporting changes after item is removed from the collection", ^{
                
                CartSection *section1 = [CartSection new];
                [cart addSection:section1];
                Product *product1 = [Product new];
                [section1 addProduct:product1];
                
                CartSection *section2 = [CartSection new];
                [cart addSection:section2];
                Product *product2 = [Product new];
                [section2 addProduct:product2];
                product2.name = @"T-shirt";
                
                [cart addSection:[CartSection new]];
                
                [observer startObserving];
                [MKTVerifyCount(delegate, times(2)) observer:observer
                                            didObserveChange:anything()
                                                      object:anything()];
                [section2 removeProduct:product2];
                product2.name = @"This change won't be registered";
                [MKTVerifyCount(delegate, times(2)) observer:anything()
                                            didObserveChange:anything()
                                                      object:anything()];

            });
        });
        
        describe(@"not observing changes after removing from collection", ^{
            __block Cart *cart;
            __block NKVOObserver *observer;
            
            beforeEach(^{
                cart = [Cart new];
                
                observer = [[NKVOObserver alloc] initWithObject:cart keyPathes:@[
                    NKVOTypedKeyPath(Cart, sections),
                    NKVOTypedKeyPath(CartSection, products),
                    NKVOTypedKeyPath(Product, name)
                ]];
            });
            
            
            
        });
    });

});

SpecEnd
