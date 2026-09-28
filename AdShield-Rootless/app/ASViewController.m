#import "ASViewController.h"
#import "../Core/ASPreferences.h"

static NSString * const ASAdGuardURL = @"https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
static NSString * const ASStevenBlackURL = @"https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
static NSString * const ASFilterDirectory = @"/var/mobile/Library/Application Support/AdShield/Filters";

@interface ASViewController ()
@property (nonatomic, strong) UISwitch *masterSwitch;
@property (nonatomic, strong) UISwitch *adguardSwitch;
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

    UIStackView *stack = [[UIStackView alloc] init];
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
    detail.text = @"Rootless ad and tracker filtering prototype";
    detail.textColor = UIColor.secondaryLabelColor;
    detail.textAlignment = NSTextAlignmentCenter;
    detail.numberOfLines = 0;

    [stack addArrangedSubview:icon];
    [stack addArrangedSubview:subtitle];
    [stack addArrangedSubview:detail];

    self.masterSwitch = [UISwitch new];
    self.masterSwitch.on = [ASPreferences boolForKey:@"enabled" defaultValue:YES];
    [self.masterSwitch addTarget:self action:@selector(masterChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:[self rowWithTitle:@"Enable AdShield" control:self.masterSwitch]];

    self.adguardSwitch = [UISwitch new];
    self.adguardSwitch.on = [ASPreferences boolForKey:@"useAdGuard" defaultValue:YES];
    [self.adguardSwitch addTarget:self action:@selector(adguardChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:[self rowWithTitle:@"AdGuard DNS Filter" control:self.adguardSwitch]];

    self.stevenSwitch = [UISwitch new];
    self.stevenSwitch.on = [ASPreferences boolForKey:@"useStevenBlack" defaultValue:NO];
    [self.stevenSwitch addTarget:self action:@selector(stevenChanged:) forControlEvents:UIControlEventValueChanged];
    [stack addArrangedSubview:[self rowWithTitle:@"StevenBlack Hosts" control:self.stevenSwitch]];

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
    self.statusLabel.text = @"Built-in seed rules are active. Tap Update Filter Lists for current upstream rules.";
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

- (UIView *)rowWithTitle:(NSString *)title control:(UIView *)control {
    UIView *row = [UIView new];
    row.backgroundColor = UIColor.secondarySystemBackgroundColor;
    row.layer.cornerRadius = 12;

    UILabel *label = [UILabel new];
    label.text = title;
    label.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    control.translatesAutoresizingMaskIntoConstraints = NO;

    [row addSubview:label];
    [row addSubview:control];
    [NSLayoutConstraint activateConstraints:@[
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:56],
        [label.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
        [label.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [control.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
        [control.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
        [label.trailingAnchor constraintLessThanOrEqualToAnchor:control.leadingAnchor constant:-12]
    ]];
    return row;
}

- (void)masterChanged:(UISwitch *)sender { [ASPreferences setBool:sender.isOn forKey:@"enabled"]; }
- (void)adguardChanged:(UISwitch *)sender { [ASPreferences setBool:sender.isOn forKey:@"useAdGuard"]; }
- (void)stevenChanged:(UISwitch *)sender { [ASPreferences setBool:sender.isOn forKey:@"useStevenBlack"]; }

- (void)updateFilters {
    self.updateButton.enabled = NO;
    self.statusLabel.text = @"Downloading current filter lists…";

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
        [sources addObject:@{@"url": ASAdGuardURL, @"name": @"adguard_sdns.txt"}];
    }
    if (self.stevenSwitch.isOn) {
        [sources addObject:@{@"url": ASStevenBlackURL, @"name": @"stevenblack_hosts.txt"}];
    }

    if (!sources.count) {
        self.statusLabel.text = @"No remote filter source is enabled.";
        self.updateButton.enabled = YES;
        return;
    }

    dispatch_group_t group = dispatch_group_create();
    __block NSUInteger successCount = 0;
    __block NSMutableArray<NSString *> *errors = [NSMutableArray array];

    for (NSDictionary *source in sources) {
        NSURL *url = [NSURL URLWithString:source[@"url"]];
        NSString *name = source[@"name"];
        dispatch_group_enter(group);
        NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
            if (error || !data.length || (http && http.statusCode >= 400)) {
                @synchronized (errors) {
                    [errors addObject:[NSString stringWithFormat:@"%@: %@", name, error.localizedDescription ?: @"HTTP/download error"]];
                }
            } else {
                NSString *path = [ASFilterDirectory stringByAppendingPathComponent:name];
                if ([data writeToFile:path atomically:YES]) {
                    @synchronized (errors) { successCount++; }
                } else {
                    @synchronized (errors) { [errors addObject:[NSString stringWithFormat:@"%@: write failed", name]]; }
                }
            }
            dispatch_group_leave(group);
        }];
        [task resume];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [ASPreferences postReloadNotification];
        self.updateButton.enabled = YES;
        if (errors.count) {
            self.statusLabel.text = [NSString stringWithFormat:@"Updated %lu source(s). %@",
                                     (unsigned long)successCount,
                                     [errors componentsJoinedByString:@" | "]];
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"Updated %lu source(s). New rules will be loaded automatically by enabled apps.",
                                     (unsigned long)successCount];
        }
    });
}

@end
