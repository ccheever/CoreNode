// Copyright 2014-present 650 Industries. All rights reserved.

#import "JSValue+Errors.h"

#import <string.h>

static const NSUInteger JSErrorStackTraceLimit = 7;

@implementation JSValue (Errors)

+ (JSValue *)valueWithNewErrorFromSyscall:(NSString *)syscall errorCode:(int)code inContext:(JSContext *)context
{
    char *errorName = strerror(code);
    NSString *message = [NSString stringWithFormat:@"%@ failed (%s)", syscall, errorName];
    JSValue *error = [JSValue valueWithNewErrorFromMessage:message inContext:context];
    error[@"code"] = [NSNumber numberWithInt:code];
    error[@"syscall"] = syscall;
    return error;
}

- (NSError *)toError
{
    NSInteger code = [self[@"code"] isNumber] ? [[self[@"code"] toNumber] integerValue] : -1;
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[NSLocalizedDescriptionKey] = [self[@"message"] toString];
    info[NTUnderlyingJSErrorKey] = self;
    info[NTLineNumberKey] = [self[@"line"] toNumber];
    if ([self hasProperty:@"sourceURL"]) {
        info[NSFilePathErrorKey] = [self[@"sourceURL"] toString];
    }
    return [NSError errorWithDomain:@"net.sixfivezero" code:code userInfo:info];
}

- (NSString *)errorString
{
    NSMutableString *errorString = [NSMutableString stringWithFormat:@"%@: %@", self[@"name"], self[@"message"]];

    NSArray *stackLines = [[self[@"stack"] toString] componentsSeparatedByString:@"\n"];
    NSUInteger stackHeight = [stackLines count];
    if (stackHeight <= JSErrorStackTraceLimit) {
        for (NSUInteger i = 0; i < stackHeight; i++) {
            [errorString appendString:@"\n  at "];
            [errorString appendString:stackLines[i]];
        }
    } else {
        NSUInteger topLineCount = JSErrorStackTraceLimit / 2;
        NSUInteger bottomLineCount = MAX(JSErrorStackTraceLimit - topLineCount - 1, 0);
        NSUInteger hiddenLineCount = stackHeight - topLineCount - bottomLineCount;

        for (NSUInteger i = 0; i < topLineCount; i++) {
            [errorString appendString:@"\n  at "];
            [errorString appendString:stackLines[i]];
        }

        [errorString appendFormat:@"\n  ...(%ld frames hidden)...", (long)hiddenLineCount];

        for (NSUInteger i = stackHeight - bottomLineCount; i < stackHeight; i++) {
            [errorString appendString:@"\n  at "];
            [errorString appendString:stackLines[i]];
        }
    }

    return errorString;
}

@end

NSString * const NTUnderlyingJSErrorKey = @"NSUnderlyingJSErrorKey";
NSString * const NTLineNumberKey = @"NTLineNumberKey";
