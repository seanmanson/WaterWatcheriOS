//
//  DataModel.m
//  FMSiOS
//
//  Created by Sean M on 4/09/2015.
//  Copyright (c) 2015 Team Neptune. All rights reserved.
//

#import "DataModel.h"

// Helper classes
@interface PingRequest : NSObject
// Representation of a ping request being executed over several HTTPS requests

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, weak) Buoy *buoy;
@property NSUInteger timesRemaining;
@property NSUInteger commandId;

@end
@implementation PingRequest
@end

@interface SensorType : NSObject
// Data class for a sensor

@property NSUInteger sensorTypeId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *unit;
@property (nonatomic, strong) NSString *desc;

@end
@implementation SensorType
@end


@implementation Buoy

- (instancetype)init {
    self = [super init];
    if (self) {
        _group = nil;
        _coordinate = CLLocationCoordinate2DMake(0, 0);
        _trueCoord = CLLocationCoordinate2DMake(0, 0);
        _validCoordinate = NO;
        _title = @"Unknown";
        _subtitle = @"Unknown";
        _dateCreated = [NSDate dateWithTimeIntervalSince1970:0];
        _buoyName = @"N/A";
        _buoyGuid = @"N/A";
        _buoyId = -1;
        _databaseId = -1;
    }
    return self;
}

- (instancetype)initWithCoord:(CLLocationCoordinate2D)coord {
    self = [self init];
    if (self) {
        _coordinate = CLLocationCoordinate2DMake([DataModel addJitter:coord.latitude withMax:0.005], [DataModel addJitter:coord.longitude withMax:0.005]);
        _trueCoord = coord;
        _validCoordinate = YES;
    }
    return self;
}

- (void)setGroup:(BuoyGroup *)group {
    _group = group;
    
    if (group != nil) {
        self.subtitle = group.title;
    } else {
        self.subtitle = @"Ungrouped";
    }
}

@end


@implementation BuoyGroup

- (instancetype)init {
    self = [super init];
    if (self) {
        _buoys = [[NSMutableArray alloc] init];
        _title = @"Unknown Group";
        _groupId = -1;
        
    }
    return self;
}
@end

@interface DataModel ()

// Login info
@property (strong, nonatomic) NSString *jwt;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *role;
@property BOOL configClearance;

// Loaded data
@property (strong, nonatomic) NSArray *sensorTypes;
@property (strong, nonatomic) NSNumber *pingCommandId;

// Misc
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end


@implementation DataModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _jwt = _email = _firstName = _lastName = _role = nil;
        _configClearance = NO;
        _sensorTypes = [NSArray array];
        _pingCommandId = nil;
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZZ"];
    }
    return self;
}

#pragma mark - server connection

- (NSURL *)getServerUrl {
    // Return the server url specified by the current settings
    NSString *address = [[NSUserDefaults standardUserDefaults] objectForKey:@"ServerAddress"];
    if (address == nil) {
        NSLog(@"Saved server address could not be found; using default");
        address = FMS_DEFAULT_SERVER_ADDRESS;
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@", address]];
}

- (void)sendRequestToServerUrl:(NSString *)relPath textData:(NSString *)requestString method:(NSString *)method authorization:(BOOL)authorization handler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))handler {
    
    // Get request info
    NSURL *postUrl = [NSURL URLWithString:relPath relativeToURL:[self getServerUrl]];
    NSData *postData = [requestString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLen = [NSString stringWithFormat:@"%lu", (unsigned long)requestString.length];
    
    // Create request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:postUrl];
    request.allowsCellularAccess = YES;
    request.HTTPMethod = method;
    request.HTTPBody = postData;
    if (authorization && self.jwt != nil) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", self.jwt] forHTTPHeaderField:@"Authorization"];
    } else {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:postLen forHTTPHeaderField:@"Content-Length"];
    }
    
    // Send request
    NSLog(@"Sending request: %@\n body %@ %@", request, method, requestString);
     for (NSString *header in [[request allHTTPHeaderFields] allKeys]) {
     NSLog(@"header %@: %@", header, [request allHTTPHeaderFields][header]);
     }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:handler] resume];
}

