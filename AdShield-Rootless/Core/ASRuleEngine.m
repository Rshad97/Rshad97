#import "ASRuleEngine.h"
#import "ASPreferences.h"
#import <rootless.h>

@interface ASRuleEngine ()
@property (nonatomic, copy) NSSet<NSString *> *blockDomains;
@property (nonatomic, copy) NSSet<NSString *> *allowDomains;
@property (nonatomic) dispatch_queue_t ruleQueue;
@property (nonatomic) BOOL loaded;
@end

@implementation ASRuleEngine

+ (instancetype)sharedEngine {
    static ASRuleEngine *engine;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        engine = [ASRuleEngine new];
        engine.ruleQueue = dispatch_queue_create("com.rshad.adshield.rules", DISPATCH_QUEUE_CONCURRENT);
        engine.blockDomains = [NSSet set];
        engine.allowDomains = [NSSet set];
    });
    return engine;
}

- (NSUInteger)blockedDomainCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ruleQueue, ^{ count = self.blockDomains.count; });
    return count;
}

- (NSUInteger)allowedDomainCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ruleQueue, ^{ count = self.allowDomains.count; });
    return count;
}

- (void)reload {
    dispatch_barrier_sync(self.ruleQueue, ^{
        self.loaded = NO;
        self.blockDomains = [NSSet set];
        self.allowDomains = [NSSet set];
    });
}

- (void)ensureLoaded {
    __block BOOL alreadyLoaded = NO;
    dispatch_sync(self.ruleQueue, ^{ alreadyLoaded = self.loaded; });
    if (alreadyLoaded) return;

    NSMutableSet<NSString *> *blocks = [NSMutableSet set];
    NSMutableSet<NSString *> *allows = [NSMutableSet set];

    NSString *builtin = ROOT_PATH_NS(@"/Library/Application Support/AdShield/Filters/builtin.txt");
    [self parseFileAtPath:builtin blocks:blocks allows:allows];

    if ([ASPreferences boolForKey:@"useAdGuard" defaultValue:YES]) {
        [self parseFileAtPath:@"/var/mobile/Library/Application Support/AdShield/Filters/adguard_sdns.txt"
                       blocks:blocks
                       allows:allows];
    }

    if ([ASPreferences boolForKey:@"useHaGeZi" defaultValue:NO]) {
        [self parseFileAtPath:@"/var/mobile/Library/Application Support/AdShield/Filters/hagezi_pro_mini.txt"
                       blocks:blocks
                       allows:allows];
    }

    if ([ASPreferences boolForKey:@"useStevenBlack" defaultValue:NO]) {
        [self parseFileAtPath:@"/var/mobile/Library/Application Support/AdShield/Filters/stevenblack_hosts.txt"
                       blocks:blocks
                       allows:allows];
    }

    dispatch_barrier_sync(self.ruleQueue, ^{
        if (!self.loaded) {
            self.blockDomains = [blocks copy];
            self.allowDomains = [allows copy];
            self.loaded = YES;
        }
    });
}

- (BOOL)modifierStringIsSafeForPrototype:(NSString *)modifierString {
    if (!modifierString.length) return YES;

    for (NSString *rawModifier in [modifierString componentsSeparatedByString:@","]) {
        NSString *modifier = [rawModifier stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].lowercaseString;
        if (!modifier.length) continue;

        // "important" changes precedence, not hostname matching, so it is safe
        // for this first-stage domain engine. Other modifiers are skipped until
        // their semantics are implemented correctly.
        if ([modifier isEqualToString:@"important"]) continue;
        return NO;
    }
    return YES;
}

