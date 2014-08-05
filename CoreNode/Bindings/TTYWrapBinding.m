// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "TTYWrapBinding.h"

#import <sys/socket.h>
#import <sys/stat.h>

#import "CNRuntime.h"
#import "CNRuntime_Internal.h"
#import "JSContext+Runtime.h"
#import "TTYWrap.h"

typedef NS_ENUM(NSUInteger, TTYWrapHandleType) {
    TTYWrapHandleTypeUnknown,
    TTYWrapHandleTypeFile,
    TTYWrapHandleTypeNamedPipe,
    TTYWrapHandleTypeTCP,
    TTYWrapHandleTypeTTY,
    TTYWrapHandleTypeUDP,
};

@implementation TTYWrapBinding

- (JSValue *)exportsForContext:(JSContext *)context
{
    JSValue *TTYWrapConstructor = [self constructorForTTYWrap:context];
    self.TTY = [JSManagedValue managedValueWithValue:TTYWrapConstructor];
    [context.virtualMachine addManagedReference:self.TTY withOwner:self];
    return [JSValue valueWithObject:self inContext:context];
}

- (JSValue *)constructorForTTYWrap:(JSContext *)context
{
    NSURL *bindingUrl = [CNRuntime urlWithBase:context.runtime.bundleUrl filePath:@"TTYWrap.js"];
    JSValue *factory = [context.runtime evaluateJSAtUrl:bindingUrl];
    if (context.exception) {
        return nil;
    }
    return [factory callWithArguments:@[[TTYWrap class]]];
}

#pragma mark - Bindings

- (BOOL)isTTY:(int)fd
{
    // NOTE: STDIN_FILENO on iOS is a file instead of a TTY
    return [self guessTypeOfDescriptor:fd] == TTYWrapHandleTypeTTY;
}

- (NSString *)guessHandleType:(int)fd
{
    TTYWrapHandleType type = [self guessTypeOfDescriptor:fd];
    switch (type) {
        case TTYWrapHandleTypeUnknown:
            return @"UNKNOWN";
        case TTYWrapHandleTypeFile:
            return @"FILE";
        case TTYWrapHandleTypeNamedPipe:
            return @"PIPE";
        case TTYWrapHandleTypeTCP:
            return @"TCP";
        case TTYWrapHandleTypeTTY:
            return @"TTY";
        case TTYWrapHandleTypeUDP:
            return @"UDP";
        default:
            abort();
            return nil;
    }
}

#pragma mark - Convenience methods

- (TTYWrapHandleType)guessTypeOfDescriptor:(int)fd
{
    // Derived from https://github.com/joyent/libuv/blob/master/src/unix/tty.c
    if (fd < 0) {
        return TTYWrapHandleTypeUnknown;
    }

    if (isatty(fd)) {
        return TTYWrapHandleTypeTTY;
    }

    struct stat status;
    if (fstat(fd, &status)) {
        return TTYWrapHandleTypeUnknown;
    }

    if (S_ISREG(status.st_mode) || S_ISCHR(status.st_mode)) {
        return TTYWrapHandleTypeFile;
    }

    if (S_ISFIFO(status.st_mode)) {
        return TTYWrapHandleTypeNamedPipe;
    }

    if (!S_ISSOCK(status.st_mode)) {
        return TTYWrapHandleTypeUnknown;
    }

    int type;
    socklen_t length = sizeof(type);
    if (getsockopt(fd, SOL_SOCKET, SO_TYPE, &type, &length)) {
        return TTYWrapHandleTypeUnknown;
    }

    struct sockaddr address;
    length = sizeof(address);
    if (getsockname(fd, &address, &length)) {
        return TTYWrapHandleTypeUnknown;
    }

    if (type == SOCK_DGRAM) {
        if (address.sa_family == AF_INET || address.sa_family == AF_INET6) {
            return TTYWrapHandleTypeUDP;
        }
    }

    if (type == SOCK_STREAM) {
        if (address.sa_family == AF_INET || address.sa_family == AF_INET6) {
            return TTYWrapHandleTypeTCP;
        }
        if (address.sa_family == AF_UNIX) {
            return TTYWrapHandleTypeNamedPipe;
        }
    }

    return TTYWrapHandleTypeUnknown;
}

@end
