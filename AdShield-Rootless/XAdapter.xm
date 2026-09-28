// SPDX-License-Identifier: GPL-3.0-or-later
// X timeline interception adapted from the public Twitter No Ads approach.
// Copyright (c) 2020 Hao Nguyen <hao.ict56@gmail.com>
// Copyright (c) 2026 Rashad. Runtime checks and reuse handling added in AdShield.
// See COPYING and THIRD_PARTY.md.
#import <UIKit/UIKit.h>
#import <notify.h>
#import "Core/ASPreferences.h"
#import "Core/ASXSupport.h"
#import "Core/ASXCellGuard.h"

@interface TFNItemsDataViewController : NSObject
- (id)itemAtIndexPath:(NSIndexPath *)path;
@end

static BOOL ASXProtection = YES;
static BOOL ASXEnabled(void) { return ASXProtection; }
static void ASXReload(void) {
    ASXProtection = [ASPreferences boolForKey:@"enabled" defaultValue:YES] &&
        [ASPreferences boolForKey:@"xPromoted" defaultValue:YES];
    ASXRefreshCells();
}

%group ASXTimeline
%hook TFNItemsDataViewController
- (id)tableViewCellForItem:(id)item atIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = %orig;
    if (![cell isKindOfClass:UITableViewCell.class]) return cell;
    // Bind the item being configured, not a potentially moved index path.
    // Unknown models fail open. This also handles reconfiguration without reuse.
    BOOL promoted = ASXIsPromoted(item);
    ASXBindCell(cell, promoted);
    if (promoted && ASXEnabled() && [ASPreferences boolForKey:@"logBlocked" defaultValue:NO]) {
        NSLog(@"[AdShield] X_PROMOTED_HIDDEN stable-row");
    }
    return cell;
}
%end
%end

%ctor {
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.atebits.Tweetie2"]) return;
    Class cls = NSClassFromString(@"TFNItemsDataViewController");
    BOOL compatible = ASXMethodMatches(cls, @selector(tableViewCellForItem:atIndexPath:), "@", 4);
    if (compatible) {
        ASXReload();
        ASXInstallCellGuards(ASXEnabled);
        %init(ASXTimeline);
        static int reloadToken;
        notify_register_dispatch(ASReloadNotification, &reloadToken, dispatch_get_main_queue(), ^(int token) {
            (void)token;
            ASXReload();
        });
    }
    NSLog(@"[AdShield] X_ADAPTER %@ stable-row appVersion=%@", compatible ? @"ACTIVE" : @"UNSUPPORTED_SIGNATURE", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
}
