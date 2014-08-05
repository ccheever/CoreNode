// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

@interface JSContext (Errors)

- (NSString *)backtrace;
- (BOOL)boolFromExceptionNotification:(JSValueRef)exception;
- (JSValue *)valueFromExceptionNotification:(JSValueRef)exception;

@end
