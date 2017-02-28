//
//  BuoyScreenViewController.m
//  FMSiOS
//
//  Created by Sean M on 3/09/2015.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import "BuoyScreen.h"

// View in the centre when clicking more info
@interface MoreInfoDialog : UIView

@property (weak, nonatomic) Buoy *buoy;

@property (strong, nonatomic) UILabel *content;
@property (strong, nonatomic) UIActivityIndicatorView *contentInd;
@property (strong, nonatomic) UIButton *pingButton;
@property (strong, nonatomic) UIActivityIndicatorView *pingInd;
@property (strong, nonatomic) UILabel *pingDetail;
@property (strong, nonatomic) UIButton *cancelButton;

- (void)displayBuoyInfo:(NSDictionary *)info;
- (void)displayBuoyLoadingFailed;

- (void)hidePingButton;

- (void)startPinging;
- (void)finishPingingSuccessWithTime:(NSNumber *)seconds;
- (void)finishPingingTimeout;
- (void)finishPingingServerError;

@end

// Main buoy screen
@interface BuoyScreen () <UIPopoverPresentationControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate>

// Core UI elements
@property (strong, nonatomic) MKMapView *map;
@property (strong, nonatomic) CLLocationManager *l;
@property (strong, nonatomic) UIBarButtonItem *pButton; //info popup
@property (strong, nonatomic) UIBarButtonItem *rButton; //refresh button
@property (strong, nonatomic) UIActivityIndicatorView *rInd;
@property (strong, nonatomic) UIBarButtonItem *rIndButton;
@property (strong, nonatomic) UIViewController *popup;

// Hidden elements
@property (strong, nonatomic) UIButton *moreInfoDialogContainer; //More info dialog is in the content view for this
@property (strong, nonatomic) MoreInfoDialog *moreInfoDialog;

// Data structures
@property (strong, nonatomic) NSArray *allBuoys; // List of all buoys to display
@property (strong, nonatomic) NSArray *unlistedBuoys; // All buoys to not display
@property (strong, nonatomic) NSArray *buoyGroups; // List of buoy groups, containing the above two arrays
@property (strong, nonatomic) NSMutableIndexSet *buoyGroupsToShow; // Buoys not to show, or show all if this is set to nil

- (void)mapTypeButtonPressed:(UIControl *)c;
- (void)updateMapToMatchSelection;
- (void)moreInfoOpenedForBuoy:(Buoy *)b;

@end

// Popup controller used for the info button options settings
@interface BuoySettingsPopup : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *t;
@property (weak, nonatomic) BuoyScreen *delegate;

- (void)forceUpdate;

@end


@implementation MoreInfoDialog

- (instancetype)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, 310, 10);
        self.backgroundColor = [FMS_COLOUR_BG_SHADE colorWithAlphaComponent:0.95];
        self.layer.cornerRadius = 10;
        self.tintColor = FMS_COLOUR_TEXT_BUTTON;
        self.clipsToBounds = YES;
        
        _buoy = nil;
        
        // Labels
        _content = [[UILabel alloc] init];
        _content.numberOfLines = 0;
        _content.attributedText = [[NSAttributedString alloc] initWithString:@" "];
        _content.font = [UIFont systemFontOfSize:17];
        _content.lineBreakMode = NSLineBreakByClipping;
        [self addSubview:_content];
        
        // Indicator for missing content
        _contentInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _contentInd.color = FMS_COLOUR_INDICATOR_DARK;
        _contentInd.hidesWhenStopped = YES;
        [_contentInd startAnimating];
        [self addSubview:_contentInd];
        
        // Ping button
        _pingButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_pingButton setTitle:@"Ping" forState:UIControlStateNormal];
        [_pingButton setTitle:@"" forState:UIControlStateDisabled];
        _pingButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [self addSubview:_pingButton];
        
        // Ping indicator
        _pingInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _pingInd.color = FMS_COLOUR_INDICATOR_DARK;
        _pingInd.hidesWhenStopped = YES;
        [_pingInd stopAnimating];
        [self addSubview:_pingInd];
        
        // Ping label
        _pingDetail = [[UILabel alloc] init];
        _pingDetail.font = [UIFont systemFontOfSize:17];
        [self addSubview:_pingDetail];
        [_pingDetail setHidden:YES];
        
        // Close button
        _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_cancelButton setTitle:@"Close" forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:18];
        [self addSubview:_cancelButton];
        
        // End
        [_pingButton sizeToFit];
        [_cancelButton sizeToFit];
        [self layoutSubviews];
        float trueHeight = _content.frame.size.height + 50;
        self.frame = CGRectMake(self.frame.origin.x, self.center.y - trueHeight/2, self.frame.size.width, trueHeight);
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Ping/cancel buttons
    _pingButton.frame = CGRectMake(15, 5, _pingButton.frame.size.width, _pingButton.frame.size.height);
    _pingDetail.frame = CGRectMake(30 + _pingButton.frame.size.width, 5, 200, _pingButton.frame.size.height);
    _pingInd.center = _pingButton.center;
    _cancelButton.frame = CGRectMake(self.frame.size.width - _cancelButton.frame.size.width - 15, 5, _cancelButton.frame.size.width, _cancelButton.frame.size.height);
    
    //Content
    [_content sizeToFit];
    float newHeight = (_content.frame.size.height < 70) ? 70 : _content.frame.size.height;
    _content.frame = CGRectMake(10, 40, self.frame.size.width - 20, newHeight);
    _contentInd.center = _content.center;
}

