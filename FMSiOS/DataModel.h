//
//  DataModel.h
//  FMSiOS
//
//  Created by Sean M on 4/09/2015.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#define FMS_DEFAULT_SERVER_ADDRESS @"teamneptune.co"

#define FMS_PING_TRIES 7
#define FMS_PING_SPACE_BETWEEN_TRIES 1.0

// Data model for a buoy and the groups containing them
@interface BuoyGroup : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *buoys;

@property (nonatomic, strong) NSString *title; //Name of this group of buoys
@property NSUInteger groupId; //ID for this group

@end

@interface Buoy : NSObject <MKAnnotation>

@property (nonatomic, weak) BuoyGroup *group; //nil for no group

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate; //Coordinate shown on map
@property (nonatomic) CLLocationCoordinate2D trueCoord; //Actual coordinate given
@property BOOL validCoordinate;
@property (nonatomic, strong) NSDate *dateCreated;
@property (nonatomic, strong) NSString *buoyName;
@property (nonatomic, strong) NSString *buoyGuid; //ids for different purposes
@property NSUInteger buoyId;
@property NSUInteger databaseId;


- (instancetype)initWithCoord:(CLLocationCoordinate2D)coord;

@end

// Delegates for communication with the data model and VCs
@protocol DataModelInitDelegate <NSObject>

- (void)didConnectToServer;
- (void)didFailToConnectBadDetails;
- (void)didFailToConnectServerFail;
- (void)didFailToConnectServerNotFound;

@end

@protocol DataModelDataDelegate <NSObject>

- (void)didFailServerComms;

- (void)didFailBuoyInfoForBuoy:(Buoy *)b;

- (void)didTimeoutPing:(Buoy *)b;
- (void)didServerErrorPing:(Buoy *)b;

- (void)didGetBuoyListFromServer:(NSArray *)buoyGroups;
- (void)didGetBuoyInfoFromServer:(NSDictionary *)buoyInfo forBuoy:(Buoy *)b;
- (void)didGetPingDataWithPing:(NSTimeInterval)ping forBuoy:(Buoy *)b;

@end

// Core server communication data model
@interface DataModel : NSObject

@property (nonatomic, weak) NSObject<DataModelInitDelegate> *delegate;
@property (nonatomic, weak) NSObject<DataModelDataDelegate> *dataDelegate;

// Server connection stuff
- (void)connectToServerWithEmail:(NSString *)email andPass:(NSString *)password;
- (void)updateBuoyListingFromServer;
- (void)requestBuoyInfo:(Buoy *)buoy;
- (void)getPingDataFor:(Buoy *)buoy;
- (void)disconnect;

// Info methods after connecting to server (DO NOT USE WHEN DISCONNECTED)
- (NSString *)userDisplayName; //Name/text to display for user's name
- (BOOL)hasConfigClearance; //Can send ping commands etc

// Static helper methods
+ (BOOL)NSStringIsValidEmail:(NSString *)s; // Returns whether the given string is a valid email
+ (NSString *)stringForLatitude:(CLLocationDegrees)latitude;
+ (NSString *)stringForLongitude:(CLLocationDegrees)longitude;
+ (double)addJitter:(double)val withMax:(double)maxVal;

@end
