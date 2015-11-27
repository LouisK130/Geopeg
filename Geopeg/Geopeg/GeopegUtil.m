//
//  GeopegUtil.m
//  Geopeg
//
//  Created by Louis on 5/16/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "GeopegUtil.h"

static GeopegUtil *_sharedInstance;

@implementation GeopegUtil

// This file only has class methods for util purposes

// This first method works as something of a singleton to maintain
// and distribute a reference to the AWS credentialsProvider object

+ (AWSCognitoCredentialsProvider *)getCredsProvider {
    
    if (!_sharedInstance) {
        
        _sharedInstance = [[GeopegUtil alloc] init];
        
    }
    
    return _sharedInstance->cp;
}

+ (void)setCredsProvider:(AWSCognitoCredentialsProvider *)newCp {
    
    if (!_sharedInstance) {
        
        _sharedInstance = [[GeopegUtil alloc] init];
        
    }
    
    _sharedInstance->cp = newCp;
    
}

+ (NSMutableURLRequest *)formatConnectionWithPostString:(NSString *)post filePath:(NSString *)path {
    
    // Converted to POST data
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    // Length of post data
    
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    
    // Create a request
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    // Set some parameters of the request
    
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"http://[2601:18e:c100:8444:2d2b:c807:a3f8:9feb]:8000/", path]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:30];
    
    return request;
}

+ (NSDictionary *)parseJSONResponse:(NSData *)data {
    
    // Parse it into JSON that we can work with
    
    NSError *jsonError;
    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (!jsonResponse) {
        NSLog(@"Error parsing JSON");
        return nil;
    }
    
    return jsonResponse;
    
}

+ (BOOL)saveUserValues {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    NSError *err1;
    NSError *err2;
    NSError *err3;
    
    [FDKeychain saveItem:IP.username forKey:@"username" forService:@"Geopeg" error:&err1];
    [FDKeychain saveItem:IP.geopegId forKey:@"geopegId" forService:@"Geopeg" error:&err2];
    [FDKeychain  saveItem:IP.geopegToken forKey:@"geopegToken" forService:@"Geopeg" error:&err3];
    
    if (!err1 && !err2 && !err3) {
        
        return YES;
        
    }
    
    return NO;
}

+ (BOOL)loadUserValues {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    NSError *err1;
    NSError *err2;
    NSError *err3;
    
    IP.username = [FDKeychain itemForKey:@"username" forService:@"Geopeg" error:&err1];
    IP.geopegId = [FDKeychain itemForKey:@"geopegId" forService:@"Geopeg" error:&err2];
    IP.geopegToken = [FDKeychain itemForKey:@"geopegToken" forService:@"Geopeg" error:&err3];
    
    if (!err1 && !err2 && !err3) {
        
        return YES;
        
    }
    
    return NO;
    
}

+ (UIAlertController *)createOkAlertWithTitle:(NSString *)title message:(NSString *)message {

    UIAlertController *alertCont = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAct = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    
    [alertCont addAction:okAct];
    
    return alertCont;
    
}

+ (UIViewController *)getTopViewController {
    
    UIViewController *top = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (top.presentedViewController) {
        
        top = top.presentedViewController;
        
    }
    
    return top;
    
}

+ (AWSTask *)makeAsyncRequest:(NSURLRequest *)request {
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // Check for failure
        
        if (error) {
            
            // Not really interested in specifics except for debugging. Only care that the connection failed.
            NSError *connError = [NSError errorWithDomain:@"Geopeg" code:GP_CONNECTION_FAILURE userInfo:nil];
            
            [taskSource setError:connError];
            
            [[self getTopViewController] presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"There was a problem reaching the servers. Please check your connection and retry."] animated:YES completion:nil];
            
            return;
            
        }
        
        // Attempt to read JSON into dictionary
        
        NSDictionary *jsonResponse = [GeopegUtil parseJSONResponse:data];
        
        if (!jsonResponse) {
            
            NSError *jsonError = [NSError errorWithDomain:@"Geopeg" code:GP_JSONPARSE_FAILURE userInfo:nil];
            [taskSource setError:jsonError];
            
            [[self getTopViewController] presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Invalid server response, please try again."] animated:YES completion:nil];
            
            return;
            
        }
        
        // If we made it here, it either succeeded or failed internally (on PHP end) which is handled in the next block
        
        [taskSource setResult:jsonResponse];
        
    }];
    
    return taskSource.task;
    
}

@end