- (void)hidePingButton {
    [self.pingButton setHidden:YES];
}

- (void)startPinging {
    [self.pingDetail setHidden:YES];
    [self.pingButton setEnabled:NO];
    [self.pingInd startAnimating];
}

- (void)finishPingingTimeout {
    [self.pingInd stopAnimating];
    self.pingDetail.textColor = FMS_COLOUR_TEXT_ERROR;
    self.pingDetail.text = [NSString stringWithFormat:@"\u274C timed out"];
    [self.pingDetail setHidden:NO];
    [self.pingButton setEnabled:YES];
}

- (void)finishPingingServerError {
    [self.pingInd stopAnimating];
    self.pingDetail.textColor = FMS_COLOUR_TEXT_ERROR;
    self.pingDetail.text = [NSString stringWithFormat:@"\u274C server error"];
    [self.pingDetail setHidden:NO];
    [self.pingButton setEnabled:YES];
}

- (void)finishPingingSuccessWithTime:(NSNumber *)seconds {
    [self.pingInd stopAnimating];
    self.pingDetail.textColor = FMS_COLOUR_TEXT_SUCCESS;
    self.pingDetail.text = [NSString stringWithFormat:@"%lus \u2713", seconds.integerValue];
    [self.pingDetail setHidden:NO];
    [self.pingButton setEnabled:YES];
}

- (void)displayBuoyInfo:(NSDictionary *)info {
    NSMutableParagraphStyle *clipStyle = [[NSMutableParagraphStyle alloc] init];
    clipStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary *titleAttr = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:18], NSParagraphStyleAttributeName : clipStyle};
    NSDictionary *groupAttr = @{ NSFontAttributeName : [UIFont systemFontOfSize:15], NSForegroundColorAttributeName : FMS_COLOUR_TEXT_FADE, NSParagraphStyleAttributeName : clipStyle };
    NSDictionary *timeAttr = @{ NSFontAttributeName : [UIFont italicSystemFontOfSize:15] };
    NSDictionary *attr = @{NSFontAttributeName : [UIFont fontWithName:@"Courier" size:17]};
    NSMutableAttributedString *infoString = [[NSMutableAttributedString alloc] initWithString:@""];
    
    // Write name and times
    if (self.buoy) {
        NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", self.buoy.title] attributes:titleAttr];
        [infoString appendAttributedString:titleString];
        
        NSAttributedString *groupString;
        if (self.buoy.group.groupId == 0) {
            groupString = [[NSAttributedString alloc] initWithString:@"\n"];
        } else {
            groupString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%@)\n", self.buoy.group.title] attributes:groupAttr];
        }
        [infoString appendAttributedString:groupString];
    }
    if (self.buoy && self.buoy.dateCreated) { // Creation date
        NSString *dateStr = [NSDateFormatter localizedStringFromDate:self.buoy.dateCreated dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        dateStr = [NSString stringWithFormat:@"  Created:  %@\n", dateStr];
        NSAttributedString *dateString = [[NSAttributedString alloc] initWithString:dateStr attributes:timeAttr];
        [infoString appendAttributedString:dateString];
    }
    if (self.buoy && info.count > 0 && info[@"ts"] != nil) { // Update date
        NSDate *dateUpdated = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)info[@"ts"]).integerValue];
        NSString *dateStr = [NSDateFormatter localizedStringFromDate:dateUpdated dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        dateStr = [NSString stringWithFormat:@"  Last reading:  %@:\n", dateStr];
        NSAttributedString *dateString = [[NSAttributedString alloc] initWithString:dateStr attributes:timeAttr];
        [infoString appendAttributedString:dateString];
    }
    
    // Add space
    [infoString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    
    // Pull out info in dictionary as strings to append
    NSUInteger num = 0;
    for (NSString *key in info.allKeys) {
        if ([key isEqualToString:@"ts"])
            continue; //Don't bother with timestamp
        
        NSString *val = info[key];
        // Key
        NSAttributedString *formatKey = [[NSAttributedString alloc] initWithString:[key stringByPaddingToLength:28 - val.length withString:@" " startingAtIndex:0] attributes:attr];
        [infoString appendAttributedString:formatKey];
        
        // Value
        
        NSAttributedString *formatVal = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", val] attributes:attr];
        [infoString appendAttributedString:formatVal];
        
        num ++;
    }
    
    // If none were displayed, say so
    if (num == 0) {
        NSAttributedString *formatMsg = [[NSAttributedString alloc] initWithString:@"No readings found." attributes:attr];
        [infoString appendAttributedString:formatMsg];
    }
    
    // Display
    self.content.attributedText = infoString;
    [self.contentInd stopAnimating];
    [self.content setHidden:NO];
    [self layoutSubviews];
    
    // Update size
    float trueHeight = _content.frame.size.height + 50;
    CGRect trueSize = CGRectMake(self.frame.origin.x, self.center.y - trueHeight/2, self.frame.size.width, trueHeight);
    if (!CGRectEqualToRect(self.frame, trueSize)) {
        [UIView animateWithDuration:0.4 animations:^{
            self.frame = trueSize;
        }];
    }
}

