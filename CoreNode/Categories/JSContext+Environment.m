// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "JSContext+Environment.h"

#import "JSContext+Runtime.h"
#import "CNRuntime.h"

@implementation JSContext (Environment)

- (CNEnvironment *)environment
{
    return self.runtime.environment;
}

@end
