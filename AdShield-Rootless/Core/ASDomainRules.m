#import "ASDomainRules.h"
#include <arpa/inet.h>

@interface ASDomainRules ()
@property (nonatomic) NSUInteger acceptedCount;
@property (nonatomic) NSUInteger skippedCount;
@property (nonatomic, strong) NSMutableArray<NSMutableSet<NSString *> *> *buckets;
@end

@implementation ASDomainRules
- (instancetype)init {
    if ((self = [super init])) {
        _buckets = [NSMutableArray array];
        // block, allow, important block, important allow, exact hosts block
        for (int i = 0; i < 5; i++) [_buckets addObject:[NSMutableSet set]];
    }
    return self;
}
+ (NSString *)domain:(NSString *)value {
    NSString *s = value.lowercaseString;
    if ([s hasSuffix:@"."]) s = [s substringToIndex:s.length - 1];
    if (!s.length || s.length > 253 || ![s containsString:@"."]) return nil;
    struct in_addr ipv4;
    if (inet_pton(AF_INET, s.UTF8String, &ipv4) == 1) return nil;
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789-"] invertedSet];
    for (NSString *label in [s componentsSeparatedByString:@"."]) {
        if (!label.length || label.length > 63 || [label hasPrefix:@"-"] || [label hasSuffix:@"-"] ||
            [label rangeOfCharacterFromSet:invalid].location != NSNotFound) return nil;
    }
    return s;
}
- (void)addText:(NSString *)text {
    [text enumerateLinesUsingBlock:^(NSString *raw, BOOL *stop) {
        (void)stop;
        @autoreleasepool {
            NSString *s = [raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if ([s hasPrefix:@"\uFEFF"]) s = [s substringFromIndex:1];
            if (!s.length || [s hasPrefix:@"!"] || [s hasPrefix:@"#"] || [s hasPrefix:@"["]) return;
            BOOL allow = [s hasPrefix:@"@@"];
            if (allow) s = [s substringFromIndex:2];
            BOOL important = NO;
            NSRange modifier = [s rangeOfString:@"$"];
            if (modifier.location != NSNotFound) {
                if (![[s substringFromIndex:modifier.location + 1] isEqualToString:@"important"]) {
                    self.skippedCount++; return;
                }
                important = YES;
                s = [s substringToIndex:modifier.location];
            }
            NSUInteger bucket = (important ? 2 : 0) + (allow ? 1 : 0);
            if ([s hasPrefix:@"||"]) {
                // Never broaden URL/path/wildcard rules to whole-domain blocks.
                if (![s hasSuffix:@"^"]) { self.skippedCount++; return; }
                s = [s substringWithRange:NSMakeRange(2, s.length - 3)];
            } else {
                NSArray *tokens = [s componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                NSString *first = tokens.firstObject;
                if ([first isEqualToString:@"0.0.0.0"] || [first isEqualToString:@"127.0.0.1"] || [first isEqualToString:@"::"] || [first isEqualToString:@"::1"]) {
                    if (allow || important) { self.skippedCount++; return; }
                    NSString *body = [[s componentsSeparatedByString:@"#"] firstObject];
                    NSArray *parts = [body componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                    BOOL added = NO;
                    for (NSUInteger i = 1; i < parts.count; i++) {
                        if (![parts[i] length]) continue;
                        NSString *d = [ASDomainRules domain:parts[i]];
                        if (d) { [self.buckets[4] addObject:d]; self.acceptedCount++; added = YES; }
                        else self.skippedCount++;
                    }
                    if (!added) self.skippedCount++;
                    return;
                }
                if (allow || important) { self.skippedCount++; return; }
            }
            NSString *domain = [ASDomainRules domain:s];
            if (!domain) { self.skippedCount++; return; }
            [self.buckets[bucket] addObject:domain];
            self.acceptedCount++;
        }
    }];
}
- (BOOL)bucket:(NSUInteger)index matches:(NSString *)host {
    NSString *candidate = host;
    while (candidate.length) {
        if ([self.buckets[index] containsObject:candidate]) return YES;
        NSRange dot = [candidate rangeOfString:@"."];
        if (dot.location == NSNotFound) break;
        candidate = [candidate substringFromIndex:dot.location + 1];
    }
    return NO;
}
- (NSUInteger)blockCount { return self.buckets[0].count + self.buckets[2].count + self.buckets[4].count; }
- (NSUInteger)allowCount { return self.buckets[1].count + self.buckets[3].count; }
- (BOOL)blocksHost:(NSString *)host {
    NSString *s = [ASDomainRules domain:host];
    if (!s) return NO;
    if ([self bucket:3 matches:s]) return NO;
    if ([self bucket:2 matches:s]) return YES;
    if ([self bucket:1 matches:s]) return NO;
    return [self bucket:0 matches:s] || [self.buckets[4] containsObject:s];
}
@end
