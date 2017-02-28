//
//  BuoyScreen.h
//  FMSiOS
//
//  Created by Sean M on 3/09/2015.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "DataModel.h"
#import "Interface.h"

@interface BuoyScreen : UIViewController <DataModelDataDelegate>

@property (nonatomic, weak) DataModel *d;

@end
