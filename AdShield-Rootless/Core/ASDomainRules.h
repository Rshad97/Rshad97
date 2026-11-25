#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// A strict hostname-only subset, shared by the downloader and runtime.
@interface ASDomainRules : NSObject
@property (nonatomic, readonly) NSUInteger acceptedCount;
@property (nonatomic, readonly) NSUInteger blockCount;
@property (nonatomic, readonly) NSUInteger allowCount;
@property (nonatomic, readonly) NSUInteger skippedCount;
+ (nullable NSString *)normalizedHost:(nullable NSString *)value;
- (void)addText:(NSString *)text;
- (BOOL)blocksHost:(nullable NSString *)host;
@end

NS_ASSUME_NONNULL_END
