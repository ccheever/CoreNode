// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "CNNativeBindingProtocol.h"

@protocol TTYWrapExports <JSExport>

@property (strong, nonatomic) JSManagedValue *TTY;

- (BOOL)isTTY:(int)fd;
- (NSString *)guessHandleType:(int)fd;

@end

@interface TTYWrapBinding : NSObject <TTYWrapExports, CNNativeBindingProtocol>
@property (strong, nonatomic) JSManagedValue *TTY;
@end
