//
//  AppDelegate.m
//  Flood MS iOS
//
//  Created by Sean M on 3/09/2015.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /* APP ENTRY POINT */
    // Set default settings
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"ServerAddress" : FMS_DEFAULT_SERVER_ADDRESS}];
    
    // Build model
    self.d = [[DataModel alloc] init];
    
    // Setup navigation controller
    UINavigationController *n = [[UINavigationController alloc] init];
    n.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    n.navigationBar.tintColor = FMS_COLOUR_TEXT_LIGHT;
    n.navigationBar.barTintColor = FMS_COLOUR_BG_DARK;
    [(UIView *)[n.navigationBar.subviews objectAtIndex:0] setAlpha:0.9];
    n.navigationBar.translucent = YES;
    [n setNavigationBarHidden:YES];
    
    // Setup first screen
    LoginScreen *l = [[LoginScreen alloc] init];
    l.d = self.d;
    [n pushViewController:l animated:NO];
    
    // Setup window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = n;
    [self.window makeKeyAndVisible];
    
    // Do other things
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
