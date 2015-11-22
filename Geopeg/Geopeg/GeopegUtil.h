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
#import <AWSCore/AWSCore.h>
#import "GeopegIdentityProvider.h"
#import "FDKeychain.h"

typedef enum GeopegErrorCodes {GP_SUCCESS, GP_CONNECTION_FAILURE, GP_INTERNAL_ERROR, GP_JSONPARSE_FAILURE,
                                GP_INVALID_CREDENTIALS} GeopegErrorCodes;

@interface GeopegUtil : NSObject {
    
@public AWSCognitoCredentialsProvider *cp;
    
}

// Set and get the aws creds provider object using singleton logic

+ (AWSCognitoCredentialsProvider *)getCredsProvider;

+ (void)setCredsProvider:(AWSCognitoCredentialsProvider *)newCp;

// Does some basic setup to make a URL request

+ (NSMutableURLRequest *)formatConnectionWithPostString:(NSString *)post filePath:(NSString *)path;

// Attempts to parse some assumed JSON data into an NSDictionary

+ (NSDictionary *)parseJSONResponse:(NSData *) data;

// Saves above values to disk for later use
// Returns YES on success, NO on failure

+ (BOOL)saveUserValues;

// Loads above values from disk to memory
// Returns YES on success, NO on failure

+ (BOOL)loadUserValues;

// Creates a standard alert that says Ok

+ (UIAlertController *)createOkAlertWithTitle:(NSString *) title message:(NSString *) message;



@end