- (void)getCommandInfo {
    // Get the list of commands with their id so we can know what to send
    
    [self sendRequestToServerUrl:@"api/command_types" textData:@"" method:@"GET" authorization:YES handler:
     ^(NSData *data, NSURLResponse *response, NSError *error){
         @try {
             // Interpret their response
             NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
             if (!error && httpRes.statusCode == 200) { //Success
                 // Get command info
                 NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                 
                 // Get command array
                 NSLog(@"%@", res);
                 NSArray *commandTypes = res[@"commandTypes"];
                 if (commandTypes == nil || commandTypes.count < 1)
                     [NSException raise:@"Bad readings" format:@"readings is bad"];
                 
                 // Find ping command
                 for (NSDictionary *d in commandTypes) {
                     if (d == nil)
                         continue;
                     
                     NSNumber *commandId = d[@"id"];
                     NSString *commandName = d[@"name"];
                     if (commandId == nil || commandName == nil)
                         continue;
                     
                     NSLog(@"Found command type %@ with name %@", commandId, commandName);
                     if ([commandName isEqualToString:@"ping"])
                         self.pingCommandId = commandId;
                 }
             } else {
                 [NSException raise:@"Failed request" format:@"%@", httpRes];
             }
         } @catch (NSException *e) {
             NSLog(@"%@", e);
             [self.dataDelegate performSelectorOnMainThread:@selector(didFailServerComms) withObject:nil waitUntilDone:NO];
         }
     }];
}

- (void)getSensorTypeInfo {
    // Get the list of names and units for sensor types
    
    [self sendRequestToServerUrl:@"api/sensor_types" textData:@"" method:@"GET" authorization:YES handler:
     ^(NSData *data, NSURLResponse *response, NSError *error){
         @try {
             // Interpret their response
             NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
             if (!error && httpRes.statusCode == 200) { //Success
                 // Get command info
                 NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                 
                 // Get command array
                 NSLog(@"%@", res);
                 NSArray *sensorTypes = res[@"sensorTypes"];
                 if (sensorTypes == nil || sensorTypes.count < 1)
                     [NSException raise:@"Bad readings" format:@"readings is bad"];
                 
                 // Find ping command
                 NSArray *sensorList = [NSArray array];
                 for (NSDictionary *d in sensorTypes) {
                     if (d == nil)
                         continue;
                     
                     NSNumber *sensorId = d[@"id"];
                     NSString *sensorName = d[@"name"];
                     NSString *sensorUnit = d[@"unit"];
                     NSString *sensorDesc = d[@"description"];
                     if (sensorId == nil || sensorName == nil || sensorUnit == nil || sensorDesc == nil)
                         continue;
                     
                     NSLog(@"Found sensor type %@ with name %@", sensorId, sensorName);
                     SensorType *s = [[SensorType alloc] init];
                     s.sensorTypeId = sensorId.integerValue;
                     s.name = sensorName;
                     s.unit = sensorUnit;
                     s.desc = sensorDesc;
                     
                     sensorList = [sensorList arrayByAddingObject:s];
                 }
                 
                 self.sensorTypes = sensorList;
             } else {
                 [NSException raise:@"Failed request" format:@"%@", httpRes];
             }
         } @catch (NSException *e) {
             NSLog(@"%@", e);
             [self.dataDelegate performSelectorOnMainThread:@selector(didFailServerComms) withObject:nil waitUntilDone:NO];
         }
     }];
}

#pragma mark - parsing/data methods

- (BOOL)parseJSONForUserLogin:(NSDictionary *)userInfo {
    // Given a dictionary response to a user login, sets all class properties for a user login as necessary, returning false for a bad login (one without a token)
    self.jwt = userInfo[@"token"];
    if (self.jwt == nil) {
        return NO;
    }
    
    self.email = userInfo[@"email"];
    self.firstName = userInfo[@"firstName"];
    self.lastName = userInfo[@"lastName"];
    self.role = userInfo[@"role"];
    if (self.role != nil && ([self.role isEqualToString:@"power_user"] || [self.role isEqualToString:@"system_admin"])) {
        self.configClearance = YES;
    } else {
        self.configClearance = NO;
    }
    
    return YES;
}

