#import "ASLogger.h"
#import "ASPreferences.h"

@implementation ASLogger

+ (void)logBlockedURL:(NSURL *)url bundleIdentifier:(NSString *)bundleIdentifier {
    if (![ASPreferences boolForKey:@"logBlocked" defaultValue:NO]) {
        return;
    }
    NSLog(@"[AdShield] BLOCK bundle=%@ url=%@", bundleIdentifier ?: @"unknown", url.absoluteString ?: @"(null)");
}

@end
