// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

@interface JSValue (Types)

- (BOOL)isFunction;
- (BOOL)isTrue;
- (BOOL)isFalse;
- (BOOL)exists;
- (JSStringRef)JSStringRef;

@end
