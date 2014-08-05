// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "TTYWrap.h"

@interface TTYWrap ()

@property (nonatomic) int fd;
@property (nonatomic) BOOL readable;

//NODE_SET_PROTOTYPE_METHOD(t, "close", HandleWrap::Close);
//NODE_SET_PROTOTYPE_METHOD(t, "unref", HandleWrap::Unref);
//
//NODE_SET_PROTOTYPE_METHOD(t, "readStart", StreamWrap::ReadStart);
//NODE_SET_PROTOTYPE_METHOD(t, "readStop", StreamWrap::ReadStop);
//
//NODE_SET_PROTOTYPE_METHOD(t, "writeBuffer", StreamWrap::WriteBuffer);
//NODE_SET_PROTOTYPE_METHOD(t,
//                          "writeAsciiString",
//                          StreamWrap::WriteAsciiString);
//NODE_SET_PROTOTYPE_METHOD(t, "writeUtf8String", StreamWrap::WriteUtf8String);
//NODE_SET_PROTOTYPE_METHOD(t, "writeUcs2String", StreamWrap::WriteUcs2String);
//
//NODE_SET_PROTOTYPE_METHOD(t, "getWindowSize", TTYWrap::GetWindowSize);
//NODE_SET_PROTOTYPE_METHOD(t, "setRawMode", SetRawMode);

@end


@implementation TTYWrap

+ (instancetype)TTYWrapWithFile:(int)fd readable:(BOOL)readable
{
    return [[TTYWrap alloc] initWithFile:fd readable:readable];
}

- (instancetype)initWithFile:(int)fd readable:(BOOL)readable
{
    if (self = [super init]) {
        self.fd = fd;
        self.readable = readable;
    }
    return self;
}

@end
