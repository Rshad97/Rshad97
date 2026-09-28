#import <Foundation/Foundation.h>
#import "Core/ASPreferences.h"
#import "Core/ASRuleEngine.h"
#import "Core/ASLogger.h"
#import <notify.h>
#import <objc/runtime.h>
#include <stdlib.h>
#include <string.h>
@interface ASLocalTask : NSURLSessionTask
@end

static BOOL ASShouldActivateForCurrentProcess(void) {
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *bundleID = bundle.bundleIdentifier.lowercaseString;
    if (!bundleID.length) return NO;

    if ([bundle.bundlePath.pathExtension.lowercaseString isEqualToString:@"appex"]) {
        return NO;
    }

    NSArray<NSString *> *blockedPrefixes = @[
        @"com.apple.",
        @"org.coolstar.sileostore",
        @"com.saurik.cydia",
        @"com.opa334.dopamine",
        @"com.rshad.adshieldapp"
    ];

    for (NSString *prefix in blockedPrefixes) {
        if ([bundleID hasPrefix:prefix]) return NO;
    }

    // Always install the lightweight hook in eligible third-party apps.
    // The master switch is checked per request so toggling AdShield does not
    // require the app to be relaunched.
    return YES;
}

static void ASFilterTask(NSURLSessionTask *task) {
    if (task.state == NSURLSessionTaskStateCanceling || task.state == NSURLSessionTaskStateCompleted) return;
    NSURL *url = (task.currentRequest ?: task.originalRequest).URL;
    if (url && [[ASRuleEngine sharedEngine] shouldBlockURL:url]) {
        [ASLogger logBlockedURL:url bundleIdentifier:NSBundle.mainBundle.bundleIdentifier];
        [task cancel];
    }
}

%hook NSURLSessionTask
- (void)resume {
    ASFilterTask(self);
    // Resume cancelled tasks as well so the ordinary cancellation callback runs.
    %orig;
}
%end

%group ASConcreteTask
%hook ASLocalTask
- (void)resume {
    ASFilterTask((NSURLSessionTask *)self);
    %orig;
}
%end
%end

static BOOL ASOwnsResume(Class cls) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    BOOL found = NO;
    for (unsigned int i = 0; i < count; i++) {
        if (method_getName(methods[i]) == @selector(resume) && method_getNumberOfArguments(methods[i]) == 2) {
            char *returnType = method_copyReturnType(methods[i]);
            found = returnType && strcmp(returnType, "v") == 0;
            free(returnType);
            break;
        }
    }
    free(methods);
    return found;
}

%ctor {
    if (!ASShouldActivateForCurrentProcess()) {
        return;
    }

    static int reloadToken = 0;
    notify_register_dispatch(ASReloadNotification, &reloadToken,
                             dispatch_get_global_queue(QOS_CLASS_UTILITY, 0),
                             ^(int token) {
        (void)token;
        [[ASRuleEngine sharedEngine] reload];
    });

    [[ASRuleEngine sharedEngine] reload];
    %init;
    Class concrete = NSClassFromString(@"__NSCFLocalSessionTask");
    if (concrete && [concrete isSubclassOfClass:NSURLSessionTask.class] && ASOwnsResume(concrete)) {
        %init(ASConcreteTask, ASLocalTask=concrete);
    }
    NSLog(@"[AdShield] NETWORK_HOOK_ACTIVE bundle=%@ appVersion=%@", NSBundle.mainBundle.bundleIdentifier, [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
}

