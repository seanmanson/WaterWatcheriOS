//
//  Interface.m
//  FMSiOS
//
//  Created by Sean M on 4/09/2015.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import "Interface.h"

@implementation MiscInterface

+ (UIColor *)colourForIndex:(NSUInteger)i outOfTotal:(NSUInteger)total {
    double spacingForColour = 1.0/total;
    return [UIColor colorWithHue:(i * spacingForColour) saturation:0.9 brightness:0.9 alpha:1.0];
}

@end

@implementation SpacedTextField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.edgeInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.edgeInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, self.edgeInsets)];
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [super editingRectForBounds:UIEdgeInsetsInsetRect(bounds, self.edgeInsets)];
}

@end



@implementation ShadowButton

// The following are all overrides with specific shadow-related settings
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowRadius = 5;
        self.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.8;
        self.layer.shadowRadius = 2;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.contentEdgeInsets = UIEdgeInsetsMake(1.0, 1.0, -1.0, -1.0);
    self.layer.shadowRadius = 5;
    self.layer.shadowOpacity = 1.0;
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.contentEdgeInsets = UIEdgeInsetsZero;
    self.layer.shadowRadius = 2;
    self.layer.shadowOpacity = 0.8;
    
    [super touchesEnded:touches withEvent:event];
}

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        self.backgroundColor = self.highlightColour;
    } else {
        self.backgroundColor = self.normalColour;
    }
    
    [super setHighlighted:highlighted];
}

- (void)setSelected:(BOOL)selected {
    if (selected) {
        self.backgroundColor = self.selectedColour;
    } else {
        self.backgroundColor = self.normalColour;
    }
    
    [super setSelected:selected];
}

@end


@implementation DiamondMarker

#pragma mark - initialisation
- (void)baseInit {
    _coreColour = [UIColor whiteColor];
    _edgeColour = [UIColor whiteColor];
    self.frame = CGRectMake(0, 0, 30, 35);
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = NO;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self baseInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self baseInit];
        self.frame = frame;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self baseInit];
    }
    return self;
}

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        [self baseInit];
    }
    return self;
}


#pragma mark - drawing methods

- (void)drawRect:(CGRect)rect {
    // Create new path with set colours
    UIBezierPath *p = [UIBezierPath bezierPath];
    [self.coreColour setFill];
    [self.edgeColour setStroke];
    p.lineWidth = 4;
    
    // Draw shape using this path
    double pad = 5.0; // Padding
    [p moveToPoint:CGPointMake(rect.origin.x + rect.size.width/2, rect.origin.y + pad)];
    [p addLineToPoint:CGPointMake(rect.origin.x + pad, rect.origin.y + rect.size.height/2)];
    [p addLineToPoint:CGPointMake(rect.origin.x + rect.size.width/2, rect.origin.y + rect.size.height - pad)];
    [p addLineToPoint:CGPointMake(rect.origin.x + rect.size.width - pad, rect.origin.y + rect.size.height/2)];
    [p closePath];
    
    // Colour path
    [p fill];
    [p stroke];
    
    // Add shadow
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    self.layer.shadowRadius = 5.0;
    self.layer.shadowOpacity = 0.5;
    self.layer.shadowPath = p.CGPath;
}


#pragma mark - external methods

- (void)setCoreColour:(UIColor *)coreColour {
    _coreColour = coreColour;
    [self setNeedsDisplay];
}

- (void)setEdgeColour:(UIColor *)edgeColour {
    _edgeColour = edgeColour;
    [self setNeedsDisplay];
}

@end
