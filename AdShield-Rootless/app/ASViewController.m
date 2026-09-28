#import "ASViewController.h"
#import "../Core/ASPreferences.h"
#import "../Core/ASDomainRules.h"
#import <rootless.h>

static NSString * const ASAdGuardURL = @"https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
static NSString * const ASHaGeZiURL = @"https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.mini.txt";
static NSString * const ASStevenBlackURL = @"https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
#define ASFilterDirectory ROOT_PATH_NS(@"/Library/Application Support/AdShield/Filters/Runtime")

@interface ASViewController ()
@property (nonatomic, strong) UISwitch *masterSwitch;
@property (nonatomic, strong) UISwitch *networkSwitch;
@property (nonatomic, strong) UISwitch *xSwitch;
@property (nonatomic, strong) UISwitch *adguardSwitch;
@property (nonatomic, strong) UISwitch *hageziSwitch;
@property (nonatomic, strong) UISwitch *stevenSwitch;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *updateButton;
@end

@implementation ASViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AdShield";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Icon-60"]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.layer.cornerRadius = 28;
    icon.clipsToBounds = YES;
    [icon.heightAnchor constraintEqualToConstant:120].active = YES;

    UILabel *subtitle = [UILabel new];
    subtitle.text = @"AdShield-Rootless v1.1.0";
    subtitle.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    subtitle.textAlignment = NSTextAlignmentCenter;

    UILabel *detail = [UILabel new];
    detail.text = @"Domain protection + experimental X promoted-post adapter";
    detail.textColor = UIColor.secondaryLabelColor;
    detail.textAlignment = NSTextAlignmentCenter;
    detail.numberOfLines = 0;

    [stack addArrangedSubview:icon];
    [stack addArrangedSubview:subtitle];
    [stack addArrangedSubview:detail];

    [stack addArrangedSubview:[self sectionLabel:@"Protection"]];

    self.masterSwitch = [UISwitch new];
    self.masterSwitch.on = [ASPreferences boolForKey:@"enabled" defaultValue:YES];
    [self.masterSwitch addTarget:self action:@selector(masterChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:[self rowWithTitle:@"Enable AdShield" subtitle:@"Master switch" control:self.masterSwitch]];

    self.networkSwitch = [UISwitch new];
    self.networkSwitch.on = [ASPreferences boolForKey:@"networkFiltering" defaultValue:YES];
    [self.networkSwitch addTarget:self action:@selector(networkChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:[self rowWithTitle:@"Network Filtering" subtitle:@"Block matching NSURLSession requests" control:self.networkSwitch]];

    self.xSwitch = [UISwitch new];
    self.xSwitch.on = [ASPreferences boolForKey:@"xPromoted" defaultValue:YES];
    [self.xSwitch addTarget:self action:@selector(xChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:[self rowWithTitle:@"X Promoted Posts" subtitle:@"Experimental • requires compatible app methods; reopen X after installation" control:self.xSwitch]];
    UILabel *coverage = [UILabel new];
    coverage.text = @"Snapchat: partial ad-domain coverage only. Story, Spotlight and chat ads are not guaranteed blocked. Other apps: domain filtering where NSURLSession is used. No blanket blocking of social-media domains.";
    coverage.numberOfLines = 0;
    coverage.font = [UIFont systemFontOfSize:13];
    coverage.textColor = UIColor.secondaryLabelColor;
    [stack addArrangedSubview:coverage];
    [stack addArrangedSubview:[self sectionLabel:@"Filter Sources"]];

    self.adguardSwitch = [UISwitch new];
    self.adguardSwitch.on = [ASPreferences boolForKey:@"useAdGuard" defaultValue:YES];
    [self.adguardSwitch addTarget:self action:@selector(adguardChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:[self rowWithTitle:@"AdGuard DNS Filter" subtitle:@"Default • broad ad/tracker coverage" control:self.adguardSwitch]];

    self.hageziSwitch = [UISwitch new];
    self.hageziSwitch.on = [ASPreferences boolForKey:@"useHaGeZi" defaultValue:NO];
    [self.hageziSwitch addTarget:self action:@selector(hageziChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:[self rowWithTitle:@"HaGeZi Pro Mini" subtitle:@"Optional • mobile-size optimized list" control:self.hageziSwitch]];

    self.stevenSwitch = [UISwitch new];
    self.stevenSwitch.on = [ASPreferences boolForKey:@"useStevenBlack" defaultValue:NO];
    [self.stevenSwitch addTarget:self action:@selector(stevenChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:[self rowWithTitle:@"StevenBlack Hosts" subtitle:@"Optional • hosts-format aggregate" control:self.stevenSwitch]];

    UILabel *sourceNote = [UILabel new];
    sourceNote.text = @"For lower per-app memory usage, keep AdGuard as the primary source and enable extra lists only if you need them.";
    sourceNote.textColor = UIColor.secondaryLabelColor;
    sourceNote.font = [UIFont systemFontOfSize:13];
    sourceNote.numberOfLines = 0;
    [stack addArrangedSubview:sourceNote];

    self.updateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.updateButton setTitle:@"Update Filter Lists" forState:UIControlStateNormal];
    self.updateButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.updateButton.backgroundColor = UIColor.systemBlueColor;
    [self.updateButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.updateButton.layer.cornerRadius = 12;
    [self.updateButton.heightAnchor constraintEqualToConstant:52.0].active = YES;
    [self.updateButton addTarget:self action:@selector(updateFilters) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:self.updateButton];

    self.statusLabel = [UILabel new];
    self.statusLabel.text = [NSUserDefaults.standardUserDefaults stringForKey:@"lastFilterResult"] ?: @"Seed rules available. Missing enabled lists will download now.";
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    self.statusLabel.numberOfLines = 0;
    [stack addArrangedSubview:self.statusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:20],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40]
    ]];
    // First launch and newly enabled missing subscriptions do not silently use seeds only.
    [self downloadMissingFilters];
}

- (void)downloadMissingFilters {
    NSArray *sources = @[@[@"useAdGuard", @"adguard_sdns.txt", @YES], @[@"useHaGeZi", @"hagezi_pro_mini.txt", @NO], @[@"useStevenBlack", @"stevenblack_hosts.txt", @NO]];
    for (NSArray *source in sources) {
        if ([ASPreferences boolForKey:source[0] defaultValue:[source[2] boolValue]] &&
            ![NSFileManager.defaultManager fileExistsAtPath:[ASFilterDirectory stringByAppendingPathComponent:source[1]]]) {
            [self updateFilters];
            break;
        }
    }
}
- (void)xChanged:(UISwitch *)sender { [ASPreferences setBool:sender.isOn forKey:@"xPromoted"]; }

- (UILabel *)sectionLabel:(NSString *)title {
    UILabel *label = [UILabel new];
    label.text = title.uppercaseString;
    label.textColor = UIColor.secondaryLabelColor;
    label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    return label;
}

- (UIView *)rowWithTitle:(NSString *)title subtitle:(NSString *)subtitle control:(UIView *)control {
    UIView *row = [UIView new];
    row.backgroundColor = UIColor.secondarySystemBackgroundColor;
    row.layer.cornerRadius = 12;

    UILabel *titleLabel = [UILabel new];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];

    UILabel *subtitleLabel = [UILabel new];
    subtitleLabel.text = subtitle;
    subtitleLabel.font = [UIFont systemFontOfSize:12];
    subtitleLabel.textColor = UIColor.secondaryLabelColor;
    subtitleLabel.numberOfLines = 0;

    UIStackView *labels = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, subtitleLabel]];
    labels.axis = UILayoutConstraintAxisVertical;
    labels.spacing = 2;
    labels.translatesAutoresizingMaskIntoConstraints = NO;
    control.translatesAutoresizingMaskIntoConstraints = NO;

    [row addSubview:labels];
    [row addSubview:control];

    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:64],
        [labels.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
        [labels.topAnchor constraintGreaterThanOrEqualToAnchor:row.topAnchor constant:10],
        [labels.bottomAnchor constraintLessThanOrEqualToAnchor:row.bottomAnchor constant:-10],
        [labels.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [control.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
        [control.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [labels.trailingAnchor constraintLessThanOrEqualToAnchor:control.leadingAnchor constant:-12]
    ]];
    return row;
}

- (void)masterChanged:(UISwitch *)sender {
    [ASPreferences setBool:sender.isOn forKey:@"enabled"];
}

- (void)networkChanged:(UISwitch *)sender {
    [ASPreferences setBool:sender.isOn forKey:@"networkFiltering"];
}

- (void)adguardChanged:(UISwitch *)sender {
    [ASPreferences setBool:sender.isOn forKey:@"useAdGuard"];
    if (sender.isOn) [self downloadMissingFilters];
}

- (void)hageziChanged:(UISwitch *)sender {
    [ASPreferences setBool:sender.isOn forKey:@"useHaGeZi"];
    if (sender.isOn) [self downloadMissingFilters];
}

- (void)stevenChanged:(UISwitch *)sender {
    [ASPreferences setBool:sender.isOn forKey:@"useStevenBlack"];
    if (sender.isOn) [self downloadMissingFilters];
}

- (void)updateFilters {
    if (!self.updateButton.enabled) return;
    self.updateButton.enabled = NO;
    self.adguardSwitch.enabled = self.hageziSwitch.enabled = self.stevenSwitch.enabled = NO;
    self.statusLabel.text = @"Downloading enabled filter lists…";

    NSError *dirError = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:ASFilterDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&dirError];
    if (dirError) {
        self.statusLabel.text = [NSString stringWithFormat:@"Could not create filter directory: %@", dirError.localizedDescription];
        self.updateButton.enabled = YES;
        self.adguardSwitch.enabled = self.hageziSwitch.enabled = self.stevenSwitch.enabled = YES;
        return;
    }

    NSMutableArray<NSDictionary *> *sources = [NSMutableArray array];
    if (self.adguardSwitch.isOn) {
        [sources addObject:@{@"url": ASAdGuardURL, @"name": @"adguard_sdns.txt", @"label": @"AdGuard"}];
    }
    if (self.hageziSwitch.isOn) {
        [sources addObject:@{@"url": ASHaGeZiURL, @"name": @"hagezi_pro_mini.txt", @"label": @"HaGeZi"}];
    }
    if (self.stevenSwitch.isOn) {
        [sources addObject:@{@"url": ASStevenBlackURL, @"name": @"stevenblack_hosts.txt", @"label": @"StevenBlack"}];
    }

    if (!sources.count) {
        self.statusLabel.text = @"No remote filter source is enabled. Built-in seed rules remain available.";
        self.updateButton.enabled = YES;
        self.adguardSwitch.enabled = self.hageziSwitch.enabled = self.stevenSwitch.enabled = YES;
        return;
    }

    NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    configuration.timeoutIntervalForRequest = 45.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

    dispatch_group_t group = dispatch_group_create();
    __block NSUInteger successCount = 0;
    NSMutableArray<NSString *> *errors = [NSMutableArray array];
    NSMutableArray<NSString *> *summaries = [NSMutableArray array];

    for (NSDictionary *source in sources) {
        NSURL *url = [NSURL URLWithString:source[@"url"]];
        NSString *name = source[@"name"];
        NSString *label = source[@"label"];
        dispatch_group_enter(group);

        NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
            NSString *text = data.length > 0 && data.length <= 16 * 1024 * 1024 ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
            ASDomainRules *validation = [ASDomainRules new];
            if (text) [validation addText:text];
            BOOL valid = !error && http.statusCode == 200 && text.length &&
                validation.acceptedCount >= 100 && [text rangeOfString:@"<html" options:NSCaseInsensitiveSearch].location == NSNotFound;
            NSString *failure = nil;
            if (!valid) {
                failure = error.localizedDescription ?: [NSString stringWithFormat:@"invalid list (HTTP %ld, accepted %lu); previous file preserved", (long)http.statusCode, (unsigned long)validation.acceptedCount];
            } else {
                NSError *writeError = nil;
                NSString *path = [ASFilterDirectory stringByAppendingPathComponent:name];
                // Atomic replacement preserves the previous list on write failure.
                if (![data writeToFile:path options:NSDataWritingAtomic error:&writeError]) {
                    failure = writeError.localizedDescription ?: @"write failed; previous file preserved";
                }
            }
            @synchronized (errors) {
                if (failure) [errors addObject:[NSString stringWithFormat:@"%@: %@", label, failure]];
                else {
                    successCount++;
                    [summaries addObject:[NSString stringWithFormat:@"%@: %lu accepted / %lu skipped", label, (unsigned long)validation.acceptedCount, (unsigned long)validation.skippedCount]];
                }
            }
            dispatch_group_leave(group);
        }];
        [task resume];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [session finishTasksAndInvalidate];
        [ASPreferences postReloadNotification];
        self.updateButton.enabled = YES;
        self.adguardSwitch.enabled = self.hageziSwitch.enabled = self.stevenSwitch.enabled = YES;

        if (errors.count) {
            self.statusLabel.text = [NSString stringWithFormat:@"Updated %lu source(s). %@",
                                     (unsigned long)successCount,
                                     [errors componentsJoinedByString:@" | "]];
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"Updated %lu source(s). Running apps received a rule-reload signal.",
                                     (unsigned long)successCount];
        }
        self.statusLabel.text = [self.statusLabel.text stringByAppendingFormat:@"\n%@\nLast update attempt: %@. Counts describe parsed files, not ads blocked.", [summaries componentsJoinedByString:@"\n"], [NSDate date]];
        [NSUserDefaults.standardUserDefaults setObject:self.statusLabel.text forKey:@"lastFilterResult"];
    });
}

@end

