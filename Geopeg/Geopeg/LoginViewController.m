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

    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    if (IP.username) {
        
        [usernameField setText:IP.username];
        
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
    
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    NSString *username = [usernameField text];
    NSString *password = [passwordField text];
    
    if ([username isEqualToString:@""] || [password isEqualToString:@""]) {
        
        [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"All fields must be filled."] animated:YES completion:nil];
        
        return;
        
    }

    IP.username = username;
    
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

/*- (AWSTask *)loginWithPassword:(NSString *)password {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    if (!IP.username) {
        
        // This should never happen...
        
        NSDictionary *info = [NSDictionary dictionaryWithObject:@"No username given" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"Geopeg" code:GP_INVALID_CREDENTIALS userInfo:info];
        
        return [AWSTask taskWithError:error];
        
    }
    
    // Format the request
    NSString *post = [NSString stringWithFormat:@"password=%@&username=%@", password, IP.username];
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"login.php"];
    
}*/


- (void)loginWithPassword:(NSString *)password block:(void (^)(BOOL)) block {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    if (!IP.username) {
        
        // This should never happen...
        
        NSLog(@"Login failed, no username");
        block(NO);
        return;
        
    }
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"password=%@&username=%@", password, IP.username];
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"login.php"];
    
    // Open the connection
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error != nil || [data length] == 0) {
            
            [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"There was a problem reaching the servers. Please check your connection and retry."]
                               animated:YES completion:nil];

            block(NO);
            return;
            
        }
        
        // Attempt to make the response a nice NSDictionary
        
        NSDictionary *jsonResponse = [GeopegUtil parseJSONResponse:data];
        
        if ([[jsonResponse objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *errMsg = [jsonResponse objectForKey:@"Message"];
            
            if ([errMsg isEqualToString:@"Invalid username"]) {
                
                [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Invalid username."] animated:YES completion:nil];

                
            }
            
            else if ([errMsg isEqualToString:@"Invalid password"]) {
                
                [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Invalid password."] animated:YES completion:nil];
                
            }
            
            else {
            
                [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Something went wrong with the login request. Please retry."] animated:YES completion:nil];
                
                
                
            }

            block(NO);
            return;
            
        }
        
        // Save all the values we got as a response
        
        IP.geopegId = [jsonResponse objectForKey:@"Geopeg_ID"];
        IP.geopegToken = [jsonResponse objectForKey:@"Geopeg_Token"];
        IP.identityId = [jsonResponse objectForKey:@"AWSId"];
        [IP.logins setValue:[jsonResponse objectForKey:@"AWSToken"] forKey:@"login.geopeg"];
        
        [GeopegUtil saveUserValues];
        
        block(YES);
        
    }];
    
}

@end