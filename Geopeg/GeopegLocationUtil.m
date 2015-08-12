//
//  GeopegLocationUtil.m
//  Geopeg
//
//  Created by Louis on 5/23/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "GeopegLocationUtil.h"

@implementation GeopegLocationUtil

static GeopegLocationUtil *_sharedInstance;

- (id) init {
    
    if(self = [super init]) {
    
        self->latZones = [NSDictionary dictionaryWithObjectsAndKeys:
                      @"C", [NSNumber numberWithInt:-80],
                      @"D",[NSNumber numberWithInt:-72],
                      @"E",[NSNumber numberWithInt:-64],
                      @"F",[NSNumber numberWithInt:-56],
                      @"G",[NSNumber numberWithInt:-48],
                      @"H",[NSNumber numberWithInt:-40],
                      @"J",[NSNumber numberWithInt:-32],
                      @"K",[NSNumber numberWithInt:-24],
                      @"L",[NSNumber numberWithInt:-16],
                      @"M",[NSNumber numberWithInt:-8],
                      @"N",[NSNumber numberWithInt:0],
                      @"P",[NSNumber numberWithInt:8],
                      @"Q",[NSNumber numberWithInt:16],
                      @"R",[NSNumber numberWithInt:24],
                      @"S",[NSNumber numberWithInt:32],
                      @"T",[NSNumber numberWithInt:40],
                      @"U",[NSNumber numberWithInt:48],
                      @"V",[NSNumber numberWithInt:56],
                      @"W",[NSNumber numberWithInt:64],
                      @"X",[NSNumber numberWithInt:72],
                      nil];
    
        // For easting pattern this is accurate
        // For northing pattern, take off the last 4 letters
    
        self->mgrsCharSequence = @[
                              @"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"J",
                              @"K",@"L",@"M",@"N",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",
                              @"W",@"X",@"Y",@"Z"];
        
    }
    
    return self;
    
}

+ (GeopegLocationUtil *) sharedInstance {
    
    if (!_sharedInstance) {
        
        _sharedInstance = [[GeopegLocationUtil alloc] init];
        
    }
    
    return _sharedInstance;
    
}

// This method is called when location services gives us a new loctions

- (void)locationManager:(CLLocationManager *) manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *location = [locations lastObject];
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (fabs(howRecent) < 5) {
        
        currentLocation = location;
        
        if (location.horizontalAccuracy <= 10) {
            
            // We can restart it when the user next refreshes
            [manager stopUpdatingLocation];
            
        }
        
    }
    
}

- (NSString *) getCurrentMGRSLocation {
    
    if (!currentLocation || currentLocation.horizontalAccuracy > 100) {
        
        // We don't know location accurately enough to make MGRS
        return nil;
        
    }
    
    return [self toMGRSFromLat:currentLocation.coordinate.latitude Lon:currentLocation.coordinate.longitude];
    
}

// This function calls all the necessarry others to convert from Lat/Lon to an MGRS string

- (NSString *) toMGRSFromLat:(double) lat Lon:(double) lon {
    
    NSDictionary *utmVals = [self toUTMFromLat:lat Lon:lon];
    
    return [self toMGRSFromUTMWithZone:[[utmVals objectForKey:@"UTMZone"] intValue] latZone:[utmVals objectForKey:@"GZD"]
                               easting:[[utmVals objectForKey:@"Easting"] doubleValue] northing:[[utmVals objectForKey:@"Northing"] doubleValue]];
    
}

// Verifies that a certain Lat/Lon are valid for conversion to MGRS

- (BOOL) validateLat:(double) lat Lon:(double) lon {
    
    if (lat > 84 || lat < -80) {
        
        return NO;
        
    }
    
    if (lon < -180 || lon > 180) {
        
        return NO;
        
    }
    
    return YES;
    
}

// Converts UTM to Lat/Lon
// UTMZone should be negative if in the south

