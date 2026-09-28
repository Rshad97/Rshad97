#import "ASPreferences.h"
#import <CoreFoundation/CoreFoundation.h>
#import <notify.h>

NSString * const ASPrefsDomain = @"com.rshad.adshieldrootless";
NSString * const ASPrefsPath = @"/var/mobile/Library/Preferences/com.rshad.adshieldrootless.plist";
const char * ASReloadNotification = "com.rshad.adshieldrootless/ReloadPrefs";

@implementation ASPreferences

+ (NSDictionary *)allPreferences {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:ASPrefsPath];
    return [prefs isKindOfClass:NSDictionary.class] ? prefs : @{};
}

+ (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id value = [self allPreferences][key];
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}

+ (void)setBool:(BOOL)value forKey:(NSString *)key {
    NSMutableDictionary *prefs = [[self allPreferences] mutableCopy];
    prefs[key] = @(value);
    [prefs writeToFile:ASPrefsPath atomically:YES];
    CFPreferencesSetAppValue((__bridge CFStringRef)key,
                             (__bridge CFPropertyListRef)@(value),
                             (__bridge CFStringRef)ASPrefsDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)ASPrefsDomain);
    [self postReloadNotification];
}

+ (void)postReloadNotification {
    notify_post(ASReloadNotification);
}

@end
