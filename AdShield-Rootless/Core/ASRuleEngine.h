#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASRuleEngine : NSObject
+ (instancetype)sharedEngine;
- (BOOL)shouldBlockURL:(NSURL *)url;
- (void)reload;
@property (nonatomic, readonly) NSUInteger blockedDomainCount;
@property (nonatomic, readonly) NSUInteger allowedDomainCount;
@end

NS_ASSUME_NONNULL_END
