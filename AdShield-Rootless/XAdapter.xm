// SPDX-License-Identifier: GPL-3.0-or-later
// X timeline interception adapted from the public Twitter No Ads approach.
// Copyright (c) 2020 Hao Nguyen <hao.ict56@gmail.com>
// Copyright (c) 2026 Rashad. Runtime checks and reuse handling added in AdShield.
// See COPYING and THIRD_PARTY.md.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Core/ASPreferences.h"
#import "Core/ASXSupport.h"

@interface TFNItemsDataViewController : NSObject
- (id)itemAtIndexPath:(NSIndexPath *)path;
@end

static char ASHiddenKey;
static BOOL ASXEnabled(void) {
    return [ASPreferences boolForKey:@"enabled" defaultValue:YES] &&
           [ASPreferences boolForKey:@"xPromoted" defaultValue:YES];
}

%group ASXTimeline
%hook TFNItemsDataViewController
- (id)tableViewCellForItem:(id)item atIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = %orig;
    if (![cell isKindOfClass:UITableViewCell.class]) return cell;
    // Restore only visibility changed by AdShield; preserve the app's own state.
    NSNumber *previous = objc_getAssociatedObject(cell, &ASHiddenKey);
    if (previous) {
        cell.hidden = previous.boolValue;
        objc_setAssociatedObject(cell, &ASHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (ASXEnabled() && ASXIsPromoted([self itemAtIndexPath:path])) {
        objc_setAssociatedObject(cell, &ASHiddenKey, @(cell.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        cell.hidden = YES;
        if ([ASPreferences boolForKey:@"logBlocked" defaultValue:NO]) NSLog(@"[AdShield] X_PROMOTED_HIDDEN");
    }
    return cell;
}
- (double)tableView:(id)table heightForRowAtIndexPath:(NSIndexPath *)path {
    if (ASXEnabled() && ASXIsPromoted([self itemAtIndexPath:path])) return 0.0;
    return %orig;
}
%end
%end

%ctor {
    if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.atebits.Tweetie2"]) return;
    Class cls = NSClassFromString(@"TFNItemsDataViewController");
    BOOL compatible = ASXMethodMatches(cls, @selector(itemAtIndexPath:), "@", 3) &&
        ASXMethodMatches(cls, @selector(tableViewCellForItem:atIndexPath:), "@", 4) &&
        ASXMethodMatches(cls, @selector(tableView:heightForRowAtIndexPath:), "d", 4);
    if (compatible) {
        %init(ASXTimeline);
    }
    NSLog(@"[AdShield] X_ADAPTER %@ appVersion=%@", compatible ? @"ACTIVE" : @"UNSUPPORTED_SIGNATURE", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
}