- (NSArray *)parseJSONForCurrentBuoys:(NSArray *)buoyDictList {
    // Given a list of buoy dictionaries retrieved from the server, generates buoy and buoy group objects and returns an array of these buoy group objects
    // Buoys and BuoyGroups are mixed in the results; any buoys not in a group are by themselves, while those which are are inserted into the buoy groups arrays.
    NSMutableArray *parsed = [[NSMutableArray alloc] initWithCapacity:buoyDictList.count];
    for (NSDictionary *buoyInfo in buoyDictList) {
        // Get lat, long
        NSObject *latInfo = buoyInfo[@"latitude"];
        NSObject *lonInfo = buoyInfo[@"longitude"];
        
        // Create buoy
        Buoy *b;
        if ([latInfo isKindOfClass:[NSNumber class]] && [lonInfo isKindOfClass:[NSNumber class]]) {
            NSNumber *lat = (NSNumber *)latInfo;
            NSNumber *lon = (NSNumber *)lonInfo;
            b = [[Buoy alloc] initWithCoord:CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue)];
        } else if ([latInfo isKindOfClass:[NSDictionary class]] && [lonInfo isKindOfClass:[NSDictionary class]]) {
            NSDictionary *latDict = (NSDictionary *)latInfo;
            NSDictionary *lonDict = (NSDictionary *)lonInfo;
            NSNumber *lat = latDict[@"Float64"];
            NSNumber *lon = lonDict[@"Float64"];
            NSNumber *latValid = latDict[@"Valid"];
            NSNumber *lonValid = lonDict[@"Valid"];
            if (lat != nil && lon != nil && latValid != nil && lonValid != nil && latValid.intValue == 1 && lonValid.intValue == 1) {
                b = [[Buoy alloc] initWithCoord:CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue)];
            } else {
                b = [[Buoy alloc] init];
            }
        } else {
            b = [[Buoy alloc] init];
        }
        
        // Set indiv. properties
        NSString *buoyGuid = buoyInfo[@"buoyGuid"];
        NSNumber *buoyId = buoyInfo[@"buoyId"];
        NSString *buoyName = buoyInfo[@"buoyName"];
        NSString *dateCreated = buoyInfo[@"dateCreated"];
        NSNumber *databaseId = buoyInfo[@"id"];
        NSString *name = buoyInfo[@"name"];
        if (buoyGuid != nil) b.buoyGuid = buoyGuid;
        if (buoyId != nil) b.buoyId = buoyId.integerValue;
        if (buoyName != nil) b.buoyName = buoyName;
        if (dateCreated != nil) b.dateCreated = [_dateFormatter dateFromString:dateCreated];
        if (databaseId != nil) b.databaseId = databaseId.integerValue;
        if (name != nil) b.title = name;
        
        // Get group id to put under
        NSNumber *groupId = buoyInfo[@"buoyGroupId"];
        if (groupId == nil) groupId = [NSNumber numberWithInteger:0];
        
        // Find group for this id
        BuoyGroup *groupForBuoy = nil;
        for (BuoyGroup *g in parsed) {
            if (g.groupId == groupId.integerValue) {
                groupForBuoy = g;
            }
        }
        
        // If not there, create it and add to list of all groups
        if (groupForBuoy == nil) {
            groupForBuoy = [[BuoyGroup alloc] init];
            groupForBuoy.groupId = groupId.integerValue;
            if (groupId.integerValue == 0) {
                groupForBuoy.title = @"-";
            } else {
                NSString *groupName = buoyInfo[@"buoyGroupName"];
                if (groupName != nil) {
                    if (groupName.length == 0) {
                        groupForBuoy.title = @"(blank)";
                    } else {
                        groupForBuoy.title = groupName;
                    }
                }
            }
            [parsed addObject:groupForBuoy];
        }
        
        // Add buoy to this group
        b.group = groupForBuoy;
        [groupForBuoy.buoys addObject:b];
    }
    
    return parsed;
}

