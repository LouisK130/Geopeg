//
//  GeopegS3Util.h
//  Geopeg
//
//  Created by Louis on 8/4/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>
#import <AWSCore/AWSCore.h>
#import "GeopegUtil.h"

static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

@interface GeopegS3Util : NSObject

+ (GeopegS3Util *) sharedInstance;

- (NSString *)generateRandomS3Path;

// Takes a saved image or video and copies to Library/Caches
// Also renames it a random 10 length string
// Returns success bool

- (BOOL)copyFileToCacheFromURL:(NSURL *) url withNewName:(NSString *) newName;

- (AWSTask *) uploadGeopegWithURL:(NSURL *) url;

@end
