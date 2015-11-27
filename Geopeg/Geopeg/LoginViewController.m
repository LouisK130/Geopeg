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

- (AWSTask *)loginWithPassword:(NSString *)password {
    
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
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    // Make the conn
    
    [[GeopegUtil makeAsyncRequest:request] continueWithSuccessBlock:^id(AWSTask *task) {
        
        NSDictionary *json = task.result;
        
        if ([[json objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *errMsg = [json objectForKey:@"Message"];
            
            NSError *credsError = [NSError errorWithDomain:@"Geopeg" code:GP_INVALID_CREDENTIALS userInfo:nil];
            
            if ([errMsg isEqualToString:@"Invalid username"]) {
                
                [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Invalid username."] animated:YES completion:nil];
                
                [taskSource setError:credsError];
                
                
            }
            
            else if ([errMsg isEqualToString:@"Invalid password"]) {
                
                [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Invalid password."] animated:YES completion:nil];
                
                [taskSource setError:credsError];
                
            }
            
            else {
                
                [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Something went wrong with the login request. Please retry."] animated:YES completion:nil];
                
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"Geopeg" code:GP_INTERNAL_ERROR userInfo:userInfo];
                
                [taskSource setError:error];
                
            }
            
        }
        
        IP.geopegId = [json objectForKey:@"Geopeg_ID"];
        IP.geopegToken = [json objectForKey:@"Geopeg_Token"];
        IP.identityId = [json objectForKey:@"AWSId"];
        IP.token = [json objectForKey:@"AWSToken"];

        [GeopegUtil saveUserValues];
        
        [taskSource setResult:GP_SUCCESS];
        
        return nil;
    
    }];
    
    return taskSource.task;
    
}

@end