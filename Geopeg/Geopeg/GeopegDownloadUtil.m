//
//  GeopegDownloadUtil.m
//  Geopeg
//
//  Created by Louis on 6/21/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "GeopegDownloadUtil.h"

@implementation GeopegDownloadUtil

+ (AWSTask *)requestImageDataForLocation:(NSString *)mgrsid size:(NSNumber *)size startDate:(NSString *)startDate currentMGRS:(NSString *)currentMGRS {
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"mgrsid=%@&startdate=%@&size=%d", mgrsid, startDate, [size intValue]];
    
    if (currentMGRS != nil) {
        
        post = [post stringByAppendingString:[NSString stringWithFormat:@"&user_mgrsid=%@", currentMGRS]];
        
    }
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"download.php"];
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [[GeopegUtil makeAsyncRequest:request] continueWithBlock:^id(AWSTask *task) {
        
        if (task.error) {
            
            // If error in request, just pass it along and do no more.
            [taskSource setError:task.error];
            return nil;
            
        }
        
        NSDictionary *json = task.result;
        
        [taskSource setResult:json[@"Results"]];
        
        return nil;
        
    }];
    
    return taskSource.task;

}

+ (AWSTask *)requestSelfImageDataWithStartDate:(NSString *)startDate {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"username=%@&token=%@&startdate=%@", IP.username, IP.geopegToken, startDate];
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"selfdownload.php"];
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [[GeopegUtil makeAsyncRequest:request] continueWithBlock:^id(AWSTask *task) {
        
        if (task.error) {
            
            [taskSource setError:task.error];
            return nil;
            
        }
        
        NSDictionary *json = task.result;
        
        [taskSource setResult:json[@"Results"]];
        
        return nil;
        
    }];
    
    return taskSource.task;

}

+ (AWSTask *)uploadImageDataWithS3Path:(NSString *)s3path mgrsid:(NSString *)mgrsid caption:(NSString *)caption {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"username=%@&token=%@&s3path=%@&mgrsid=%@&caption=%@", IP.username, IP.geopegToken, s3path, mgrsid, caption];
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"upload.php"];
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [[GeopegUtil makeAsyncRequest:request] continueWithBlock:^id(AWSTask *task) {
        
        if (task.error) {
            
            [taskSource setError:task.error];
            return nil;
            
        }
        
        [taskSource setResult:GP_SUCCESS];
        
        return nil;
        
    }];
    
    return taskSource.task;
    
}

@end
