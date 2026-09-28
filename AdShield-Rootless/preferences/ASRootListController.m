#import "ASRootListController.h"
#import "../Core/ASPreferences.h"
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <unistd.h>

@implementation ASRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = specifier.properties[@"key"];
    id defaultValue = specifier.properties[@"default"];
    id value = [ASPreferences allPreferences][key];
    return value ?: defaultValue;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = specifier.properties[@"key"];
    if (!key.length) return;

    NSMutableDictionary *prefs = [[ASPreferences allPreferences] mutableCopy];
    prefs[key] = value ?: @NO;
    [prefs writeToFile:ASPrefsPath atomically:YES];
    [ASPreferences postReloadNotification];
}

- (void)openApp {
    NSURL *url = [NSURL URLWithString:@"adshield://open"];
    UIApplication *app = UIApplication.sharedApplication;
    if ([app respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        [app openURL:url options:@{} completionHandler:nil];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [app openURL:url];
#pragma clang diagnostic pop
    }
}

- (void)respring {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Restart SpringBoard"
                                                                   message:@"Apply current AdShield settings now?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Restart" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        pid_t pid = fork();
        if (pid == 0) {
            execl("/var/jb/usr/bin/sbreload", "sbreload", NULL);
            execl("/usr/bin/sbreload", "sbreload", NULL);
            _exit(0);
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
