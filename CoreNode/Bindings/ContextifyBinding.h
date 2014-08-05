// Copyright 2014-present 650 Industries. All rights reserved.

#import "CNNativeBindingProtocol.h"
#import "ContextifyContext.h"

@protocol ContextifyExports <JSExport>

@property (strong, nonatomic) JSManagedValue *ContextifyScript;

- (JSValue *)makeContext:(JSValue *)sandbox;
- (BOOL)isContext:(JSValue *)sandbox;

@end

@interface ContextifyBinding : NSObject <ContextifyExports, CNNativeBindingProtocol>

@property (strong, nonatomic) JSManagedValue *ContextifyScript;

@end
