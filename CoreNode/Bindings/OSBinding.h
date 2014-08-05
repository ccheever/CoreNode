// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "CNNativeBindingProtocol.h"

@interface OSBinding : NSObject <CNNativeBindingProtocol>

- (NSString *)endianness;
- (NSString *)hostname;
- (NSArray *)loadAverage;
- (NSNumber *)uptime;
- (NSNumber *)freeMemory;
- (NSNumber *)totalMemory;
- (NSArray *)CPUs;
- (NSString *)OSType;
- (NSString *)OSRelease;
- (NSDictionary *)interfaceAddresses;

@end
