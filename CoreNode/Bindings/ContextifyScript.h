// Copyright (c) 2014-present 650 Industries, Inc. All rights reserved.

#import "JSExport+Macros.h"

@protocol ContextifyScriptExports <JSExport>

JSExportNullarySelectorAs(newScript,
+ (instancetype)script
);

JSExportAs(runInContext,
- (JSValue *)runCode:(JSValue *)code inSandbox:(JSValue *)sandbox withFilename:(JSValue *)filename
);

JSExportAs(runInThisContext,
- (JSValue *)runCode:(JSValue *)code withFilename:(JSValue *)filename
);

@end


@interface ContextifyScript : NSObject <ContextifyScriptExports>

@end
