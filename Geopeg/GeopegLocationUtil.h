//
//  GeopegLocationUtil.h
//  Geopeg
//
//  Created by Louis on 5/23/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <complex.h>
#import <CoreLocation/CoreLocation.h>

@interface GeopegLocationUtil : NSObject <CLLocationManagerDelegate> {
    
    @public CLLocationManager *locationManager;
    
    @private NSDictionary *latZones;
    @private NSArray *mgrsCharSequence;
    @private CLLocation *currentLocation;
    
}

+ (GeopegLocationUtil *) sharedInstance;

- (NSDictionary *) toUTMFromLat:(double) lat Lon:(double) lon;

- (BOOL) validateLat:(double) lat Lon:(double) lon;

- (NSString *) toMGRSFromUTMWithZone:(int) lonZone latZone:(NSString *) latZone easting:(double) easting northing:(double) northing;

- (NSString *) toMGRSFromLat:(double) lat Lon:(double) lon;

- (NSString *) getCurrentMGRSLocation;

- (NSDictionary *) toLatLonFromUTMWithZone:(int) utmZone easting:(double) easting northing:(double) northing;

@end
