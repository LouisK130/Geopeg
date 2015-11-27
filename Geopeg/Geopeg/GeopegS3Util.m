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

+ (NSString *)generateRandomS3Path {
    
    // Make our string
    NSMutableString *random = [NSMutableString stringWithCapacity: 30];
    
    // Loop and add random characters one at a time to proper length
    for (int i=0; i<30; i++) {
        
        [random appendFormat:@"%C", [letters characterAtIndex:arc4random() % [letters length]]];
        
    }
    
    // return the string
    return random;
    
}

+ (BOOL)copyFileToCacheFromURL:(NSURL *)url withNewName:(NSString *)newName {
    
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

+ (AWSTask *) uploadGeopegWithURL:(NSURL *) url {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    NSString *extension = [@"." stringByAppendingString:[url pathExtension]];
    
    NSString *userId = IP.geopegId;
    NSString *pegID = [[GeopegS3Util generateRandomS3Path] stringByAppendingString:extension];
    NSString *s3Path = [[IP.identityId stringByAppendingString:@"/"] stringByAppendingString:pegID];
    
    NSString *newName = [[userId stringByAppendingString:@"_"] stringByAppendingString:pegID];
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = s3Bucket;
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
            
            [GeopegS3Util copyFileToCacheFromURL:url withNewName:newName];
            
            [taskSource setResult:GP_SUCCESS];
        }
        
        return nil;
        
    }];
    
    return taskSource.task;
    
}

+ (AWSTask *) downloadGeopegFromS3Path:(NSString *) path {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    // Let's build a file system path from our s3path
    // Only '/' in the s3path divides awsId from pegId, so split at that
    NSArray *pathParts = [path componentsSeparatedByString:@"/"];
    
    NSURL *cachesDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    NSString *fileName = [[IP.geopegId stringByAppendingString:@"_"] stringByAppendingString:pathParts[1]];
    NSURL *filePath = [cachesDir URLByAppendingPathComponent:fileName];
    
    AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
    
    downloadRequest.bucket = s3Bucket;
    downloadRequest.key = path;
    downloadRequest.downloadingFileURL = filePath;
    
    AWSS3TransferManager *tm = [AWSS3TransferManager defaultS3TransferManager];
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [[tm download:downloadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor] withBlock:^id(AWSTask *task) {
        
        if (task.error) {
            
            NSLog(@"download error: %@", task.error);
            
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                
                switch (task.error.code) {
                        
                    case AWSS3TransferManagerErrorCancelled:
                    case AWSS3TransferManagerErrorPaused:
                        break;
                        
                    default:
                        NSLog(@"Error downloading: %@", task.error);
                        break;
                        
                }
                
            }
            
            else {
                
                NSLog(@"Error downloading: %@", task.error);
                
            }
            
            [taskSource setError:task.error];
            
        }
        
        NSLog(@"Downloaded to: %@", filePath);
        
        [taskSource setResult:task.result];
        return nil;
        
    }];
    
    return taskSource.task;
}

+ (AWSTask *)deleteGeopegFromS3Path:(NSString *) path {
    
    AWSS3DeleteObjectRequest *deleteRequest = [AWSS3DeleteObjectRequest new];
    deleteRequest.key = path;
    deleteRequest.bucket = s3Bucket;
    
    AWSS3 *s3 = [AWSS3 defaultS3];
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [[s3 deleteObject:deleteRequest] continueWithBlock:^id(AWSTask *task) {
        
        if (task.error) {
            
            [taskSource setError:task.error];
            
        }
        
        [taskSource setResult:task.result];
        
        return nil;
        
    }];
    
    return taskSource.task;
    
}

@end