- (NSDictionary *)parseJSONForBuoyInfo:(NSArray *)readings {
    // Given a list of readings from a 'latest reading' request, generates a formatted dictionary linking their formatted names with values
    // Returns nil if invalid
    if (readings == nil || ![readings isKindOfClass:[NSArray class]])
        return nil;
    
    // Empty reading list
    if (readings.count == 0)
        return [NSDictionary dictionary];
    
    // Get sensor readings
    NSDictionary *latest = readings[0];
    NSNumber *timestamp = latest[@"timestamp"];
    NSArray *sensorReadings = latest[@"sensorReadings"];
    if (sensorReadings == nil)
        return nil;
    
    // For each of these readings, add them to the overall dict
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (NSDictionary *reading in sensorReadings) {
        NSNumber *sensorTypeID = reading[@"sensorTypeId"];
        NSNumber *value = reading[@"value"];
        if (sensorTypeID == nil || value == nil)
            continue;
        
        // Get sensor type for this
        SensorType *sensor = nil;
        for (SensorType *s in self.sensorTypes) {
            if (s.sensorTypeId == sensorTypeID.integerValue) {
                sensor = s;
                break;
            }
        }
        if (sensor == nil)
            continue; // Only display sensors we understand
        
        [dict setObject:[NSString stringWithFormat:@"%@%@", value.stringValue, sensor.unit] forKey:sensor.name];
    }
    
    // Handle timestamp, if it exists
    if (timestamp) {
        [dict setObject:timestamp forKey:@"ts"];
    }
    
    return dict;
}

- (void)repeatPingDataReq:(NSObject *)req {
    // Allow both timer and ping request objects
    PingRequest *p;
    if ([req isKindOfClass:[PingRequest class]]) {
        p = (PingRequest *)req;
    } else if ([req isKindOfClass:[NSTimer class]]) {
        p = ((NSTimer *)req).userInfo;
    } else {
        return;
    }
    
    // Ensure attempts remain
    p.timesRemaining--;
    if (p.timesRemaining == 0) {
        [self.dataDelegate didTimeoutPing:p.buoy];
        return;
    }
    
    // Send a server api request for buoy info
    NSString *addr = [NSString stringWithFormat:@"api/commands/%lu", (unsigned long)p.commandId];
    [self sendRequestToServerUrl:addr textData:@"" method:@"GET" authorization:YES handler:
     ^(NSData *data, NSURLResponse *response, NSError *error){
         @try {
             // Interpret their response
             NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
             if (!error && httpRes.statusCode == 200) { //Success
                 // Get buoy info
                 NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                 
                 // Get command ID array
                 NSLog(@"%@", res);
                 NSNumber *sent = res[@"sent"];
                 NSDictionary *sentAt = res[@"sentAt"];
                 if (sent == nil || sentAt == nil) {
                     [NSException raise:@"Bad sent" format:@"sent is bad"];
                 }
                 
                 // See if sent is true and get time
                 if (sent.intValue != 0) {
                     // Got value!
                     NSString *timeStr = sentAt[@"Time"];
                     NSString *createdT = res[@"createdAt"];
                     if (timeStr == nil || createdT == nil) {
                         [NSException raise:@"Bad time" format:@""];
                     }
                     // Get time sent
                     NSDate *createdTime = [_dateFormatter dateFromString:createdT];
                     NSDate *timeSent = [_dateFormatter dateFromString:timeStr];
                     NSTimeInterval timeTaken = [timeSent timeIntervalSinceDate:createdTime];
                     [self.dataDelegate didGetPingDataWithPing:timeTaken forBuoy:p.buoy];
                 } else {
                     // Resend after a delay
                     [self performSelectorOnMainThread:@selector(nextPingReqCycle:) withObject:p waitUntilDone:NO];
                 }
             } else {
                 [NSException raise:@"Failed request" format:@"%@", httpRes];
             }
         } @catch (NSException *e) {
             NSLog(@"%@", e);
             [self.dataDelegate performSelectorOnMainThread:@selector(didServerErrorPing:) withObject:p.buoy waitUntilDone:NO];
         }
     }];
}

