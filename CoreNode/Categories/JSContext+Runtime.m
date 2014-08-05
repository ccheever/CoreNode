// Copyright 2014-present 650 Industries. All rights reserved.

#import "JSContext+Runtime.h"

@import ObjectiveC;

@implementation JSContext (Runtime)

static const void *JSContextRuntimeKey = &JSContextRuntimeKey;

- (CNRuntime *)runtime
{
    return objc_getAssociatedObject(self, JSContextRuntimeKey);
}

- (void)setRuntime:(CNRuntime *)runtime
{
    objc_setAssociatedObject(self, JSContextRuntimeKey, runtime, OBJC_ASSOCIATION_ASSIGN);
}


@end
