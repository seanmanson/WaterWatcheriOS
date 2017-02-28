//
//  Interface.h
//  FMSiOS
//
//  Created by Sean M on 4/09/2015.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

// Default colours
#define FMS_COLOUR_BG_DARK [UIColor colorWithRed:0x07/255.0 green:0x30/255.0 blue:0x64/255.0 alpha:1.0]
#define FMS_COLOUR_BG_LIGHT [UIColor whiteColor]
#define FMS_COLOUR_BG_SHADE [UIColor colorWithWhite:0.85 alpha:1.0]
#define FMS_COLOUR_BG_LIGHT_SHADE [UIColor colorWithWhite:0.97 alpha:1.0]
#define FMS_COLOUR_BUTTON_DARK [UIColor colorWithRed:0 green:0.332 blue:0.542 alpha:1.0]
#define FMS_COLOUR_BUTTON_DARK_SEL [UIColor colorWithRed:0 green:0.281 blue:0.461 alpha:1.0]
#define FMS_COLOUR_TEXT_LIGHT [UIColor whiteColor]
#define FMS_COLOUR_TEXT_DARK [UIColor blackColor]
#define FMS_COLOUR_TEXT_FADE [UIColor lightGrayColor]
#define FMS_COLOUR_TEXT_BUTTON [UIColor colorWithRed:0.2 green:0.478 blue:0.718 alpha:1.0]
#define FMS_COLOUR_TEXT_ERROR [UIColor colorWithRed:1 green:0.35 blue:0.35 alpha:1]
#define FMS_COLOUR_TEXT_SUCCESS [UIColor colorWithHue:121/256.0 saturation:0.85 brightness:0.55 alpha:1.0]
#define FMS_COLOUR_INDICATOR_DARK [UIColor darkGrayColor]
#define FMS_COLOUR_INDICATOR_LIGHT [UIColor whiteColor]

// Misc interface static methods
@interface MiscInterface : NSObject

// Gets the colour for an object of index i out of a number of indexes, split evenly
+ (UIColor *)colourForIndex:(NSUInteger)i outOfTotal:(NSUInteger)total;

@end

// Special text field used to pad text from edges
@interface SpacedTextField : UITextField

@property UIEdgeInsets edgeInsets;

@end

// Special custom UIButton which can act depressed, because that's cool
@interface ShadowButton : UIButton

@property UIColor *normalColour;
@property UIColor *highlightColour;
@property UIColor *selectedColour;

@end

// Map marker diamond
@interface DiamondMarker : MKAnnotationView

@property (strong, nonatomic) UIColor *coreColour;
@property (strong, nonatomic) UIColor *edgeColour;

@end