- (void)nextPingReqCycle:(PingRequest *)p {
    [NSTimer scheduledTimerWithTimeInterval:FMS_PING_SPACE_BETWEEN_TRIES target:self selector:@selector(repeatPingDataReq:) userInfo:p repeats:NO];
}


#pragma mark - external methods

- (void)connectToServerWithEmail:(NSString *)email andPass:(NSString *)password {
    NSString *dataToSend = [NSString stringWithFormat:@" { \"email\" : \"%@\", \"password\" : \"%@\" } ", email, password];
    
    // Send a server api request to logon
    [self sendRequestToServerUrl:@"api/login" textData:dataToSend method:@"POST" authorization:NO handler:
     ^(NSData *data, NSURLResponse *response, NSError *error){
         if (error) {
             [self.delegate performSelectorOnMainThread:@selector(didFailToConnectServerNotFound) withObject:nil waitUntilDone:NO];
             return;
         }
         
         // Interpret their response
         NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
         if (httpRes.statusCode == 401 || httpRes.statusCode == 403) { //Unauthorised
             [self.delegate performSelectorOnMainThread:@selector(didFailToConnectBadDetails) withObject:nil waitUntilDone:NO];
         } else if (httpRes.statusCode == 200) { //Success
             // Get user info
             NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             if ([self parseJSONForUserLogin:user]) {
                 [self.delegate performSelectorOnMainThread:@selector(didConnectToServer) withObject:nil waitUntilDone:NO];
                 
                 // Kick off extraneous data readings
                 if (self.configClearance) {
                    [self performSelectorOnMainThread:@selector(getCommandInfo) withObject:nil waitUntilDone:NO];
                 }
                 [self performSelectorOnMainThread:@selector(getSensorTypeInfo) withObject:nil waitUntilDone:NO];
             } else {
                 [self.delegate performSelectorOnMainThread:@selector(didFailToConnectServerFail) withObject:nil waitUntilDone:NO];
             }
         } else { //Server failure
             [self.delegate performSelectorOnMainThread:@selector(didFailToConnectServerFail) withObject:nil waitUntilDone:NO];
         }
     }];
}

- (void)updateBuoyListingFromServer {
    // Send a server api request to logon
    [self sendRequestToServerUrl:@"api/buoy_instances?active=true" textData:@"" method:@"GET" authorization:YES handler:
     ^(NSData *data, NSURLResponse *response, NSError *error){
         // Interpret their response
         NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
         if (!error && httpRes.statusCode == 200) { //Success
             // Get buoy info
             NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             
             NSLog(@"%@", res);
             NSArray *buoyGroups = [self parseJSONForCurrentBuoys:res[@"buoyInstances"]];
             
             [self.dataDelegate performSelectorOnMainThread:@selector(didGetBuoyListFromServer:) withObject:buoyGroups waitUntilDone:NO];
         } else { //Server failure
             [self.dataDelegate performSelectorOnMainThread:@selector(didFailServerComms) withObject:nil waitUntilDone:NO];
         }
     }];
}

- (void)requestBuoyInfo:(Buoy *)buoy {
    // Send a server request for data
    NSString *addr = [NSString stringWithFormat:@"api/buoy_instances/%lu/readings?last=true", (unsigned long)buoy.databaseId];
    [self sendRequestToServerUrl:addr textData:@"" method:@"GET" authorization:YES handler:
     ^(NSData *data, NSURLResponse *response, NSError *error){
         @try {
             // Interpret their response
             NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
             if (!error && httpRes.statusCode == 200) { //Success
                 // Get buoy info
                 NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                 
                 // Get command ID array
                 NSLog(@"%@", res);
                 NSDictionary *namesWithValues = [self parseJSONForBuoyInfo:res[@"readings"]];
                 if (namesWithValues == nil) {
                     [NSException raise:@"Bad readings" format:@"readings is bad"];
                 }
                 
                 
                 // Return it
                 [self.dataDelegate didGetBuoyInfoFromServer:namesWithValues forBuoy:buoy];
             } else {
                 [NSException raise:@"Failed request" format:@"%@", httpRes];
             }
         } @catch (NSException *e) {
             NSLog(@"%@", e);
             [self.dataDelegate performSelectorOnMainThread:@selector(didFailBuoyInfoForBuoy:) withObject:buoy waitUntilDone:NO];
         }
     }];
}

