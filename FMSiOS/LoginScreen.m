//
//  LoginScreen.m
//  Flood MS iOS
//
//  Created by Sean M on 3/09/2015.
//  Help given by veducm on Stack Overflow.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import "LoginScreen.h"

@interface LoginScreen () <UITextFieldDelegate>

@property UIImageView *bg;
@property UIView *loginDialog;
@property UILabel *errorLabel;
@property UITextField *emailField;
@property UITextField *passField;
@property UISwitch *saveSwitch;
@property ShadowButton *loginButton;
@property UIActivityIndicatorView *loginInd;
@property UIButton *settingsButton;

@end

@implementation LoginScreen

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Title for next page back button
    self.title = @"Logout";

    // Load background
    self.bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background" inBundle:nil compatibleWithTraitCollection:nil]];
    self.bg.contentMode = UIViewContentModeScaleAspectFill;
    self.bg.frame = CGRectMake(-30, -25, self.view.frame.size.width + 60, self.view.frame.size.height + 50);
    [self.view addSubview:self.bg];
    
    // Add cool parallax effect
    UIInterpolatingMotionEffect *vEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    vEffect.minimumRelativeValue = @(-25);
    vEffect.maximumRelativeValue = @(25);
    UIInterpolatingMotionEffect *hEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    hEffect.minimumRelativeValue = @(-30);
    hEffect.maximumRelativeValue = @(30);
    [self.bg addMotionEffect:vEffect];
    [self.bg addMotionEffect:hEffect];
    
    // Load UI
    // Overall
    self.loginDialog = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    self.loginDialog.center = self.view.center;
    
    // Logo
    UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    topLabel.textAlignment = NSTextAlignmentCenter;
    topLabel.font = [UIFont fontWithName:@"Avenir Next" size:42];
    topLabel.textColor = FMS_COLOUR_TEXT_LIGHT;
    topLabel.text = @"Water Watcher";
    topLabel.center = CGPointMake(150, 40);
    
    // Error message
    UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.font = [UIFont systemFontOfSize:18];
    errorLabel.textColor = FMS_COLOUR_TEXT_ERROR;
    errorLabel.text = @"The error text for the current error message goes here";
    errorLabel.lineBreakMode = NSLineBreakByWordWrapping;
    errorLabel.numberOfLines = 1;
    errorLabel.center = CGPointMake(150, 100);
    [errorLabel setHidden:YES];
    
    // Text dialogs
    SpacedTextField *emailField = [[SpacedTextField alloc] initWithFrame:CGRectMake(0, 0, 280, 50)];
    emailField.edgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    emailField.backgroundColor = FMS_COLOUR_BG_LIGHT;
    emailField.keyboardType = UIKeyboardTypeEmailAddress;
    emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    emailField.returnKeyType = UIReturnKeyNext;
    emailField.placeholder = @"E-mail";
    emailField.center = CGPointMake(150, 150);
    emailField.delegate = self;
    SpacedTextField *passField = [[SpacedTextField alloc] initWithFrame:CGRectMake(0, 0, 280, 50)];
    passField.edgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    passField.backgroundColor = FMS_COLOUR_BG_LIGHT;
    passField.keyboardType = UIKeyboardTypeASCIICapable;
    passField.returnKeyType = UIReturnKeyDone;
    passField.autocorrectionType = UITextAutocorrectionTypeNo;
    passField.secureTextEntry = YES;
    passField.placeholder = @"Password";
    passField.center = CGPointMake(150, 202);
    passField.delegate = self;
    
    // Handle tapping outside
    UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    [self.view addGestureRecognizer:t];
    
    // Save switch
    UISwitch *saveSwitch = [[UISwitch alloc] init];
    saveSwitch.center = CGPointMake(60, 265);
    saveSwitch.backgroundColor = [FMS_COLOUR_BG_LIGHT colorWithAlphaComponent:0.7];
    saveSwitch.layer.cornerRadius = 16;
    
    UILabel *saveLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 35)];
    saveLabel.textAlignment = NSTextAlignmentCenter;
    saveLabel.font = [UIFont systemFontOfSize:17];
    saveLabel.textColor = FMS_COLOUR_TEXT_LIGHT;
    saveLabel.text = @"Remember?";
    saveLabel.center = CGPointMake(60, 295);
    
    // Login button
    ShadowButton *loginButton = [ShadowButton buttonWithType:UIButtonTypeCustom];
    loginButton.backgroundColor = FMS_COLOUR_BUTTON_DARK;
    loginButton.normalColour = FMS_COLOUR_BUTTON_DARK;
    loginButton.highlightColour = FMS_COLOUR_BUTTON_DARK_SEL;
    loginButton.selectedColour = FMS_COLOUR_BUTTON_DARK;
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton setTitleColor:FMS_COLOUR_TEXT_LIGHT forState:UIControlStateNormal];
    [loginButton setTitle:@"" forState:UIControlStateDisabled];
    loginButton.titleLabel.font = [UIFont systemFontOfSize:20];
    loginButton.frame = CGRectMake(0, 0, 150, 50);
    loginButton.center = CGPointMake(210, 275);
    
    // Login button indicator
    self.loginInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.loginInd.hidesWhenStopped = YES;
    [self.loginInd stopAnimating];
    self.loginInd.frame = loginButton.bounds;
    self.loginInd.center = loginButton.center;
    
    // Round corners
    UIBezierPath *topMaskPath = [UIBezierPath bezierPathWithRoundedRect:emailField.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(5.0, 5.0)];
    CAShapeLayer *topMaskLayer = [CAShapeLayer layer];
    topMaskLayer.frame = emailField.bounds;
    topMaskLayer.path = topMaskPath.CGPath;
    emailField.layer.mask = topMaskLayer;
    UIBezierPath *bottomMaskPath = [UIBezierPath bezierPathWithRoundedRect:emailField.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(5.0, 5.0)];
    CAShapeLayer *bottomMaskLayer = [CAShapeLayer layer];
    bottomMaskLayer.frame = passField.bounds;
    bottomMaskLayer.path = bottomMaskPath.CGPath;
    passField.layer.mask = bottomMaskLayer;
    loginButton.layer.cornerRadius = 5.0;
    loginButton.clipsToBounds = YES;
    loginButton.layer.masksToBounds = NO;
    
    // End centre login dialog
    [self.loginDialog addSubview:topLabel];
    [self.loginDialog addSubview:errorLabel];
    [self.loginDialog addSubview:emailField];
    [self.loginDialog addSubview:passField];
    [self.loginDialog addSubview:saveSwitch];
    [self.loginDialog addSubview:saveLabel];
    [self.loginDialog addSubview:loginButton];
    [self.loginDialog addSubview:self.loginInd];
    [self.view addSubview:self.loginDialog];
    
    // Settings icon
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [settingsButton setTitle:@"\u2699" forState:UIControlStateNormal];
    [settingsButton setTitleColor:FMS_COLOUR_TEXT_LIGHT forState:UIControlStateNormal];
    settingsButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:45];
    settingsButton.frame = CGRectMake(0, self.view.frame.size.height - 80, 80, 80);
    [self.view addSubview:settingsButton];
    
    // Set globals
    self.errorLabel = errorLabel;
    self.emailField = emailField;
    self.passField = passField;
    self.saveSwitch = saveSwitch;
    self.loginButton = loginButton;
    self.settingsButton = settingsButton;
    
    // Events
    [loginButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [settingsButton addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.d.delegate = self;
    self.b = nil;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    // Fill dialogs with text from default info
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    self.emailField.text = [d objectForKey:@"SavedEmail"] != nil ? [d objectForKey:@"SavedEmail"] : @"";
    self.passField.text = [d objectForKey:@"SavedPassword"] != nil ? [d objectForKey:@"SavedPassword"] : @"";
    if ([d objectForKey:@"SavedEmail"] != nil || [d objectForKey:@"SavedPassword"] != nil) {
        self.saveSwitch.on = YES;
    } else {
        self.saveSwitch.on = NO;
    }
    //self.emailField.text = @"sean_manson@iprimus.com.au";
    //self.passField.text = @"eB7WIenG";
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.bg.frame = CGRectMake(-30, -25, self.view.frame.size.width + 60, self.view.frame.size.height + 50);
    self.loginDialog.center = self.view.center;
    self.settingsButton.frame = CGRectMake(0, self.view.frame.size.height - 80, 80, 80);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if ([self.view window] == nil) {
        self.bg = nil;
        self.view = nil;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UI changes
- (void)clearError {
    [self.errorLabel setHidden:YES];
}

- (void)errorInvalid {
    self.errorLabel.text = @"Please enter a valid email/password";
    [self.errorLabel setHidden:NO];
}

- (void)errorIncorrect {
    self.errorLabel.text = @"Incorrect email/password";
    [self.errorLabel setHidden:NO];
}

- (void)errorServerFail {
    self.errorLabel.text = @"Error connecting to server";
    [self.errorLabel setHidden:NO];
}

- (void)errorServerNotFound {
    self.errorLabel.text = @"Could not find server at given address";
    [self.errorLabel setHidden:NO];
}

- (void)disableLoginButton {
    self.loginButton.enabled = NO;
    [self.loginInd startAnimating];
}

- (void)enableLoginButton {
    [self.loginInd stopAnimating];
    self.loginButton.enabled = YES;
}

#pragma mark - text field selection
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.backgroundColor = FMS_COLOUR_BG_SHADE;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    textField.backgroundColor = FMS_COLOUR_BG_LIGHT;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Change return button behaviour depending on field
    if (textField == self.emailField) {
        [self.passField becomeFirstResponder];
        return NO;
    } else {
        [textField resignFirstResponder];
        return YES;
    }
}

#pragma mark - button pressed
- (void)loginButtonPressed:(UIControl *)button {
    [self clearError];
    
    // Check for valid email/password
    if ([self.emailField.text isEqualToString:@""] || [self.passField.text isEqualToString:@""] || ![DataModel NSStringIsValidEmail:self.emailField.text]) {
        [self errorInvalid];
        return;
    }
    
    // Prepare UI for server connection
    [self disableLoginButton];
    
    // Start connection process
    [self.d connectToServerWithEmail:self.emailField.text andPass:self.passField.text];
}

- (void)settingsButtonPressed:(UIControl *)button {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

#pragma mark - navigation
- (void)openBuoyPage {
    // Create page to load
    self.b = [[BuoyScreen alloc] init];
    self.b.d = self.d;
    
    // Navigate to page
    [self.navigationController pushViewController:self.b animated:YES];
}

#pragma mark - server conn delegate
- (void)didConnectToServer {
    // Save defaults for user info
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if (self.saveSwitch.on) { // Should save user data
        [d setObject:self.emailField.text forKey:@"SavedEmail"];
        [d setObject:self.passField.text forKey:@"SavedPassword"];
    } else { // Should remove if it exists
        [d removeObjectForKey:@"SavedEmail"];
        [d removeObjectForKey:@"SavedPassword"];
    }
    
    // Go to buoy page
    [self openBuoyPage];
    [self enableLoginButton];
}

- (void)didFailToConnectBadDetails {
    [self errorIncorrect];
    [self enableLoginButton];
}

- (void)didFailToConnectServerFail {
    [self errorServerFail];
    [self enableLoginButton];
}

- (void)didFailToConnectServerNotFound {
    [self errorServerNotFound];
    [self enableLoginButton];
}



@end
