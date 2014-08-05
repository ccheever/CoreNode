// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "SmallocBinding.h"

@implementation SmallocBinding

- (JSValue *)exportsForContext:(JSContext *)context
{
    JSValue *exports = [JSValue valueWithNewObjectInContext:context];
    [self exportConstants:exports];
    return exports;
}

- (void)exportConstants:(JSValue *)exports
{
    // See https://github.com/joyent/node/blob/f674b09f40d22915e15b6968aafc5d25ac8178a2/src/smalloc.h#L40
    exports[@"kMaxLength"] = @(0x3FFFFFFF);
}

@end