- (void)displayBuoyLoadingFailed {
    // We copy much of the standard display, but have an error message
    NSMutableParagraphStyle *clipStyle = [[NSMutableParagraphStyle alloc] init];
    clipStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    NSDictionary *titleAttr = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:18], NSParagraphStyleAttributeName : clipStyle};
    NSDictionary *groupAttr = @{ NSFontAttributeName : [UIFont systemFontOfSize:15], NSForegroundColorAttributeName : FMS_COLOUR_TEXT_FADE, NSParagraphStyleAttributeName : clipStyle };
    NSDictionary *timeAttr = @{ NSFontAttributeName : [UIFont italicSystemFontOfSize:15] };
    NSDictionary *attr = @{NSFontAttributeName : [UIFont fontWithName:@"Courier" size:17], NSForegroundColorAttributeName : FMS_COLOUR_TEXT_ERROR};
    NSMutableAttributedString *infoString = [[NSMutableAttributedString alloc] initWithString:@""];
    
    // Write name and times
    if (self.buoy) {
        NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", self.buoy.title] attributes:titleAttr];
        [infoString appendAttributedString:titleString];
        
        NSAttributedString *groupString;
        if (self.buoy.group.groupId == 0) {
            groupString = [[NSAttributedString alloc] initWithString:@" (unlisted)\n" attributes:groupAttr];
        } else {
            groupString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" (%@)\n", self.buoy.group.title] attributes:groupAttr];
        }
        [infoString appendAttributedString:groupString];
    }
    if (self.buoy && self.buoy.dateCreated) { // Creation date
        NSString *dateStr = [NSDateFormatter localizedStringFromDate:self.buoy.dateCreated dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        dateStr = [NSString stringWithFormat:@"  Created:  %@\n", dateStr];
        NSAttributedString *dateString = [[NSAttributedString alloc] initWithString:dateStr attributes:timeAttr];
        [infoString appendAttributedString:dateString];
    }
    
    // Add space
    [infoString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    
    // If none were displayed, say so
    NSAttributedString *formatMsg = [[NSAttributedString alloc] initWithString:@"Failed loading readings from server." attributes:attr];
    [infoString appendAttributedString:formatMsg];
    
    // Display
    self.content.attributedText = infoString;
    [self.contentInd stopAnimating];
    [self.content setHidden:NO];
    [self layoutSubviews];
    
    // Update size
    float trueHeight = _content.frame.size.height + 50;
    CGRect trueSize = CGRectMake(self.frame.origin.x, self.center.y - trueHeight/2, self.frame.size.width, trueHeight);
    if (!CGRectEqualToRect(self.frame, trueSize)) {
        [UIView animateWithDuration:0.4 animations:^{
            self.frame = trueSize;
        }];
    }
}

@end



@implementation BuoySettingsPopup {
    NSUInteger maxFilterRows;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    maxFilterRows = [[UIApplication sharedApplication] keyWindow].frame.size.width/44 - 4;
    self.preferredContentSize = CGSizeMake(300, 190);
    
    self.t = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.t.delegate = self;
    self.t.dataSource = self;
    self.t.tintColor = FMS_COLOUR_BUTTON_DARK;
    self.t.backgroundColor = FMS_COLOUR_BG_LIGHT_SHADE;
    self.t.scrollEnabled = YES;
    
    [self.view addSubview:self.t];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.t reloadData];
    
    NSUInteger rowCount = [self.t numberOfRowsInSection:1] + [self.t numberOfRowsInSection:2];
    if (rowCount > maxFilterRows) {
        self.preferredContentSize = CGSizeMake(300, 190 + 44 * maxFilterRows);
    } else {
        self.preferredContentSize = CGSizeMake(300, 190 + 44 * rowCount);
    }
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.t.frame = self.view.frame;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return (self.delegate.unlistedBuoys.count == 0) ? 1 : self.delegate.unlistedBuoys.count;
        case 2:
            return (self.delegate.buoyGroups.count == 0) ? 1 : self.delegate.buoyGroups.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Settings";
        case 1:
            return @"Unlisted Buoys";
        case 2:
            return @"Filters";
    }
    
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Get new empty reusable table cell
    UITableViewCell *c;
    
    if (indexPath.section == 0) {// Settings
        c = [self.t dequeueReusableCellWithIdentifier:@"SelectCell"];
        if (c == nil) {
            c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SelectCell"];
            c.backgroundColor = FMS_COLOUR_BG_LIGHT;
            
            UISegmentedControl *typeChooser = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Map", @"Satellite", nil]];
            typeChooser.frame = CGRectMake(c.frame.size.width/2 - 10, 5, c.frame.size.width/2 - 20, c.frame.size.height - 10);
            typeChooser.selectedSegmentIndex = 0;
            [typeChooser addTarget:self.delegate action:@selector(mapTypeButtonPressed:) forControlEvents:UIControlEventValueChanged];
            [c addSubview:typeChooser];
        }
        c.textLabel.text = @"Map type:";
        c.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.section == 1) { // Unlisted buoys
        c = [self.t dequeueReusableCellWithIdentifier:@"ListCell"];
        if (c == nil) {
            c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ListCell"];
            c.backgroundColor = FMS_COLOUR_BG_LIGHT;
        }
        
        if (self.delegate.unlistedBuoys.count == 0) { // No buoys unlisted
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            c.textLabel.text = @"No unlisted buoys.";
            c.detailTextLabel.text = nil;
            c.accessoryType = UITableViewCellAccessoryNone;
        } else { // Show buoy at this index
            Buoy *b = [self.delegate.unlistedBuoys objectAtIndex:indexPath.row];
            c.selectionStyle = UITableViewCellSelectionStyleDefault;
            c.textLabel.text = b.title;
            c.detailTextLabel.text = (b.group == nil || b.group.groupId == 0) ? nil : b.group.title;
            c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (indexPath.section == 2) { // Filters
        c = [self.t dequeueReusableCellWithIdentifier:@"BlankCell"];
        if (c == nil) {
            c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BlankCell"];
            c.backgroundColor = FMS_COLOUR_BG_LIGHT;
            
            UIView *colourator = [[UIView alloc] initWithFrame:CGRectMake(10, 10, 20, 20)];
            colourator.backgroundColor = [UIColor lightGrayColor];
            colourator.layer.cornerRadius = 4;
            colourator.tag = 1;
            [c addSubview:colourator];
            colourator.hidden = YES;
        }
        
        if (self.delegate.buoyGroups.count == 0) { // No buoys loaded to filter
            c.selectionStyle = UITableViewCellSelectionStyleNone;
            if (self.delegate.allBuoys.count == 0) {
                c.textLabel.text = @"No buoys currently loaded.";
            } else {
                c.textLabel.text = @"No groups to filter.";
            }
        } else { // Show buoy group at this index
            BuoyGroup *g = [self.delegate.buoyGroups objectAtIndex:indexPath.row];
            c.textLabel.text = (g.groupId == 0) ? @"Unassigned" : g.title;
            c.selectionStyle = UITableViewCellSelectionStyleDefault;
            
            // Select if part of selected or none selected
            if ([self.delegate.buoyGroupsToShow containsIndex:indexPath.row]) {
                c.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                c.accessoryType = UITableViewCellAccessoryNone;
            }
            
            // Add colour view to match for ungrouped buoys
            if (g.groupId != 0) { // Ungrouped
                UIView *colourator = [c viewWithTag:1];
                colourator.hidden = NO;
                NSUInteger shift = ((BuoyGroup *)[self.delegate.buoyGroups objectAtIndex:0]).groupId == 0 ? 1 : 0;
                colourator.backgroundColor = [MiscInterface colourForIndex:(indexPath.row - shift) outOfTotal:(self.delegate.buoyGroups.count - shift)];
            }
            // Spacing fix for titles
            c.textLabel.text = [NSString stringWithFormat:@"     %@", c.textLabel.text];
        }
    }

    return c;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || self.delegate.moreInfoDialog != nil) {
        return; //Ignore as nothing happens on selection
    } else if (indexPath.section == 1) { // Unlisted buoys
        if (self.delegate.unlistedBuoys.count == 0) {
            return;
        }
        
        // Deselect
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        // Open more info
        Buoy *b = [self.delegate.unlistedBuoys objectAtIndex:indexPath.row];
        [self.delegate moreInfoOpenedForBuoy:b];
    } else if (indexPath.section == 2) { // Filters
        if (self.delegate.buoyGroups.count == 0) {
            return;
        }
        
        // Select
        if ([self.delegate.buoyGroupsToShow containsIndex:indexPath.row]) {
            [self.delegate.buoyGroupsToShow removeIndex:indexPath.row];
        } else {
            [self.delegate.buoyGroupsToShow addIndex:indexPath.row];
        }
        
        // Refresh
        [self.t reloadData];
        [self.delegate updateMapToMatchSelection];
    }
}

