//
//  AppDelegate.h
//  Flood MS iOS
//
//  Created by Sean M on 3/09/2015.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Interface.h"
#import "DataModel.h"
#import "LoginScreen.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

// Core app global properties
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) DataModel *d;

@end

