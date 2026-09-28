#import "ASViewController.h"
#import "../Core/ASPreferences.h"

static NSString * const ASAdGuardURL = @"https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
static NSString * const ASHaGeZiURL = @"https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.mini.txt";
static NSString * const ASStevenBlackURL = @"https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
static NSString * const ASFilterDirectory = @"/var/jb/Library/Application Support/AdShield/Filters/Runtime";

@interface ASViewController ()
@property (nonatomic, strong) UISwitch *masterSwitch;
@property (nonatomic, strong) UISwitch *networkSwitch;
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
    subtitle.text = @"AdShield-Rootless v1.0.0";
    subtitle.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    subtitle.textAlignment = NSTextAlignmentCenter;

    UILabel *detail = [UILabel new];
    detail.text = @"System-wide domain filtering prototype for third-party apps";
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
    self.statusLabel.text = @"Built-in seed rules are active. Tap Update Filter Lists to download current upstream rules.";
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
}

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
}

- (void)hageziChanged:(UISwitch *)sender {
    [ASPreferences setBool:sender.isOn forKey:@"useHaGeZi"];
}

- (void)stevenChanged:(UISwitch *)sender {
    [ASPreferences setBool:sender.isOn forKey:@"useStevenBlack"];
}

- (void)updateFilters {
    self.updateButton.enabled = NO;
    self.statusLabel.text = @"Downloading enabled filter lists…";

    NSError *dirError = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:ASFilterDirectory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&dirError];
    if (dirError) {
        self.statusLabel.text = [NSString stringWithFormat:@"Could not create filter directory: %@", dirError.localizedDescription];
        self.updateButton.enabled = YES;
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
        return;
    }

    NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    configuration.timeoutIntervalForRequest = 45.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

    dispatch_group_t group = dispatch_group_create();
    __block NSUInteger successCount = 0;
    NSMutableArray<NSString *> *errors = [NSMutableArray array];

    for (NSDictionary *source in sources) {
        NSURL *url = [NSURL URLWithString:source[@"url"]];
        NSString *name = source[@"name"];
        NSString *label = source[@"label"];
        dispatch_group_enter(group);

        NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
            BOOL validHTTP = !http || (http.statusCode >= 200 && http.statusCode < 300);

            if (error || !validHTTP || data.length < 128) {
                @synchronized (errors) {
                    NSString *reason = error.localizedDescription ?: [NSString stringWithFormat:@"HTTP %ld", (long)http.statusCode];
                    [errors addObject:[NSString stringWithFormat:@"%@: %@", label, reason]];
                }
            } else {
                NSString *path = [ASFilterDirectory stringByAppendingPathComponent:name];
                NSString *tempPath = [path stringByAppendingString:@".tmp"];

                if ([data writeToFile:tempPath atomically:YES]) {
                    NSFileManager *fm = NSFileManager.defaultManager;
                    [fm removeItemAtPath:path error:nil];
                    NSError *moveError = nil;
                    if ([fm moveItemAtPath:tempPath toPath:path error:&moveError]) {
                        @synchronized (errors) { successCount++; }
                    } else {
                        @synchronized (errors) {
                            [errors addObject:[NSString stringWithFormat:@"%@: %@", label, moveError.localizedDescription ?: @"move failed"]];
                        }
                    }
                } else {
                    @synchronized (errors) {
                        [errors addObject:[NSString stringWithFormat:@"%@: write failed", label]];
                    }
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

        if (errors.count) {
            self.statusLabel.text = [NSString stringWithFormat:@"Updated %lu source(s). %@",
                                     (unsigned long)successCount,
                                     [errors componentsJoinedByString:@" | "]];
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"Updated %lu source(s). Running apps received a rule-reload signal.",
                                     (unsigned long)successCount];
        }
    });
}

@end
