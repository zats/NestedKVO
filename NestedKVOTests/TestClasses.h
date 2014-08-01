//
//  TestClasses.h
//  NestedKVO
//
//  Created by Sasha Zats on 8/1/14.
//  Copyright (c) 2014 Sash Zats. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CartSection, Product;
@interface Cart : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSSet *sections;
- (void)addSection:(CartSection *)object;
- (void)removeSection:(CartSection *)object;
@end

@interface CartSection : NSObject
@property (nonatomic, copy) NSSet *products;
- (void)addProduct:(Product *)object;
- (void)removeProduct:(Product *)object;
@end

@interface Product : NSObject
@property (nonatomic, copy) NSString *name;
@end