- (void)forceUpdate {
    // Forces an update right at this moment for this popup view's info
    [self.t reloadData];
    NSUInteger rowCount = [self.t numberOfRowsInSection:1] + [self.t numberOfRowsInSection:2];
    if (rowCount > maxFilterRows) {
        self.preferredContentSize = CGSizeMake(300, 190 + 44 * maxFilterRows);
    } else {
        self.preferredContentSize = CGSizeMake(300, 190 + 44 * rowCount);
    }
}

@end


@implementation BuoyScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Use location manager to ensure they have current location enabled
    self.l = [[CLLocationManager alloc] init];
    self.l.delegate = self;
    if ([self.l respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.l requestWhenInUseAuthorization];
    }
    
    // Data models
    self.allBuoys = [NSArray array];
    self.unlistedBuoys = [NSArray array];
    self.buoyGroups = [NSArray array];
    self.buoyGroupsToShow = [NSMutableIndexSet indexSet];
    
    // Overall colour
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.tintColor = FMS_COLOUR_BUTTON_DARK;
    
    // Create map and fit to screen
    self.map = [[MKMapView alloc] initWithFrame:self.view.frame];
    self.map.mapType = MKMapTypeStandard;
    self.map.showsPointsOfInterest = NO;
    self.map.showsBuildings = NO;
    self.map.zoomEnabled = YES;
    self.map.scrollEnabled = YES;
    self.map.pitchEnabled = NO;
    self.map.rotateEnabled = NO;
    self.map.delegate = self;
    
    // Navigation bar settings
    // Info gear button
    UIButton *infoView = [UIButton buttonWithType:UIButtonTypeSystem];
    infoView.frame = CGRectMake(0, 0, 30, 30);
    [infoView setTitle:@"\u2699" forState:UIControlStateNormal];
    infoView.titleLabel.font = [UIFont systemFontOfSize:26];
    infoView.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [infoView setTitleColor:FMS_COLOUR_TEXT_LIGHT forState:UIControlStateNormal];
    [infoView addTarget:self action:@selector(infoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *infoIcon = [[UIBarButtonItem alloc] initWithCustomView:infoView];
    infoIcon.width = 30;
    
    // Position icon
    UIBarButtonItem *posIcon = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.map];
    
    // Refresh icon
    UIBarButtonItem *refreshIcon = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonPressed)];
    UIActivityIndicatorView *refreshInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [refreshInd sizeToFit];
    [refreshInd startAnimating];
    refreshInd.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    UIBarButtonItem *refreshIndIcon = [[UIBarButtonItem alloc] initWithCustomView:refreshInd];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:infoIcon, posIcon, refreshIcon, nil];
    
    // Popover for options
    BuoySettingsPopup *pContents = [[BuoySettingsPopup alloc] init];
    pContents.delegate = self;
    self.pButton = infoIcon;
    self.popup = pContents;
    
    // Refresh settings
    self.rButton = refreshIcon;
    self.rInd = refreshInd;
    self.rIndButton = refreshIndIcon;
    
    // More info dialog container
    self.moreInfoDialogContainer = [UIButton buttonWithType:UIButtonTypeCustom];
    self.moreInfoDialogContainer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    self.moreInfoDialogContainer.frame = self.view.bounds;
    [self.moreInfoDialogContainer addTarget:self action:@selector(closeMoreInfoPressed) forControlEvents:UIControlEventTouchUpInside];
    
    // Fin
    [self.view addSubview:self.map];
    [self.view addSubview:self.moreInfoDialogContainer];
    [self.moreInfoDialogContainer setHidden:YES];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.map.frame = self.view.frame;
    self.moreInfoDialogContainer.frame = self.view.frame;
    if (self.moreInfoDialog != nil) {
        self.moreInfoDialog.center = self.moreInfoDialogContainer.center;
        [self.moreInfoDialog layoutSubviews];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.d.dataDelegate = self;
    
    self.title = [self.d userDisplayName];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Disconnect from server after leaving this screen
    [self.d disconnect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if ([self.view window] == nil) {
        self.map = nil;
        self.view = nil;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UI changes
- (void)setRefreshIconLoading {
    NSMutableArray *a = [[NSMutableArray alloc] init];
    for (UIBarButtonItem *b in self.navigationItem.rightBarButtonItems) {
        if (b == self.rButton) {
            [a addObject:self.rIndButton];
        } else {
            [a addObject:b];
        }
    }
    
    self.navigationItem.rightBarButtonItems = a;
}

- (void)setRefreshIconRefresh {
    NSMutableArray *a = [[NSMutableArray alloc] init];
    for (UIBarButtonItem *b in self.navigationItem.rightBarButtonItems) {
        if (b == self.rIndButton) {
            [a addObject:self.rButton];
        } else {
            [a addObject:b];
        }
    }
    
    self.navigationItem.rightBarButtonItems = a;
}

#pragma mark - location updates and animations
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.map.showsUserLocation = YES;
        self.map.userTrackingMode = MKUserTrackingModeFollow;
    }
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
    NSLog(@"Map loading error: %@", error);
    
    // Create alert box informing user
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Couldn't load map" message:@"Loading map data requires an active internet connection." preferredStyle:UIAlertControllerStyleAlert];
    
    // Add buttons for logging out and cancelling (cancelling should just repeat until it's fixed or they logout)
    [a addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:a animated:YES completion:nil];
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"Locating user error: %@", error);
    
    // Create alert box informing user
    UIAlertController *a;
    if ([CLLocationManager locationServicesEnabled]) { // Depends on type of error
        if (error.code == 0) {
            return; //Don't give a fuck about those damn error 0 messages.
        }
        a = [UIAlertController alertControllerWithTitle:@"Locate failed" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        
        // Logout button
        [a addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
    } else {
        a = [UIAlertController alertControllerWithTitle:@"Locate failed" message:@"Location services must be enabled in order to locate your position." preferredStyle:UIAlertControllerStyleAlert];
        
        // Settings button
        [a addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }]];
    }
    
    // Cancel button
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:a animated:YES completion:nil];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    DiamondMarker *v = (DiamondMarker *)[self.map dequeueReusableAnnotationViewWithIdentifier:@"BuoyIcon"];
    if (v == nil) {
        // Initial only properties
        v = [[DiamondMarker alloc] initWithAnnotation:annotation reuseIdentifier:@"BuoyIcon"];
        v.canShowCallout = YES;
        
        // Label containing lat/long
        UILabel *leftViewLabel = [[UILabel alloc] init];
        leftViewLabel.font = [UIFont systemFontOfSize:12];
        leftViewLabel.numberOfLines = 2;
        leftViewLabel.textAlignment = NSTextAlignmentRight;
        v.leftCalloutAccessoryView = leftViewLabel;
        
        // Buttons for more info and stuff
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton addTarget:self action:@selector(moreInfoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        v.rightCalloutAccessoryView = rightButton;
    } else {
        // Reuse only properties
        v.annotation = annotation;
    }
    
    // General properties
    Buoy *b = (Buoy *)annotation;
    UILabel *leftViewLabel = (UILabel *)v.leftCalloutAccessoryView;
    leftViewLabel.text = [NSString stringWithFormat:@"%@\n%@", [DataModel stringForLatitude:b.trueCoord.latitude], [DataModel stringForLongitude:b.trueCoord.longitude]];
    [leftViewLabel sizeToFit];
    v.leftCalloutAccessoryView = leftViewLabel;
    UIButton *rightButton = (UIButton *)v.rightCalloutAccessoryView;
    rightButton.tag = [self.allBuoys indexOfObject:b];
    
    // Marker colours
    if (b.group == nil || b.group.groupId == 0) { // Ungrouped
        v.edgeColour = [UIColor lightGrayColor];
    } else { // Grouped buoy
        NSUInteger shift = ((BuoyGroup *)[self.buoyGroups objectAtIndex:0]).groupId == 0 ? 1 : 0;
        v.edgeColour = [MiscInterface colourForIndex:([self.buoyGroups indexOfObject:b.group] - shift) outOfTotal:(self.buoyGroups.count - shift)];
    }
    
    return v;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views {
    for (NSUInteger i = 0; i < views.count; i++) {
        MKAnnotationView *av = [views objectAtIndex:i];
        
        // Ignore user location
        if (![av.annotation isKindOfClass:[Buoy class]]) {
            continue;
        }
        
        // Ensure contained within visible map rect
        MKMapPoint p = MKMapPointForCoordinate(av.annotation.coordinate);
        if (!MKMapRectContainsPoint(self.map.visibleMapRect, p)) {
            continue;
        }
        
        // Otherwise, animate bounce
        av.transform = CGAffineTransformMakeScale(0, 0);
        [UIView animateWithDuration:0.3 delay:0.1*i options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             av.transform = CGAffineTransformMakeScale(0.8, 1.2);
                         }
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:0.05 animations:^{
                                 av.transform = CGAffineTransformIdentity;
                             }];
                         }
         ];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    // Ignore user location
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    
    // Select
    DiamondMarker *d = (DiamondMarker *)view;
    d.coreColour = [UIColor colorWithWhite:0.9 alpha:1.0];
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    // Ignore user location
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    
    // Deselect
    DiamondMarker *d = (DiamondMarker *)view;
    d.coreColour = [UIColor whiteColor];
}

