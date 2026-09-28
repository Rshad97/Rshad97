#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const ASPrefsDomain;
FOUNDATION_EXPORT NSString * const ASPrefsPath;
FOUNDATION_EXPORT const char * ASReloadNotification;

@interface ASPreferences : NSObject
+ (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
+ (void)setBool:(BOOL)value forKey:(NSString *)key;
+ (NSDictionary *)allPreferences;
+ (void)postReloadNotification;
@end

NS_ASSUME_NONNULL_END
