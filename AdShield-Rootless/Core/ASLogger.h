#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface ASLogger : NSObject
+ (void)logBlockedURL:(NSURL *)url bundleIdentifier:(nullable NSString *)bundleIdentifier;
@end
NS_ASSUME_NONNULL_END
