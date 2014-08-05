// Copyright 2014-present 650 Industries. All rights reserved.

#import "CNNativeBindingProtocol.h"


@interface NativesBinding : NSObject <CNNativeBindingProtocol>

- (void)overrideModule:(NSString *)moduleName withSource:(NSString *)source;

@end