- (NSDictionary *) toLatLonFromUTMWithZone:(int) utmZone easting:(double)easting northing:(double)northing {
    
    // WGS84 Datum Values
    double A1 = 6378137.0;
    double F1 = 298.257223563;

    // Constants
    double D0 = 180/M_PI; // Rad to degress
    int maxiter = 100; // Max iteration for latitude computation // wtf is this
    double eps = 1e-11; // Min residue for latitude computation // wtf is this
    
    double K0 = 0.9996; // UTM Scale Factor
    double X0 = 500000; // UTM False Easting
    double Y0 = 1e7 * (utmZone < 0); // UTM False Northing
    double P0 = 0; // UTM Origin Latitude (rad)
    double L0 = (6 * abs(utmZone) - 183) / D0; // UTM Origin Longitude (rad)
    double E1 = sqrt(((pow(A1, 2) - pow(A1*(1 - 1/F1), 2)) / pow(A1, 2))); // ellipsoid eccentricity
    double N = K0 * A1;
    
    // Computing parameters for Mercator Transverse projection
    // I don't even know what that means
    NSArray *C = [self coef:E1 m:0];
    double YS = Y0 - N * ([C[0] doubleValue]*P0 + [C[1] doubleValue]*sin(2*P0) + [C[2] doubleValue]*sin(4*P0) + [C[3] doubleValue]*sin(6*P0) + [C[4] doubleValue]*sin(8*P0));
    
    C = [self coef:E1 m:1];
    
    complex double zt = (northing - YS) / N / [C[0] doubleValue] + (((easting - X0) / N / [C[0] doubleValue]) * I);
    complex double z = zt - [C[1] doubleValue]*sin(2*zt) - [C[2] doubleValue]*sin(4*zt) - [C[3] doubleValue]*sin(6*zt) - [C[4] doubleValue]*sin(8*zt);
    double L = creal(z);
    double LS = cimag(z);
    
    double l = L0 + atan(sinh(LS)/cos(L));
    
    double p = asin(sin(L)/cosh(LS));
    
    L = log(tan(M_PI/4 + p/2));
    
    // Calculates latitude from the isometric latitude ....?
    p = 2 * atan(exp(L) - M_PI/2);
    double p0 = NAN;
    int n = 0;
    while ((isnan(p0) || fabs(p - p0) > eps) && n < maxiter) {
        
        p0 = p;
        double es = E1*sin(p0);
        double a = pow((1 + es) / (1 - es), (E1/2));
        p = 2 * atan(a * exp(L)) - M_PI/2;
        n = n + 1;
        
    }
    
    double lat = p * D0;
    double lon = l * D0;
    
    NSMutableDictionary *coords = [[NSMutableDictionary alloc] init];
    coords[@"Latitude"] = [NSNumber numberWithDouble:lat];
    coords[@"Longitude"] = [NSNumber numberWithDouble:lon];
    
    return coords;
    
}

// Converts Lat/Lon to UTM string

- (NSDictionary *) toUTMFromLat:(double) Lat Lon:(double) Lon {
    
    if (![self validateLat:Lat Lon:Lon]) {
        
        return nil;
        
    }
    
    // Convert to radians
    
    double lat = Lat * M_PI / 180;
    double lon = Lon * M_PI / 180;
    
    // WGS84 values
    
    double a = 6378137; // semi-major axis in meters
    double b = 6356752.314245; // semi-minor axis in meters
    double e = sqrtf(1 - pow(b/a, 2)); // eccentricity
    double e2 = pow(e, 2); // Just e squared
    
    // UTM values
    
    double Lon0 = floor(Lon / 6) * 6 + 3; // Reference longitude, "0" in the UTM zone
    double lon0 = Lon0 * M_PI / 180; // In radians
    
    double k0 = 0.9996; // scale on central meridian ???
    double FE = 500000; // False easting
    double FN = (lat < 0) * 10000000; // False northing, 0 if north, 1e7 if south
    
    // Values for equations
    
    double eps = e2 / (1 - e2); // epsilon ???
    // N is the radius of curvature of the earth perpendicular to meridian plane
    // Also distance from point to polar axis
    double N = a / sqrt(1 - e2 * pow(sin(lat), 2));
    double T = pow(tan(lat), 2);
    double C = eps * pow(cos(lat), 2);
    double A = (lon-lon0) * cos(lat);
    // M is true distance along the central meridian from the equator to lat
    double M = a * ((1 - e2 / 4 - 3 * pow(e, 4) / 64 - 5 * pow(e, 6) / 256)     * lat
                    - (3 * e2 / 8 + 3 * pow(e, 4) / 32 + 45 * pow(e, 6) / 1024) * sin(2 * lat)
                    + (15 * pow(e, 4) / 256 + 45 * pow(e, 6) / 1024)            * sin(4 * lat)
                    - (35 * pow(e, 6) / 3072)                                   * sin(6 * lat));
    
    // Easting
    
    double x = FE + k0 * N * (A + (1-T+C) * pow(A, 3) / 6
        + (5 - (18 * T) + pow(T, 2) + (72 * C) - (58 * eps))
        * pow(A, 5) / 120 );
    
    // Northing
    
    double y = FN + k0 * M + k0 * N * tan(lat) * (
        pow(A, 2) / 2 + (5 - T + (9 * C) + (4 * pow(C, 2))) * pow(A, 4) / 24
        + (61 - (58 * T) + pow(T, 2) + (600 * C) - (330 * eps)) * pow(A, 6) / 720 );
    
    // UTM Zone
    
    int zone = floor(Lon0 / 6) + 31;
    
    // Handle exceptions
    
    NSString * latZone = [self latZoneFromLat:Lat];
    
    if (zone == 31 && [latZone isEqualToString:@"V"]) { // Norway
        
        if (Lat >= 3) {
            
            zone = 32;
            
        }
        
    }
    
    else if ([latZone isEqualToString:@"X"] && zone > 30 && zone < 38) { // Svalbard
        
        if (Lat < 9) {
            
            zone = 31;
            
        }
        else if (Lat < 21) {
            
            zone = 33;
            
        }
        else if (Lat < 33) {
            
            zone = 35;
            
        }
        else if (Lat < 42) {
            
            zone = 37;
            
        }
        
    }
    
    if (zone > 60) {
        
        zone = zone - 60;
        
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys: [NSString stringWithFormat:@"%d", zone], @"UTMZone",
            latZone, @"GZD", [NSNumber numberWithDouble:x], @"Easting", [NSNumber numberWithDouble:y], @"Northing", nil];
    
}