- (void)updateMapToMatchSelection {
    // Remove any annotations not selected, or add those which are
    for (NSUInteger i = 0; i < self.buoyGroups.count; i++) {
        BuoyGroup *g = [self.buoyGroups objectAtIndex:i];
        if (self.buoyGroupsToShow.count == 0 || [self.buoyGroupsToShow containsIndex:i]) {
            for (Buoy *b in g.buoys) {
                if (b.validCoordinate && ![self.map.annotations containsObject:b]) {
                    [self.map addAnnotation:b];
                }
            }
        } else {
            for (Buoy *b in g.buoys) {
                if ([self.map.annotations containsObject:b]) {
                    [self.map removeAnnotation:b];
                }
            }
        }
    }
}

#pragma mark - server comms

- (void)didGetBuoyListFromServer:(NSArray *)buoyGroups {
    // Stop loading icon
    [self setRefreshIconRefresh];
    
    // Ensure not displaying more info, otherwise ignore
    if (self.moreInfoDialog != nil) {
        return;
    }
    
    // Remove previous annotations
    [self.map removeAnnotations:self.allBuoys];
    
    // Get buoy information from list of buoys/groups
    NSMutableArray *allBuoys = [[NSMutableArray alloc] init];
    NSMutableArray *unlistedBuoys = [[NSMutableArray alloc] init];
    NSMutableArray *displayedBuoyGroups = [[NSMutableArray alloc] init];
    for (BuoyGroup *g in buoyGroups) {
        BOOL hasDisplayedBuoy = NO;
        for (Buoy *b in g.buoys) {
            // Get buoys with valid coordinates
            if (b.validCoordinate) {
                [allBuoys addObject:b];
                hasDisplayedBuoy = YES;
            } else {
                NSLog(@"Buoy %@ with id %d has invalid coord - adding to unlisted list", b, b.buoyId);
                [unlistedBuoys addObject:b];
            }
        }
        
        // Get all buoys
        [allBuoys addObjectsFromArray:g.buoys];
        
        // Add group if displayed
        if (hasDisplayedBuoy) {
            [displayedBuoyGroups addObject:g];
        }
    }
    
    // Update globals
    self.allBuoys = allBuoys;
    self.unlistedBuoys = unlistedBuoys;
    self.buoyGroups = [displayedBuoyGroups sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        BuoyGroup *a2 = (BuoyGroup *)a;
        BuoyGroup *b2 = (BuoyGroup *)b;
        if (a2.groupId < b2.groupId) {
            return NSOrderedAscending;
        } else if (a2.groupId > b2.groupId) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    self.buoyGroupsToShow = [NSMutableIndexSet indexSet];
    [(BuoySettingsPopup *)self.popup forceUpdate];
    
    // Reload map
    [self.map addAnnotations:self.allBuoys];
}

- (void)didGetBuoyInfoFromServer:(NSDictionary *)buoyInfo forBuoy:(Buoy *)b {
    // Update more info dialog to contain info
    if (self.moreInfoDialog) {
        // Check if right buoy
        if (self.moreInfoDialog.buoy != b) {
            return;
        }
        
        // Do this to force onto main thread, as it likes to jump onto background thread sometimes.
        [self.moreInfoDialog performSelectorOnMainThread:@selector(displayBuoyInfo:) withObject:buoyInfo waitUntilDone:NO];
    }
}

- (void)didFailBuoyInfoForBuoy:(Buoy *)b {
    // Update more info dialog to say so
    if (self.moreInfoDialog) {
        // Check if right buoy
        if (self.moreInfoDialog.buoy != b) {
            return;
        }
        
        [self.moreInfoDialog displayBuoyLoadingFailed];
    }
}

- (void)didGetPingDataWithPing:(NSTimeInterval)ping forBuoy:(Buoy *)b {
    // Update more info dialog to ping res
    if (self.moreInfoDialog) {
        // Check if right buoy
        if (self.moreInfoDialog.buoy != b) {
            return;
        }
        
        // Do this to force onto main thread, as it likes to jump onto background thread sometimes.
        [self.moreInfoDialog performSelectorOnMainThread:@selector(finishPingingSuccessWithTime:) withObject:[NSNumber numberWithInteger:ping] waitUntilDone:NO];
    }
}

- (void)didTimeoutPing:(Buoy *)b {
    // Update more info dialog to ping res
    if (self.moreInfoDialog) {
        // Check if right buoy
        if (self.moreInfoDialog.buoy != b) {
            return;
        }
        
        [self.moreInfoDialog finishPingingTimeout];
    }
}

- (void)didServerErrorPing:(Buoy *)b {
    // Update more info dialog to ping res
    if (self.moreInfoDialog) {
        // Check if right buoy
        if (self.moreInfoDialog.buoy != b) {
            return;
        }
        
        [self.moreInfoDialog finishPingingServerError];
    }
}

- (void)didFailServerComms {
    [self setRefreshIconRefresh];
    
    // Create alert box informing user
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"Couldn't load buoy info" message:@"Could not establish connection with server" preferredStyle:UIAlertControllerStyleAlert];
    
    // Add buttons for logging out or cancelling
    [a addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:a animated:YES completion:nil];
}

