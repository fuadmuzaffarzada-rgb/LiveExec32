#import <Foundation/Foundation.h>

/*
 * The shim generator skips selectors that take a C function pointer ("^?"), so
 * these NSArray methods had no guest implementation. A call fell through to
 * guest message forwarding, which cannot marshal a function pointer and
 * aborted ("unsupported argument 2 encoding ^?"). Luxor Evolved Lite calls
 * -[NSMutableArray sortedArrayUsingFunction:context:] during startup.
 *
 * Like -[NSMutableArray sortUsingFunction:context:], keep the guest function
 * and opaque context in the guest and let the existing block bridge convert
 * the elements and the signed comparison result. The category is on NSArray so
 * that NSMutableArray receivers inherit it.
 */
@implementation NSArray (LC32Sorting)

- (NSArray *)sortedArrayUsingFunction:(NSInteger (NS_NOESCAPE *)(id, id, void *))compare
                              context:(void *)context {
    return [self sortedArrayUsingComparator:^NSComparisonResult(id first, id second) {
        return compare(first, second, context);
    }];
}

/* The hint (from -sortedArrayHint) is only a performance cache for the
 * original implementation; ignoring it never changes the sorted result. */
- (NSArray *)sortedArrayUsingFunction:(NSInteger (NS_NOESCAPE *)(id, id, void *))compare
                              context:(void *)context
                                 hint:(NSData *)hint {
    (void)hint;
    return [self sortedArrayUsingFunction:compare context:context];
}

@end
