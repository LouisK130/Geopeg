//
//  GeopegUtil.h
//  Geopeg
//
//  Created by Louis on 5/16/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

// This is a "singleton" class.
// It stores some global values and methods for us
// Only one instance will ever exist

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GeopegUtil : NSObject {
    
    @public NSString *geopegToken;
    @public NSString *awsID;
    @public NSString *awsToken;
    @public NSString *username;
    @public NSString *email;
    
    enum GeopegRequestResult {
        GEOPEG_INVALID_CREDENTIALS = -2,
        GEOPEG_CONNECTION_FAILURE = -1,
        GEOPEG_FAILURE = 0,
        GEOPEG_SUCCESS = 1
    };
    
}

// Get the only available instance of this class

+ (GeopegUtil *) sharedInstance;

// Does some basic setup to make a URL request

- (NSMutableURLRequest *)formatConnectionWithPostString:(NSString *)post filePath:(NSString *)path;

// Attempts to parse some assumed JSON data into an NSDictionary

- (NSDictionary *)parseJSONResponse:(NSData *) data;

// Attempt to refresh AWS Token after expiration
// Note that username and geopegToken must be stored and valid also
// Calls the given function, passing a success indicator as first param (-1 = connection error, 0 = failure, 1 = success)

- (void)refreshAWSTokenWithBlock:(void (^) (NSNumber *)) block;

// Saves above values to disk for later use
// Returns YES on success, NO on failure

- (BOOL)saveUserValues;

// Loads above values from disk to memory
// Returns YES on success, NO on failure

- (BOOL)loadUserValues;

// Creates a standard alert that says Ok

- (UIAlertController *)createOkAlertWithTitle:(NSString *) title message:(NSString *) message;



@end