- (void)getPingDataFor:(Buoy *)buoy {
    // Error if no ping command ID loaded
    if (self.pingCommandId == nil)
        [self.dataDelegate didServerErrorPing:buoy];
    
    // Create new ping request, and start polling for a ping response this many times
    PingRequest *p = [[PingRequest alloc] init];
    p.startTime = [NSDate date];
    p.timesRemaining = FMS_PING_TRIES;
    p.buoy = buoy;
    
    // Send a POST command to add a new ping command
    NSString *addr = [NSString stringWithFormat:@"api/buoys/%lu/commands", (unsigned long)buoy.buoyId];
    NSString *dataToSend = [NSString stringWithFormat:@" { \"commands\" : [ {\"commandTypeId\" : %@, \"value\" : 0} ] } ", self.pingCommandId];
    [self sendRequestToServerUrl:addr textData:dataToSend method:@"POST" authorization:YES handler:
     ^(NSData *data, NSURLResponse *response, NSError *error){
         @try {
             // Interpret their response
             NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
             if (!error && httpRes.statusCode == 201) { //Success
                 // Get buoy info
                 NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                 
                 // Get command ID array
                 NSLog(@"%@", res);
                 NSArray *commandIds = res[@"commandIds"];
                 if (commandIds == nil || commandIds.count != 1) {
                     [NSException raise:@"Bad count" format:@"count is bad"];
                 }
                 
                 // Get id we want
                 NSNumber *commandId = commandIds[0];
                 if (commandId == nil) {
                     [NSException raise:@"Bad command ID" format:@""];
                 }
                 
                 // Start sending for id
                 p.commandId = commandId.integerValue;
                 NSTimer *send = [NSTimer timerWithTimeInterval:0 target:self selector:@selector(nextPingReqCycle:) userInfo:p repeats:NO];
                 [self performSelectorOnMainThread:@selector(repeatPingDataReq:) withObject:send waitUntilDone:NO];
             } else {
                 [NSException raise:@"Failed request" format:@"%@", httpRes];
             }
         } @catch (NSException *e) {
             NSLog(@"%@", e);
             [self.dataDelegate performSelectorOnMainThread:@selector(didServerErrorPing:) withObject:p.buoy waitUntilDone:NO];
         }
     }];
}

- (void)disconnect {
    self.jwt = self.email = self.firstName = self.lastName = self.role = nil;
}

- (NSString *)userDisplayName {
    // First name exists
    if (self.firstName != nil && self.firstName.length > 0) {
        if (self.lastName != nil && self.lastName.length > 0) {
            return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
        } else {
            return self.firstName;
        }
    }
    
    // Last name only
    if (self.lastName != nil && self.lastName.length > 0) {
        return self.lastName;
    }
    
    // Use email otherwise, if it exists
    if (self.email != nil && self.email.length > 0) {
        return self.email;
    }
    
    // Else unknown way to display name
    return @"User";
}

- (BOOL)hasConfigClearance {
    return self.configClearance;
}

#pragma mark - static methods
+ (BOOL)NSStringIsValidEmail:(NSString *)s {
    NSString *regex = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [test evaluateWithObject:s];
}

+ (NSString *)stringForLatitude:(CLLocationDegrees)latitude {
    if (latitude > 0) { // North of equator
        return [NSString stringWithFormat:@"%.2f°N", latitude];
    } else if (latitude < 0) { // South
        return [NSString stringWithFormat:@"%.2f°S", -latitude];
    } else {
        return @"0°";
    }
}

+ (NSString *)stringForLongitude:(CLLocationDegrees)longitude {
    if (longitude > 0) { // East of london
        return [NSString stringWithFormat:@"%.2f°E", longitude];
    } else if (longitude < 0) { // West
        return [NSString stringWithFormat:@"%.2f°W", -longitude];
    } else {
        return @"0°";
    }
}

+ (double)addJitter:(double)val withMax:(double)maxVal{
    NSInteger jitter = arc4random() % 10000;
    return val + (jitter - 5000)/10000.0*maxVal;
}

@end