- (NSString *) latZoneFromLat:(double) lat {

    if (lat < 72) {
        
        int zoneNum = floor(lat / 8) * 8;
        return [self->latZones objectForKey:[NSNumber numberWithInt:zoneNum]];
        
    }
    else {
        
        return @"X";
        
    }
    
}

- (NSString *) toMGRSFromUTMWithZone:(int) utmZone latZone:(NSString *) latZone easting:(double) easting northing:(double) northing {
    
    // First find the set number for this zone
    
    int set = utmZone % 6;
    
    if (set == 0) { set = 6; }
    
    // Reduce easting to nearest 100,000 meters
    
    double redEasting = floor(easting / 100000) * 100000;
    
    // Reduce northing by multiples of 2,000,000 meters
    // Until between 0 and 2,000,000
    // Then reduce to nearest 100,000
    
    double scaledNorthing = northing - (floor(northing / 2000000) * 2000000);
    double redNorthing = floor(scaledNorthing / 100000) * 100000;
    
    // Now find the character that the easting corresponds to
    
    int startValue = -1; // First index is 0, so we compensate here
    
    if (set == 2 || set == 4) { startValue = 7; }
    else if (set == 3 || set == 6) { startValue = 15; }
    
    // redEasting / 100000 represents the index of the character in the sequence
    // For example:
    // 300000 / 100000 = 3, the third character in the sequence is c
    // 300000 corresponds with c
    
    // If we are in a different set, the sequence starts further in, for example
    // Set 2 starts at J, so the third character would be L
    
    NSString *eastingChar = [self->mgrsCharSequence objectAtIndex:(startValue + (redEasting / 100000))];
    
    // Now we do something similar for the northing character, but we
    // have to exclude the last 4 characters in the sequence
    
    NSMutableArray *northingSeq = [[NSMutableArray alloc] initWithArray:[self->mgrsCharSequence copy]];
    [northingSeq removeObjectsInRange:NSMakeRange(20, 4)];
    
    // Re-setup our start value
    
    startValue = 0; // Starts at A
    
    if (set == 2 || set == 4 || set == 6) { startValue = 5; }; // Starts at F
    
    int simpleNorthing = startValue + (redNorthing / 100000); // This is the char index we want
    
    // However, it may exceed the indexes of the charSequence, meaning we would need to restart at 0
    
    if (simpleNorthing > 19) {
        
        simpleNorthing = simpleNorthing - 20;
        
    }
    
    NSString *northingChar = [self->mgrsCharSequence objectAtIndex:simpleNorthing];
    
    // Add leading zero to utmZone if needed, for uniform string length
    
    NSString *utmZoneString = [NSString stringWithFormat:@"%d", utmZone];
    
    if ([utmZoneString length] == 1) {
        
        utmZoneString = [NSString stringWithFormat:@"0%d", utmZone];
        
    }
    
    // Now the easting and northing in our string are simply the remainders
    // Padded with trailing zeroes to a length of 5 (1m precision)
    
    NSString *eastingString = [NSString stringWithFormat:@"%d", (int)floor(easting - redEasting)];
    NSString *northingString = [NSString stringWithFormat:@"%d", (int)floor(scaledNorthing - redNorthing)];
    eastingString = [eastingString stringByPaddingToLength:5 withString:@"0" startingAtIndex:0];
    northingString = [northingString stringByPaddingToLength:5 withString:@"0" startingAtIndex:0];
    
    return [NSString stringWithFormat:@"%@%@%@%@%@%@", utmZoneString, latZone, eastingChar, northingChar, eastingString, northingString];
    
}

