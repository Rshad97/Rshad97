#import <Foundation/Foundation.h>
#import "Core/ASPreferences.h"
#import "Core/ASRuleEngine.h"
#import "Core/ASLogger.h"
#import <notify.h>

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

%hook NSURLSessionTask

- (void)resume {
    NSURLRequest *request = self.currentRequest ?: self.originalRequest;
    NSURL *url = request.URL;

    if (url && [[ASRuleEngine sharedEngine] shouldBlockURL:url]) {
        [ASLogger logBlockedURL:url bundleIdentifier:NSBundle.mainBundle.bundleIdentifier];
        [self cancel];
        return;
    }

    %orig;
}

%end

%ctor {
    @autoreleasepool {
        if (!ASShouldActivateForCurrentProcess()) return;

        static int reloadToken = 0;
        notify_register_dispatch(ASReloadNotification, &reloadToken,
                                 dispatch_get_global_queue(QOS_CLASS_UTILITY, 0),
                                 ^(int token) {
            (void)token;
            [[ASRuleEngine sharedEngine] reload];
        });

        // Prime the rule engine in the background so the first network request\n        // never pays the cost of parsing large filter lists.\n        [[ASRuleEngine sharedEngine] reload];\n\n        %init;\n    }
}
