@class NSOperationQueue;
@class PMKPromise;

extern NSOperationQueue *PMKOperationQueue();

#define PMK_DEPRECATED(msg) __attribute__((deprecated(msg)))

#define PMKJSONDeserializationOptions ((NSJSONReadingOptions)(NSJSONReadingAllowFragments | NSJSONReadingMutableContainers))

#define PMKHTTPURLResponseIsJSON(rsp) ({ \
    NSString *type = [rsp allHeaderFields][@"Content-Type"]; \
    NSArray *bits = [type componentsSeparatedByString:@";"]; \
    [bits.chuzzle containsObject:@"application/json"]; \
})

extern void *PMKManualReferenceAssociatedObject;

#define PMKRetain(obj)  objc_setAssociatedObject(obj, PMKManualReferenceAssociatedObject, obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC)
#define PMKRelease(obj) objc_setAssociatedObject(obj, PMKManualReferenceAssociatedObject, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC)

typedef void (^PromiseResolver)(id) PMK_DEPRECATED("Use PromiseFulfiller or PromiseRejecter");
typedef void (^PromiseFulfiller)(id) PMK_DEPRECATED("Use PMKPromiseFulfiller");
typedef void (^PromiseRejecter)(NSError *) PMK_DEPRECATED("Use PMKPromiseRejecter");
typedef void (^PMKPromiseFulfiller)(id);
typedef void (^PMKPromiseRejecter)(NSError *);

#define PMKErrorDomain @"PMKErrorDomain"
#define PMKUnderlyingExceptionKey @"PMKUnderlyingExceptionKey"
#define PMKFailingPromiseIndexKey @"PMKFailingPromiseIndexKey"
#define PMKUnhandledExceptionError 1
#define PMKUnknownError 2
#define PMKInvalidUsageError 3
#define PMKAccessDeniedError 4

#define PMKURLErrorFailingURLResponseKey @"PMKURLErrorFailingURLResponseKey"
#define PMKURLErrorFailingDataKey @"PMKURLErrorFailingDataKey"
#define PMKURLErrorFailingStringKey @"PMKURLErrorFailingStringKey"

// deprecated
#define PMKErrorCodeThrown PMKUnhandledExceptionError
#define PMKErrorCodeUnknown PMKUnknownError
#define PMKErrorCodeInvalidUsage PMKInvalidUsageError

extern NSString const * const PMKThrown PMK_DEPRECATED("Use PMKUnderlyingExceptionKey");