// Below here is helper functions for converting from UTM to lat/lon

// This one is some weird shit where m can be 0, 1, or 2
// 0 = transverse mercator values
// 1 = transverse mercator reverse values
// 2 = meridian arc
// e = first ellipsoid eccentricity

- (NSArray *)coef:(double)e m:(int)m {
    
    if (!m) {
        m = 0;
    }
    
    NSMutableArray *matrix = [NSMutableArray arrayWithObjects:@0, @0, @0, @0, @0, nil];
    
    switch (m) {
        case 0:
            matrix[0] = [NSArray arrayWithObjects:@(-175.0f/16384.0f), @0, @(-5.0f/256.0f), @0, @(-3.0f/64.0f), @0, @(-1.0f/4.0f), @0, @1, nil];
            matrix[1] = [NSArray arrayWithObjects:@(-105.0f/4096.0f), @0, @(-45.0f/1024.0f), @0, @(-3.0f/32.0f), @0, @(-3.0f/8.0f), @0, @0, nil];
            matrix[2] = [NSArray arrayWithObjects:@(525.0f/16384.0f), @0, @(-45.0f/1024.0f), @0, @(15.0f/256.0f), @0, @0, @0, @0, nil];
            matrix[3] = [NSArray arrayWithObjects:@(-175.0f/12288.0f), @0, @(-35.0f/3072.0f), @0, @0, @0, @0, @0, @0, nil];
            matrix[4] = [NSArray arrayWithObjects:@(315.0f/131072.0f), @0, @0, @0, @0, @0, @0, @0, @0, nil];
            break;
        case 1:
            matrix[0] = [NSArray arrayWithObjects:@(-175.0f/16384.0f), @0, @(-5.0f/256.0f), @0, @(-3.0f/64.0f), @0, @(-1.0f/4.0f), @0, @1, nil];
            matrix[1] = [NSArray arrayWithObjects:@(1.0f/61440.0f), @0, @(7.0f/2048.0f), @0, @(1.0f/48.0f), @0, @(1.0f/8.0f), @0, @0, nil];
            matrix[2] = [NSArray arrayWithObjects:@(559.0f/368640.0f), @0, @(3.0f/1280.0f), @0, @(1.0f/768.0f), @0, @0, @0, @0, nil];
            matrix[3] = [NSArray arrayWithObjects:@(283.0f/430080.0f), @0, @(17.0f/30720.0f), @0, @0, @0, @0, @0, @0, nil];
            matrix[4] = [NSArray arrayWithObjects:@(4397.0f/41287680.0f), @0, @0, @0, @0, @0, @0, @0, @0, nil];
        case 2:
            matrix[0] = [NSArray arrayWithObjects:@(-175.0f/16384.0f), @0, @(-5.0f/256.0f), @0, @(-3.0f/64.0f), @0, @(-1.0f/4.0f), @0, @1, nil];
            matrix[1] = [NSArray arrayWithObjects:@(-901.0f/184320.0f), @0, @(-9.0f/1024.0f), @0, @(-1.0f/96.0f), @0, @(1.0f/8.0f), @0, @0, nil];
            matrix[2] = [NSArray arrayWithObjects:@(-311.0f/737280.0f), @0, @(17.0f/5120.0f), @0, @(13.0f/768.0f), @0, @0, @0, @0, nil];
            matrix[3] = [NSArray arrayWithObjects:@(899.0f/430080.0f), @0, @(61.0f/15360.0f), @0, @0, @0, @0, @0, @0, nil];
            matrix[4] = [NSArray arrayWithObjects:@(49561.0f/41287680.0f), @0, @0, @0, @0, @0, @0, @0, @0, nil];
    }
    
    NSMutableArray *returns = [NSMutableArray arrayWithObjects:@0, @0, @0, @0, @0, nil];
    
    for (int i = 0; i < 5; i++) {
        
        returns[i] = [NSNumber numberWithDouble:[self polyvalWithCoefs:matrix[i] x:e]];
        
    }
        
    
    return returns;
}

- (double)polyvalWithCoefs:(NSArray *)coefs x:(double) x {
    
    int n = (int)[coefs count] - 1;
    
    double answer = 0;
    
    for (int i = 0; i < [coefs count]; i++) {
        
        double coef = [((NSNumber *)coefs[i]) doubleValue];
        
        answer = answer + (coef * pow(x, n));
        
        n--;
    }
    
    return answer;
    
}

@end