#pragma mark - UI events
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void)infoButtonPressed {
    // Do nothing while more info is open
    if (self.moreInfoDialog != nil) {
        return;
    }
    
    self.popup.modalPresentationStyle = UIModalPresentationPopover;
    self.popup.popoverPresentationController.delegate = self;
    self.popup.popoverPresentationController.barButtonItem = self.pButton;
    self.popup.popoverPresentationController.sourceView = self.popup.view;
    [self presentViewController:self.popup animated:YES completion:nil];
}

- (void)refreshButtonPressed {
    [self setRefreshIconLoading];
    [self.d updateBuoyListingFromServer];
}

- (void)mapTypeButtonPressed:(UIControl *)c {
    UISegmentedControl *typeChooser = (UISegmentedControl *)c;
    
    if (typeChooser.selectedSegmentIndex == 0) {
        self.map.mapType = MKMapTypeStandard;
    } else if (typeChooser.selectedSegmentIndex == 1) {
        self.map.mapType = MKMapTypeSatellite;
    }
}

- (void)moreInfoButtonPressed:(UIControl *)c {
    // Deselect any annotations
    for (id<MKAnnotation> a in self.map.selectedAnnotations) {
        [self.map deselectAnnotation:a animated:YES];
    }
    
    // Get buoy to display
    UIButton *buttonPressed = (UIButton *)c;
    Buoy *b = [self.allBuoys objectAtIndex:buttonPressed.tag];
    [self moreInfoOpenedForBuoy:b];
}

