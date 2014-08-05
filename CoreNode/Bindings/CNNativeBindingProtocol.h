// Copyright 2014-present 650 Industries. All rights reserved.

@class JSContext;
@class JSValue;

@protocol CNNativeBindingProtocol <NSObject>
- (JSValue *)exportsForContext:(JSContext *)context;
@end
