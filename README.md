# Usage

Assuming you have following model classes

```objective-c
@interface Cart
@property (nonatomic, copy) NSSet *products;
- (void)addProduct:(Product *)product;
@end

@interface Product
@property (nonatomic, copy) NSString *name;
@end
```

Settings up observer

```objective-c
Cart *cart = ...

NKVOObserver *observer = [[NKVOObserver alloc] initWithObject:cart keyPathes:@[ @"products", @"name" ]]
observer.delegate = self;
[observer startObserving];

Product *product = [Product new];
product.name = @"T-shirt";
[cart addProduct:product];
product.name = @"Red Sweater";
```

`observer:didObserveChange:object:` will be called twice:

* when adding product, `object` is `product` with `name` set to "T-shirt"
* when name is changed to "Red Sweater"