- (void)parseFileAtPath:(NSString *)path blocks:(NSMutableSet<NSString *> *)blocks allows:(NSMutableSet<NSString *> *)allows {
    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!content.length) return;

    [content enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        (void)stop;

        @autoreleasepool {
            NSString *trimmed = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (!trimmed.length || [trimmed hasPrefix:@"!"] || [trimmed hasPrefix:@"#"] || [trimmed hasPrefix:@"["]) {
                return;
            }

            BOOL isAllow = [trimmed hasPrefix:@"@@"];
            if (isAllow) trimmed = [trimmed substringFromIndex:2];

            NSRange optionsRange = [trimmed rangeOfString:@"$"];
            if (optionsRange.location != NSNotFound) {
                NSString *modifiers = [trimmed substringFromIndex:optionsRange.location + 1];
                if (![self modifierStringIsSafeForPrototype:modifiers]) {
                    return;
                }
                trimmed = [trimmed substringToIndex:optionsRange.location];
            }

            NSString *domain = nil;

            if ([trimmed hasPrefix:@"||"]) {
                NSString *candidate = [trimmed substringFromIndex:2];
                NSRange end = [candidate rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"^/|"]];
                domain = end.location == NSNotFound ? candidate : [candidate substringToIndex:end.location];
            } else if ([trimmed hasPrefix:@"0.0.0.0 "] || [trimmed hasPrefix:@"127.0.0.1 "]) {
                NSArray<NSString *> *parts = [trimmed componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                for (NSString *part in parts.reverseObjectEnumerator) {
                    if (part.length &&
                        ![part isEqualToString:@"0.0.0.0"] &&
                        ![part isEqualToString:@"127.0.0.1"]) {
                        domain = part;
                        break;
                    }
                }
            } else if ([self looksLikePlainDomain:trimmed]) {
                domain = trimmed;
            }

            domain = [self normalizeDomain:domain];
            if (!domain.length) return;

            if (isAllow) {
                [allows addObject:domain];
            } else {
                [blocks addObject:domain];
            }
        }
    }];
}

- (BOOL)looksLikePlainDomain:(NSString *)value {
    if ([value containsString:@"/"] ||
        [value containsString:@"*"] ||
        [value containsString:@"|"] ||
        [value containsString:@"^"] ||
        [value containsString:@":"]) {
        return NO;
    }
    return [value containsString:@"."] && ![value containsString:@" "];
}

- (NSString *)normalizeDomain:(NSString *)domain {
    if (!domain.length) return nil;

    NSString *normalized = [domain.lowercaseString stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    while ([normalized hasPrefix:@"."]) {
        normalized = [normalized substringFromIndex:1];
    }
    while ([normalized hasSuffix:@"."]) {
        normalized = [normalized substringToIndex:normalized.length - 1];
    }

    if (!normalized.length ||
        ![normalized containsString:@"."] ||
        [normalized containsString:@" "] ||
        [normalized containsString:@"*"] ||
        [normalized containsString:@"/"] ||
        [normalized containsString:@"|"] ||
        [normalized containsString:@"^"] ||
        [normalized containsString:@":"]) {
        return nil;
    }
    return normalized;
}

- (BOOL)set:(NSSet<NSString *> *)set matchesHost:(NSString *)host {
    NSString *candidate = host.lowercaseString;
    while (candidate.length) {
        if ([set containsObject:candidate]) return YES;
        NSRange dot = [candidate rangeOfString:@"."];
        if (dot.location == NSNotFound || dot.location + 1 >= candidate.length) break;
        candidate = [candidate substringFromIndex:dot.location + 1];
    }
    return NO;
}

- (BOOL)isSafetyAllowlistedHost:(NSString *)host {
    static NSSet<NSString *> *criticalDomains;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        criticalDomains = [NSSet setWithArray:@[
            @"apple.com",
            @"icloud.com",
            @"mzstatic.com",
            @"itunes.apple.com"
        ]];
    });
    return [self set:criticalDomains matchesHost:host];
}

- (BOOL)shouldBlockURL:(NSURL *)url {
    if (![ASPreferences boolForKey:@"enabled" defaultValue:YES] ||
        ![ASPreferences boolForKey:@"networkFiltering" defaultValue:YES]) {
        return NO;
    }

    NSString *host = url.host.lowercaseString;
    if (!host.length || [self isSafetyAllowlistedHost:host]) return NO;

    [self ensureLoaded];

    __block BOOL allowed = NO;
    __block BOOL blocked = NO;
    dispatch_sync(self.ruleQueue, ^{
        allowed = [self set:self.allowDomains matchesHost:host];
        if (!allowed) blocked = [self set:self.blockDomains matchesHost:host];
    });

    return !allowed && blocked;
}

@end
