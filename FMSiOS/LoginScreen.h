//
//  LoginScreen.h
//  Flood MS iOS
//
//  Created by Sean M on 3/09/2015.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataModel.h"
#import "Interface.h"
#import "BuoyScreen.h"

@interface LoginScreen : UIViewController <DataModelInitDelegate>

@property (nonatomic, weak) DataModel *d;
@property (strong, nonatomic) BuoyScreen *b;

@end

