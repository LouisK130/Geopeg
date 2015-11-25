//
//  GeopegS3Util.m
//  Geopeg
//
//  Created by Louis on 8/4/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "GeopegS3Util.h"

@implementation GeopegS3Util

static GeopegS3Util *_sharedInstance;

- (id) init {
    
    return self;
    
}

+ (GeopegS3Util *) sharedInstance {
    
    if(!_sharedInstance) {
        
        _sharedInstance = [[GeopegS3Util alloc] init];
        
    }
    
    return _sharedInstance;
    
}

- (NSString *)generateRandomS3Path {
    
    // Make our string
    NSMutableString *random = [NSMutableString stringWithCapacity: 30];
    
    // Loop and add random characters one at a time to proper length
    for (int i=0; i<30; i++) {
        
        [random appendFormat:@"%C", [letters characterAtIndex:arc4random() % [letters length]]];
        
    }
    
    // return the string
    return random;
    
}

- (BOOL)copyFileToCacheFromURL:(NSURL *)url withNewName:(NSString *)newName {
    
    NSLog(@"Copying and deleting file");
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSURL *cachesDir = [[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    
    bool result = [fm copyItemAtURL:url toURL:[cachesDir URLByAppendingPathComponent:newName] error:nil];
    
    if (!result) {
        
        return NO;
        
    }
    
    // If successful, delete old one
    [fm removeItemAtURL:url error:nil];
    
    return YES;
    
}

- (AWSTask *) uploadGeopegWithURL:(NSURL *) url {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    NSString *extension = [@"." stringByAppendingString:[url pathExtension]];
    
    NSString *userId = IP.geopegId;
    NSString *pegID = [[self generateRandomS3Path] stringByAppendingString:extension];
    NSString *s3Path = [[IP.identityId stringByAppendingString:@"/"] stringByAppendingString:pegID];
    
    NSString *newName = [[userId stringByAppendingString:@"_"] stringByAppendingString:pegID];
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = @"geopegbucket";
    uploadRequest.body = url;
    uploadRequest.key = s3Path;
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    AWSS3TransferManager *tm = [AWSS3TransferManager defaultS3TransferManager];
    
    [[tm upload:uploadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor] withBlock:^id(AWSTask *task) {
        
        if (task.error) {
            
            [taskSource setError:task.error];
            
        }
        
        if (task.result) {
            
            // It worked!
            // Lets get rid of the image/video and cache it
            
            [self copyFileToCacheFromURL:url withNewName:newName];
            
            [taskSource setError:GP_SUCCESS];
        }
        
        return nil;
        
    }];
    
    return taskSource.task;
    
}

@end
