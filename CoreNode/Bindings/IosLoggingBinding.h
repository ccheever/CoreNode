// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "CNNativeBindingProtocol.h"

@protocol IosLoggingExports <JSExport>

- (void)logError:(NSString *)message;
- (void)logWarning:(NSString *)message;
- (void)logInfo:(NSString *)message;
- (void)logDebug:(NSString *)message;
- (void)logVerbose:(NSString *)message;

@end


@interface IosLoggingBinding : NSObject <IosLoggingExports, CNNativeBindingProtocol>

@end

