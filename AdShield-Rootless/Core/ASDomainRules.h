#import <Foundation/Foundation.h>

// A strict hostname-only subset, shared by the downloader and runtime.
@interface ASDomainRules : NSObject
@property (nonatomic, readonly) NSUInteger acceptedCount;
@property (nonatomic, readonly) NSUInteger blockCount;
@property (nonatomic, readonly) NSUInteger allowCount;
@property (nonatomic, readonly) NSUInteger skippedCount;
- (void)addText:(NSString *)text;
- (BOOL)blocksHost:(NSString *)host;
@end
