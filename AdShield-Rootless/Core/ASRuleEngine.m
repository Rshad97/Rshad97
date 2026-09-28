#import "ASRuleEngine.h"
#import "ASPreferences.h"
#import "ASDomainRules.h"
#import <rootless.h>

@interface ASRuleEngine ()
@property (nonatomic, strong) ASDomainRules *rules;
@property (nonatomic, strong) dispatch_queue_t loaderQueue;
@end
@implementation ASRuleEngine
+ (instancetype)sharedEngine {
    static ASRuleEngine *engine;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        engine = [ASRuleEngine new];
        engine.loaderQueue = dispatch_queue_create("com.rshad.adshield.rules", DISPATCH_QUEUE_SERIAL);
        engine.rules = [ASDomainRules new];
        // Small seed is ready before the first intercepted request.
        NSString *seed = [NSString stringWithContentsOfFile:ROOT_PATH_NS(@"/Library/Application Support/AdShield/Filters/builtin.txt") encoding:NSUTF8StringEncoding error:nil];
        if (seed) [engine.rules addText:seed];
    });
    return engine;
}
- (NSUInteger)blockedDomainCount { @synchronized(self) { return self.rules.blockCount; } }
- (NSUInteger)allowedDomainCount { @synchronized(self) { return self.rules.allowCount; } }
- (void)reload {
    dispatch_async(self.loaderQueue, ^{
        ASDomainRules *next = [ASDomainRules new];
        NSString *base = ROOT_PATH_NS(@"/Library/Application Support/AdShield/Filters");
        NSMutableArray *paths = [NSMutableArray arrayWithObject:[base stringByAppendingPathComponent:@"builtin.txt"]];
        NSDictionary *prefs = [ASPreferences allPreferences];
        NSArray *sources = @[@[@"useAdGuard", @"adguard_sdns.txt", @YES], @[@"useHaGeZi", @"hagezi_pro_mini.txt", @NO], @[@"useStevenBlack", @"stevenblack_hosts.txt", @NO]];
        for (NSArray *source in sources) {
            if ([(prefs[source[0]] ?: source[2]) boolValue]) [paths addObject:[[base stringByAppendingPathComponent:@"Runtime"] stringByAppendingPathComponent:source[1]]];
        }
        for (NSString *path in paths) {
            NSError *error = nil;
            NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (text) [next addText:text];
            else NSLog(@"[AdShield] FILTER_UNAVAILABLE %@ code=%ld", path.lastPathComponent, (long)error.code);
        }
        @synchronized(self) { self.rules = next; }
        NSLog(@"[AdShield] FILTERS_LOADED accepted=%lu skipped=%lu", (unsigned long)next.acceptedCount, (unsigned long)next.skippedCount);
    });
}
- (BOOL)shouldBlockURL:(NSURL *)url {
    if (![ASPreferences boolForKey:@"enabled" defaultValue:YES] || ![ASPreferences boolForKey:@"networkFiltering" defaultValue:YES]) return NO;
    NSString *host = url.host.lowercaseString;
    if ([host hasSuffix:@"."]) host = [host substringToIndex:host.length - 1];
    for (NSString *safe in @[@"apple.com", @"icloud.com", @"mzstatic.com"]) {
        if ([host isEqualToString:safe] || [host hasSuffix:[@"." stringByAppendingString:safe]]) return NO;
    }
    ASDomainRules *rules;
    @synchronized(self) { rules = self.rules; }
    return [rules blocksHost:host];
}
@end
