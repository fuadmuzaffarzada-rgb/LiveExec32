#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

/* Diagnostic only: records AVAudioPlayer creation and play calls to
 * lc32-avplayer-log.txt in LiveContainer's Documents folder, so we can see
 * whether a game plays its music with AVAudioPlayer and what the result is.
 * Does not change behavior. */
static unsigned LC32PlayerLogCount;

static void LC32PlayerLog(const char *format, ...)
        __attribute__((format(printf, 1, 2)));
static void LC32PlayerLog(const char *format, ...) {
    if(LC32PlayerLogCount >= 200) return;
    ++LC32PlayerLogCount;
    char line[512];
    va_list arguments;
    va_start(arguments, format);
    vsnprintf(line, sizeof(line) - 2, format, arguments);
    va_end(arguments);
    strcat(line, "\n");
    fputs(line, stderr);
    char exe[1024];
    uint32_t exeSize = sizeof(exe);
    if(_NSGetExecutablePath(exe, &exeSize) == 0) {
        char *marker = strstr(exe, "/Documents/");
        if(marker) {
            strcpy(marker + strlen("/Documents/"), "lc32-avplayer-log.txt");
            FILE *file = fopen(exe, "a");
            if(file) { fputs(line, file); fclose(file); }
        }
    }
}

static void LC32PlayerSwizzle(SEL original, SEL replacement) {
    Method a = class_getInstanceMethod([AVAudioPlayer class], original);
    Method b = class_getInstanceMethod([AVAudioPlayer class], replacement);
    if(a && b) method_exchangeImplementations(a, b);
    else LC32PlayerLog("AVAudioPlayer swizzle skipped: %s", sel_getName(original));
}

@implementation AVAudioPlayer (LC32Log)

+ (void)load {
    LC32PlayerSwizzle(@selector(initWithContentsOfURL:error:),
        @selector(lc32log_initWithContentsOfURL:error:));
    LC32PlayerSwizzle(@selector(initWithData:error:),
        @selector(lc32log_initWithData:error:));
    LC32PlayerSwizzle(@selector(play), @selector(lc32log_play));
}

- (instancetype)lc32log_initWithContentsOfURL:(NSURL *)url error:(NSError **)outError {
    AVAudioPlayer *player = [self lc32log_initWithContentsOfURL:url error:outError];
    NSError *error = outError ? *outError : nil;
    LC32PlayerLog("AVAudioPlayer initWithContentsOfURL url=%s player=%s error=%s",
        [[url description] UTF8String] ?: "(nil)", player ? "ok" : "NIL",
        [[error description] UTF8String] ?: "none");
    return player;
}

- (instancetype)lc32log_initWithData:(NSData *)data error:(NSError **)outError {
    AVAudioPlayer *player = [self lc32log_initWithData:data error:outError];
    NSError *error = outError ? *outError : nil;
    LC32PlayerLog("AVAudioPlayer initWithData bytes=%lu player=%s error=%s",
        (unsigned long)[data length], player ? "ok" : "NIL",
        [[error description] UTF8String] ?: "none");
    return player;
}

- (BOOL)lc32log_play {
    const BOOL started = [self lc32log_play];
    LC32PlayerLog("AVAudioPlayer play -> %d isPlaying=%d", (int)started,
        (int)[self isPlaying]);
    return started;
}

@end
