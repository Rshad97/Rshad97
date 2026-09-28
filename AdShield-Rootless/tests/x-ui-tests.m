#import <UIKit/UIKit.h>
#import "../Core/ASXCellGuard.h"
#include <stdlib.h>

static BOOL protection = YES;
static BOOL Enabled(void) { return protection; }
static NSUInteger checks;
static void Finish(BOOL pass, NSString *message) {
    NSDictionary *result = @{@"passed": @(pass), @"checks": @(checks), @"message": message};
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/result.json"];
    [data writeToFile:path atomically:YES];
    NSLog(@"ADSHIELD_UI_RESULT %@", result);
    exit(pass ? 0 : 1);
}
static void Check(BOOL value, NSString *message) {
    checks++;
    if (!value) Finish(NO, message);
}
@interface App : UIResponder <UIApplicationDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UITableView *table;
@end
@implementation App
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    (void)table; (void)section; return 3;
}
- (CGFloat)tableView:(UITableView *)table heightForRowAtIndexPath:(NSIndexPath *)path {
    (void)table; return path.row == 1 ? 170 : 90;
}
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    (void)table;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fixture"];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, 260, 32)];
    label.text = path.row == 1 ? @"Promoted fixture" : @"Organic fixture";
    [cell.contentView addSubview:label];
    return cell;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)application; (void)options;
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    UIViewController *controller = [UIViewController new];
    self.window.rootViewController = controller;
    self.table = [[UITableView alloc] initWithFrame:self.window.bounds style:UITableViewStylePlain];
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.estimatedRowHeight = 0;
    [controller.view addSubview:self.table];
    [self.window makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self runChecks]; });
    return YES;
}
- (void)runChecks {
    // Reproduce the old one-shot hiding failure before installing the actual guard.
    UITableViewCell *legacy = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:@"legacy"];
    legacy.hidden = YES;
    legacy.hidden = NO; // UIKit/X reveals the row after the adapter's factory returned.
    Check(!legacy.hidden, @"legacy one-shot hiding reproduction");

    [self.table layoutIfNeeded];
    CGRect before[3];
    for (NSInteger i = 0; i < 3; i++) before[i] = [self.table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    ASXInstallCellGuards(Enabled);
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:@"test"];
    ASXBindCell(cell, YES);
    Check(cell.hidden, @"ad initially hidden");
    cell.hidden = NO;
    Check(cell.hidden, @"late unhide cannot reveal promoted cell");
    [cell setNeedsLayout]; [cell layoutIfNeeded];
    Check(cell.hidden, @"layout preserves hiding");
    ASXBindCell(cell, NO);
    Check(!cell.hidden, @"reconfigure as organic without prepareForReuse");
    cell.hidden = YES;
    ASXBindCell(cell, YES);
    ASXBindCell(cell, NO);
    Check(cell.hidden, @"preserve app-owned hidden state");
    cell.hidden = NO;
    ASXBindCell(cell, YES);
    [cell prepareForReuse];
    cell.hidden = NO;
    Check(!cell.hidden, @"reuse clears old promoted binding");
    ASXBindCell(cell, YES);
    protection = NO; ASXRefreshCells();
    Check(!cell.hidden, @"disable restores app-requested visibility immediately");
    protection = YES; ASXRefreshCells();
    Check(cell.hidden, @"enable hides bound promoted cell immediately");
    protection = NO; ASXRefreshCells();
    cell.hidden = YES;
    protection = YES; ASXRefreshCells();
    protection = NO; ASXRefreshCells();
    Check(cell.hidden, @"toggle preserves newer app-owned hidden request");
    protection = YES;
    ASXBindCell(cell, NO); cell.hidden = NO;
    // Repeated layout/reuse/reconfiguration with actual UIKit objects.
    for (NSUInteger i = 0; i < 300; i++) {
        ASXBindCell(cell, YES);
        cell.hidden = NO;
        Check(cell.hidden, @"scroll cycle ad stays hidden");
        ASXBindCell(cell, NO);
        Check(!cell.hidden, @"scroll cycle organic is visible");
        ASXBindCell(cell, YES);
        [cell prepareForReuse];
        cell.hidden = NO;
        Check(!cell.hidden, @"scroll cycle reused cell is visible");
    }
    UIView *unrelated = [UIView new];
    unrelated.hidden = YES; unrelated.hidden = NO;
    Check(!unrelated.hidden, @"UIView outside cells unaffected");
    UITableViewCell *organic = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:@"organic"];
    organic.hidden = YES; organic.hidden = NO;
    Check(!organic.hidden, @"unbound cells unaffected");

    NSIndexPath *adPath = [NSIndexPath indexPathForRow:1 inSection:0];
    UITableViewCell *ad = [self.table cellForRowAtIndexPath:adPath];
    Check(ad != nil, @"real table fixture has an ad cell");
    ASXBindCell(ad, YES);
    [self.table layoutIfNeeded];
    for (NSInteger i = 0; i < 3; i++) {
        CGRect after = [self.table rectForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        Check(CGRectEqualToRect(before[i], after), @"row geometry unchanged");
    }
    Check(before[1].size.height == 170, @"native ad height retained instead of zero");
    Check(!CGRectIntersectsRect(before[0], before[1]) && !CGRectIntersectsRect(before[1], before[2]), @"neighboring row frames do not overlap");
    Check(ad.hidden, @"real table ad hidden");
    __weak UITableViewCell *weakCell;
    @autoreleasepool {
        UITableViewCell *temporary = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:nil];
        weakCell = temporary;
        ASXBindCell(temporary, YES);
    }
    Check(weakCell == nil, @"tracking does not retain dead cells");

    // Delayed callbacks from a configured ad must not make it visible again.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        ad.hidden = NO;
        [ad setNeedsLayout]; [ad layoutIfNeeded];
        Check(ad.hidden, @"async reveal attempt suppressed");
        ASXBindCell(ad, NO);
        Check(!ad.hidden, @"async scenario reconfigured as organic");
        Finish(YES, @"UIKit lifecycle, 300 reuse cycles and table geometry passed");
    });
}
@end
int main(int argc, char *argv[]) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(App.class)); }
}
