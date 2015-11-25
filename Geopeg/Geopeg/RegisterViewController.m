//
//  RegisterViewController.m
//  Geopeg
//
//  Created by Louis on 6/20/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "RegisterViewController.h"
#import "LoginViewController.h"
#import "GeopegUtil.h"

@implementation RegisterViewController

- (IBAction)submitRegisterPress:(id)sender {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    NSString *username = [regUsername text];
    NSString *pass = [regPassword text];
    NSString *passConf = [regPasswordConf text];
    NSString *email = [regEmail text];
    
    if ([username isEqualToString:@""] ||
        [pass isEqualToString:@""] ||
        [passConf isEqualToString:@""] ||
        [email isEqualToString:@""]) {
        
        [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"All fields are required."] animated:YES completion:nil];
        
        return;
        
    }
    
    if (!([pass isEqualToString:passConf])) {
        
        [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"The passwords entered do not match."] animated:YES completion:nil];
        
        return;
        
    }
    
    
    [[self registerWithUsername:username password:pass email:email] continueWithBlock:^id(AWSTask *task) {
        
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        if (task.result == GP_SUCCESS) {
            
            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
            
            IP.username = username;
            
            // Get the nav controller
            
            UINavigationController *navCont = (UINavigationController *)[self parentViewController];
            
            // Grab the root of the nav controller (Login Page)
            
            LoginViewController *loginView = (LoginViewController *)[navCont.viewControllers objectAtIndex:0];
            
            // Use it to login
            
            [loginView loginWithPassword:pass block:^(BOOL loginResult) {
                
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                
                if (loginResult == YES) {
                    
                    UITabBarController *tabBarCont = [self.storyboard instantiateViewControllerWithIdentifier:@"Main Tab Bar Controller"];
                    [self presentViewController:tabBarCont animated:YES completion:nil];
                    
                    
                }
            }];
            
        }
        
        return nil;
        
    }];
    
    [regUsername resignFirstResponder];
    [regPassword resignFirstResponder];
    [regPasswordConf resignFirstResponder];
    [regEmail resignFirstResponder];
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
}

- (AWSTask *)registerWithUsername:(NSString *)username password:(NSString *)password email:(NSString *)email {
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"username=%@&email=%@&password=%@", username, email, password];
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"register.php"];
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    // Open the connection
    
    [[GeopegUtil makeAsyncRequest:request] continueWithSuccessBlock:^id(AWSTask *task) {
        
        NSDictionary *json = task.result;
        
        if ([[json objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *errMsg = [json objectForKey:@"Message"];
            
            if ([errMsg isEqualToString:@"Email already in use."] || [errMsg isEqualToString:@"Username already in use."]) {
                
                // Make error popup about duplicate email/username
                
                UIAlertController *alertCont = [UIAlertController alertControllerWithTitle:@"Error" message:errMsg preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                
                UIAlertAction *recoverAct = [UIAlertAction actionWithTitle:@"Recover" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    
                    UIViewController *recoverPage = [self.storyboard instantiateViewControllerWithIdentifier:@"RecoverView"];
                    
                    // Push it onto the navgiation stack
                    
                    UINavigationController *navCont = (UINavigationController *)[self parentViewController];
                    [navCont pushViewController:recoverPage animated:YES];
                    
                }];
                
                [alertCont addAction:cancelAct];
                [alertCont addAction:recoverAct];
                
                [self presentViewController:alertCont animated:YES completion:nil];
                
            }
            
            [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Something went wrong with the registration request. Please retry."] animated:YES completion:nil];
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:@"Geopeg" code:GP_INTERNAL_ERROR userInfo:userInfo];
            
            [taskSource setError:error];
            
        }
        
        // If we made it to here, registration succeded
        
        [taskSource setResult:GP_SUCCESS];
        
        return nil;
        
    }];
    
    return taskSource.task;
    
}

@end
