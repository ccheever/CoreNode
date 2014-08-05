// Copyright 2014-present 650 Industries. All rights reserved.

@interface JSValue (Errors)

+ (JSValue *)valueWithNewErrorFromSyscall:(NSString *)syscall errorCode:(int)code inContext:(JSContext *)context;
- (NSError *)toError;
- (NSString *)errorString;

@end

NSString * const NTUnderlyingJSErrorKey;
NSString * const NTLineNumberKey;