- (void)moreInfoOpenedForBuoy:(Buoy *)b {
    NSLog(@"Opening more info...");
    
    // Close popup, if present
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self _moreInfoOpenedForBuoy:b];
        }];
    } else {
        [self _moreInfoOpenedForBuoy:b];
    }
}

- (void)_moreInfoOpenedForBuoy:(Buoy *)b {
    // Create more info dialog
    self.moreInfoDialog = [[MoreInfoDialog alloc] init];
    self.moreInfoDialog.center = self.moreInfoDialogContainer.center;
    [self.moreInfoDialog.pingButton addTarget:self action:@selector(pingMoreInfoPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.moreInfoDialog.cancelButton addTarget:self action:@selector(closeMoreInfoPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.moreInfoDialogContainer addSubview:self.moreInfoDialog];
    self.moreInfoDialog.buoy = b;
    
    // Hide ping if no clearance
    if (![self.d hasConfigClearance]) {
        [self.moreInfoDialog hidePingButton];
    }
    
    // Start settings for animation
    self.moreInfoDialogContainer.alpha = 0;
    self.moreInfoDialog.transform = CGAffineTransformMakeScale(0, 0);
    [self.moreInfoDialogContainer setHidden:NO];
    
    // Animate popup
    [UIView animateWithDuration:0.5 animations:^{
        self.moreInfoDialogContainer.alpha = 1;
        self.moreInfoDialog.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished){
        if (finished) {
            [self.moreInfoDialogContainer setEnabled:YES];
        }
    }];
    
    // Start request for info
    [self.d requestBuoyInfo:b];
}

- (void)closeMoreInfoPressed {
    [self.moreInfoDialogContainer setEnabled:NO];
    
    // Animate close
    self.moreInfoDialog.transform = CGAffineTransformIdentity;
    [UIView animateWithDuration:0.5 animations:^{
        self.moreInfoDialog.transform = CGAffineTransformMakeScale(0.001, 0.001);
        self.moreInfoDialogContainer.alpha = 0;
    } completion:^(BOOL finished){
        if (finished) {
            [self.moreInfoDialogContainer setHidden:YES];
            self.moreInfoDialog = nil;
        }
    }];
}

- (void)pingMoreInfoPressed {
    // Update interface to start ping look
    [self.moreInfoDialog startPinging];
    
    // Send ping
    [self.d getPingDataFor:self.moreInfoDialog.buoy];
}

@end
