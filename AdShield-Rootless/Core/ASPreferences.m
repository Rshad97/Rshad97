#import "ASPreferences.h"
#import <CoreFoundation/CoreFoundation.h>
#import <notify.h>

NSString * const ASPrefsDomain = @"com.rshad.adshieldrootless";
NSString * const ASPrefsPath = @"/var/mobile/Library/Preferences/com.rshad.adshieldrootless.plist";
const char * ASReloadNotification = "com.rshad.adshieldrootless/ReloadPrefs";

@implementation ASPreferences

+ (NSDictionary *)allPreferences {
    NSDictionary *filePrefs = [NSDictionary dictionaryWithContentsOfFile:ASPrefsPath];
    if ([filePrefs isKindOfClass:NSDictionary.class] && filePrefs.count > 0) {
        return filePrefs;
    }

    CFPreferencesAppSynchronize((__bridge CFStringRef)ASPrefsDomain);
    CFDictionaryRef copied = CFPreferencesCopyMultiple(NULL,
                                                       (__bridge CFStringRef)ASPrefsDomain,
                                                       kCFPreferencesCurrentUser,
                                                       kCFPreferencesAnyHost);
    NSDictionary *cfPrefs = CFBridgingRelease(copied);
    return [cfPrefs isKindOfClass:NSDictionary.class] ? cfPrefs : @{};
}

+ (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id value = [self allPreferences][key];
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}

+ (void)setBool:(BOOL)value forKey:(NSString *)key {
    NSMutableDictionary *prefs = [[self allPreferences] mutableCopy];
    if (!prefs) prefs = [NSMutableDictionary dictionary];
    prefs[key] = @(value);
    [prefs writeToFile:ASPrefsPath atomically:YES];

    CFPreferencesSetAppValue((__bridge CFStringRef)key,
                             value ? kCFBooleanTrue : kCFBooleanFalse,
                             (__bridge CFStringRef)ASPrefsDomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)ASPrefsDomain);
    [self postReloadNotification];
}

+ (void)postReloadNotification {
    notify_post(ASReloadNotification);
}

@end
