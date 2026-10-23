#import <Foundation/Foundation+LC32.h>

#import <objc/runtime.h>

/*
 * Foundation declares the legacy NSObject class-versioning methods
 * (+version / +setVersion:) on top of the libobjc class_getVersion /
 * class_setVersion primitives. The guest Foundation shim did not provide
 * them, so [SomeClass version] fell through to forwarding and ended in
 * doesNotRecognizeSelector:. Luxor Evolved Lite hits this at startup on
 * iOS_AppDelegate.
 *
 * The methods are installed at load time with the runtime API instead of an
 * Objective-C category, so they cannot conflict with whatever the SDK headers
 * declare for these deprecated selectors. The version is stored per class by
 * libobjc and is not inherited, which matches Apple's behavior.
 */
static int LC32ClassVersionGet(id self, SEL _cmd) {
    (void)_cmd;
    return class_getVersion((Class)self);
}

static void LC32ClassVersionSet(id self, SEL _cmd, int version) {
    (void)_cmd;
    class_setVersion((Class)self, version);
}

__attribute__((constructor)) static void LC32InstallClassVersion(void) {
    Class metaclass = object_getClass((id)[NSObject class]);
    if(!metaclass) return;
    /* class_addMethod leaves an existing implementation in place. The guest
     * is ARM32, where NSInteger is a 32-bit int ("i"). */
    class_addMethod(metaclass, sel_registerName("version"),
        (IMP)LC32ClassVersionGet, "i@:");
    class_addMethod(metaclass, sel_registerName("setVersion:"),
        (IMP)LC32ClassVersionSet, "v@:i");
}
