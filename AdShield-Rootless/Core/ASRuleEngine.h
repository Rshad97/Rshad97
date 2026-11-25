#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASRuleEngine : NSObject
+ (instancetype)sharedEngine;
- (BOOL)shouldBlockURL:(NSURL *)url;
- (BOOL)shouldBlockHost:(NSString *)host;
- (void)reload;
- (void)reloadWithCompletion:(void (^ _Nullable)(NSArray<NSString *> *unavailableFiles))completion;
@property (nonatomic, readonly) NSUInteger blockedDomainCount;
@property (nonatomic, readonly) NSUInteger allowedDomainCount;
@end

NS_ASSUME_NONNULL_END
