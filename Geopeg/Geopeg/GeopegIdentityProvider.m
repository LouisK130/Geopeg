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
    
    if ([NSThread isMainThread]) {
        
        NSLog(@"Main thread");
        
    }
    
    if (!self.username || !self.geopegToken) {
        
        // If no username or token, we can't go further. User needs to login.
        
        [self logout];
        
        NSError *loggedOut = [NSError errorWithDomain:@"Geopeg" code:GP_INVALID_CREDENTIALS userInfo:nil];
        return [AWSTask taskWithError:loggedOut];
        
    }
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"token=%@&username=%@", self.geopegToken, self.username];
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"login.php"];
    
    // Make the connection
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    
        if (!data) {
        
            return;
        
        }
    
        NSDictionary *json = [GeopegUtil parseJSONResponse:data];
    
        if (!json) {
        
            return;
        
        }
        
        if ([[json objectForKey:@"Result"] isEqualToString:@"Failure"]) {
        
            return;
            
        }
        
        // Save all the values we got as a response
    
        self.identityId = [json objectForKey:@"AWSId"];
        self.token = [json objectForKey:@"AWSToken"];
        
    }];
    
    return nil;
    
}

- (void)logout {
    
    self.identityId = nil;
    self.logins = nil;
    self.geopegToken = nil;
    self.username = nil;
    self.email = nil;
    self.geopegId = nil;
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]];
    UINavigationController *navCont = [sb instantiateViewControllerWithIdentifier:@"Login Navigation Controller"];
    UIViewController *root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [root presentViewController:navCont animated:YES completion:nil];
    
    // Needs to go to logout on PhP too, invalidate GeopegToken
    
}

@end
