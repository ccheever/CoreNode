// Copyright 2014-present 650 Industries. All rights reserved.

@class CNiOSBindings;
@class CNEnvironment;

@interface CNRuntime : NSObject

- (id)init NS_UNAVAILABLE;
- (instancetype)initWithContext:(JSContext *)context rootUrl:(NSURL *)url;

@property (nonatomic, strong, readonly) JSContext *context;
@property (nonatomic, strong, readonly) CNEnvironment *environment;

@property (nonatomic, copy, readonly) NSURL *rootUrl;
@property (nonatomic, copy, readonly) NSURL *bundleUrl;
@property (nonatomic, strong, readonly) CNiOSBindings *iOSBindings;

@property (nonatomic, readonly) dispatch_queue_t jsQueue;
@property (nonatomic, readonly) dispatch_queue_t ioQueue;

+ (JSValue *)evaluateCallbackScript:(NSString *)script inContext:(JSContext *)context;
+ (JSValue *)evaluateCallbackScript:(NSString *)script inContext:(JSContext *)context inFile:(NSURL *)file;
+ (JSValue *)evaluateCallbackScript:(NSString *)script inContext:(JSContext *)context inFile:(NSURL *)file fromLine:(NSUInteger)line;
+ (JSValue *)invokeTarget:(JSValue *)target callbackMethod:(NSString *)method withArguments:(NSArray *)arguments;
+ (JSValue *)invokeCallbackFunction:(JSValue *)function withArguments:(NSArray *)arguments;
+ (JSValue *)invokeCallbackConstructor:(JSValue *)constructor withArguments:(NSArray *)arguments;

- (void)installNodeWithMainScript:(NSURL *)scriptUrl;
- (BOOL)hasActiveJSQueue;

+ (NSURL *)urlWithBase:(NSURL *)base filePath:(NSString *)filename;

@end
