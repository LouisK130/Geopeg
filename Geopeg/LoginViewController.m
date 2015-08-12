//
//  LoginViewController.m
//  Geopeg
//
//  Created by Louis on 5/17/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "LoginViewController.h"
#import "GeopegUtil.h"

@implementation LoginViewController

- (void) viewDidAppear:(BOOL)animated {

    GeopegUtil *util = [GeopegUtil sharedInstance];
    
    if (util->username) {
        
        [usernameField setText:util->username];
        
    }
    
}

- (IBAction)registerPress:(id)sender {
    
    // Create the register page
    
    UIViewController *registerPage = [self.storyboard instantiateViewControllerWithIdentifier:@"RegisterView"];
    
    // Push it onto the navgiation stack
    
    UINavigationController *navCont = (UINavigationController *)[self parentViewController];
    [navCont pushViewController:registerPage animated:YES];
    
}

- (IBAction)forgotPassPress:(id)sender {
    
    UIViewController *recoverPage = [self.storyboard instantiateViewControllerWithIdentifier:@"RecoverView"];
    
    // Push it onto the navgiation stack
    
    UINavigationController *navCont = (UINavigationController *)[self parentViewController];
    [navCont pushViewController:recoverPage animated:YES];
    
}

- (IBAction)loginPress:(id)sender {
    
    
    GeopegUtil *util = [GeopegUtil sharedInstance];
    
    NSString *username = [usernameField text];
    NSString *password = [passwordField text];
    
    if ([username isEqualToString:@""] || [password isEqualToString:@""]) {
        
        [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"All fields must be filled."] animated:YES completion:nil];
        
        return;
        
    }

    util->username = username;
    
    [self loginWithPassword:password block:^(BOOL result) {
        
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
       
        if (result == YES) {
            
            UITabBarController *tabBarCont = [self.storyboard instantiateViewControllerWithIdentifier:@"Main Tab Bar Controller"];
            [self presentViewController:tabBarCont animated:YES completion:nil];
            
        }
        
    }];
    
    // Drop text focus, so they can't edit the fields
    
    [usernameField resignFirstResponder];
    [passwordField resignFirstResponder];
    
    // Stop input while loading
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
}


- (void)loginWithPassword:(NSString *)password block:(void (^)(BOOL)) block {
    
    GeopegUtil *util = [GeopegUtil sharedInstance];
    
    if (!util->username) {
        
        // This should never happen...
        
        NSLog(@"Login failed, no username");
        block(NO);
        return;
        
    }
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"password=%@&username=%@", password, util->username];
    
    NSMutableURLRequest *request = [util formatConnectionWithPostString:post filePath:@"login.php"];
    
    // Open the connection
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error != nil || [data length] == 0) {
            
            [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"There was a problem reaching the servers. Please check your connection and retry."]
                               animated:YES completion:nil];

            block(NO);
            return;
            
        }
        
        // Attempt to make the response a nice NSDictionary
        
        NSDictionary *jsonResponse = [util parseJSONResponse:data];
        
        if ([[jsonResponse objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *errMsg = [jsonResponse objectForKey:@"Message"];
            
            if ([errMsg isEqualToString:@"Invalid username"]) {
                
                [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"Invalid username."] animated:YES completion:nil];

                
            }
            
            else if ([errMsg isEqualToString:@"Invalid password"]) {
                
                [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"Invalid password."] animated:YES completion:nil];
                
            }
            
            else {
            
                [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"Something went wrong with the login request. Please retry."] animated:YES completion:nil];
                
                
                
            }

            block(NO);
            return;
            
        }
        
        // Save all the values we got as a response
        
        util->geopegToken = [jsonResponse objectForKey:@"Geopeg_Token"];
        util->awsID = [jsonResponse objectForKey:@"AWSId"];
        util->awsToken = [jsonResponse objectForKey:@"AWSToken"];
        
        [util saveUserValues];
        
        block(YES);
        
    }];
    
}

@end