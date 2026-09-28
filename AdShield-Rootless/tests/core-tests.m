#import <Foundation/Foundation.h>
#import "../Core/ASDomainRules.h"
#import "../Core/ASXSupport.h"
#include <stdlib.h>

static NSUInteger checks;
static void Check(BOOL result, NSString *message) {
    checks++;
    if (!result) { NSLog(@"FAIL %@", message); exit(1); }
}
@interface Promotion : NSObject
@property BOOL isPromoted;
@end
@implementation Promotion
@end
@interface WrongPromotion : NSObject
- (id)isPromoted;
@end
@implementation WrongPromotion
- (id)isPromoted { return @YES; }
@end
@interface ThrowingPromotion : NSObject
- (BOOL)isPromoted;
@end
@implementation ThrowingPromotion
- (BOOL)isPromoted { [NSException raise:@"test" format:@"unsupported runtime"]; return NO; }
@end
@interface CompatibleController : NSObject
- (id)itemAtIndexPath:(id)path;
- (double)tableView:(id)table heightForRowAtIndexPath:(id)path;
@end
@implementation CompatibleController
- (id)itemAtIndexPath:(id)path { return path; }
- (double)tableView:(id)table heightForRowAtIndexPath:(id)path { (void)table; (void)path; return 44; }
@end
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc == 2) {
            NSString *text = [NSString stringWithContentsOfFile:@(argv[1]) encoding:NSUTF8StringEncoding error:nil];
            ASDomainRules *download = [ASDomainRules new];
            [download addText:text];
            Check(download.acceptedCount >= 100, @"upstream list parses");
            NSLog(@"UPSTREAM %@ accepted=%lu skipped=%lu", @(argv[1]), (unsigned long)download.acceptedCount, (unsigned long)download.skippedCount);
            return 0;
        }
        ASDomainRules *rules = [ASDomainRules new];
        [rules addText:@"! comment\n[Adblock Plus 2.0]\n||ads.example^\n@@||ok.ads.example^\n||priority.example^$important\n@@||priority.example^\n@@||exception.priority.example^$important\n0.0.0.0\tfirst.example second.example # note\n:: ipv6.example\nplain.example\n||path.example/ads/\n||path2.example^/ads\n||wild*.example^\n||condition.example^$third-party\n||bad.example^$important,third-party\n||unterminated.example\n||exact.example|\n||other.example^$badfilter\nexample.com##.ad\n0.0.0.0 local.example\n1.2.3.4 redirected.example\n||-bad.example^\n||a..example^\n"]; 
        Check([rules blocksHost:@"ADS.EXAMPLE."], @"case and trailing dot");
        Check([rules blocksHost:@"child.ads.example"], @"subdomains");
        Check(![rules blocksHost:@"notads.example"], @"hostname boundary");
        Check(![rules blocksHost:@"ads.example.evil"], @"suffix boundary");
        Check(![rules blocksHost:@"ok.ads.example"], @"exception");
        Check(![rules blocksHost:@"child.ok.ads.example"], @"exception subdomain");
        Check([rules blocksHost:@"priority.example"], @"important beats ordinary allow");
        Check(![rules blocksHost:@"exception.priority.example"], @"important allow beats important block");
        Check([rules blocksHost:@"first.example"] && [rules blocksHost:@"second.example"], @"hosts tabs aliases comments");
        Check(![rules blocksHost:@"child.first.example"], @"hosts exact match");
        Check([rules blocksHost:@"ipv6.example"], @"IPv6 sink address");
        Check([rules blocksHost:@"sub.plain.example"], @"plain domain suffix");
        for (NSString *host in @[@"path.example", @"path2.example", @"wild1.example", @"condition.example", @"bad.example", @"unterminated.example", @"exact.example", @"other.example", @"example.com", @"redirected.example", @"-bad.example", @"a..example"]) Check(![rules blocksHost:host], [@"reject unsafe rule " stringByAppendingString:host]);
        Check(rules.skippedCount >= 12, @"unsupported rules counted");
        Check(![rules blocksHost:nil], @"nil host");
        Check(![rules blocksHost:@""], @"empty host");
        ASDomainRules *seed = [ASDomainRules new];
        NSString *seedText = [NSString stringWithContentsOfFile:@"layout/Library/Application Support/AdShield/Filters/builtin.txt" encoding:NSUTF8StringEncoding error:nil];
        Check(seedText.length > 0, @"seed exists");
        [seed addText:seedText];
        for (NSString *host in @[@"doubleclick.net", @"adsapi.snapchat.com", @"adserver.shadow.snapads.com", @"ads-bidder-api.twitter.com"]) Check([seed blocksHost:host], [@"seed ad host " stringByAppendingString:host]);
        for (NSString *host in @[@"snapchat.com", @"app.snapchat.com", @"snapchat.com.evil", @"x.com", @"api.twitter.com", @"video.twimg.com"]) Check(![seed blocksHost:host], [@"preserve ordinary host " stringByAppendingString:host]);
        Promotion *item = [Promotion new];
        Check(!ASXIsPromoted(item), @"organic post");
        item.isPromoted = YES;
        Check(ASXIsPromoted(item), @"promoted post");
        Check(!ASXIsPromoted([NSObject new]), @"unknown model");
        Check(!ASXIsPromoted([WrongPromotion new]), @"object BOOL mismatch");
        Check(!ASXIsPromoted([ThrowingPromotion new]), @"throwing model");
        Check(!ASXIsPromoted(nil), @"nil model");
        Check(ASXMethodMatches(CompatibleController.class, @selector(itemAtIndexPath:), "@", 3), @"compatible selector");
        Check(ASXMethodMatches(CompatibleController.class, @selector(tableView:heightForRowAtIndexPath:), "d", 4), @"compatible height");
        Check(!ASXMethodMatches(CompatibleController.class, @selector(itemAtIndexPath:), "B", 3), @"wrong return");
        Check(!ASXMethodMatches(Nil, @selector(itemAtIndexPath:), "@", 3), @"missing controller");
        NSLog(@"PASS %lu core checks", (unsigned long)checks);
    }
    return 0;
}
