//
//  GeopegIdentityProvider.m
//  Geopeg
//
//  Created by Louis on 11/16/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "GeopegIdentityProvider.h"

@implementation GeopegIdentityProvider

- (AWSTask *)getIdentityId {
    
    if (self.identityId) {
        
        // Id is cached, return it
        return [AWSTask taskWithResult:self.identityId];
        
    }
    else {
        
        // Return nil for now, try to fetch ID with refresh logic
        
        return [[AWSTask taskWithResult:nil] continueWithBlock:^id(AWSTask *task) {
            return [self refresh];
        }];
        
    }
}

- (AWSTask *)refresh {
    
    if (!self.username || !self.geopegToken) {
        
        // If no username or token, we can't go further. User needs to login.
        
        [self logoutLocalOnly:YES];
        
        NSError *loggedOut = [NSError errorWithDomain:@"Geopeg" code:GP_INVALID_CREDENTIALS userInfo:nil];
        return [AWSTask taskWithError:loggedOut];
        
    }
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"token=%@&username=%@", self.geopegToken, self.username];
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"login.php"];
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    // Connect and request data
    
    [[GeopegUtil makeAsyncRequest:request] continueWithBlock:^id(AWSTask *task) {
        
        if (task.error) {
            
            // If request failed, just pass the error along
            [taskSource setError:task.error];
            return nil;
            
        }
        
        NSDictionary *json = task.result;
        
        // Failed internally?
        if ([[json objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[json objectForKey:@"Message"] forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"Geopeg" code:GP_INTERNAL_ERROR userInfo:userInfo];
            [taskSource setError:error];
            
        }
        
        // Success
        // Save all the values we got as a response
        
        self.identityId = [json objectForKey:@"AWSId"];
        self.token = [json objectForKey:@"AWSToken"];
        
        [taskSource setResult:GP_SUCCESS];
        
        return nil;
        
    }];
    
    return taskSource.task;
    
}

- (AWSTask *)logoutLocalOnly:(BOOL) localOnly {
    
    self.identityId = nil;
    self.logins = nil;
    self.geopegToken = nil;
    self.geopegId = nil;
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]];
    UINavigationController *navCont = [sb instantiateViewControllerWithIdentifier:@"Login Navigation Controller"];
    UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [root presentViewController:navCont animated:YES completion:nil];
    
    if (localOnly) {
        
        return [AWSTask taskWithResult:nil];
        
    }
    
    // Needs to go to logout on PhP too, invalidate GeopegToken
    // TO DO go lookup what needs to be sent in logout.php ...
    
    NSString *post = [NSString stringWithFormat:@"username=%@&token=%@", self.username, self.geopegToken];
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"logout.php"];
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [[GeopegUtil makeAsyncRequest:request] continueWithSuccessBlock:^id(AWSTask *task) {
        
        NSDictionary *json = task.result;
        
        if ([[json objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            // Lookup what kind of errors can result ...
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[json objectForKey:@"Message"] forKey:NSLocalizedDescriptionKey];
            
            NSError *error = [NSError errorWithDomain:@"Geopeg" code:GP_INTERNAL_ERROR userInfo:userInfo];
            
            [taskSource setError:error];
            
        }
        
        [taskSource setResult:GP_SUCCESS];
        
        return nil;
        
    }];
    
    return taskSource.task;
    
}

@end
