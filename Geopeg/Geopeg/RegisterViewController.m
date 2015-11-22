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
    
    
    [self registerWithUsername:username password:pass email:email completionBlock:^(BOOL result) {
        
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        if (result == YES) {
            
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
        
    }];
    
    [regUsername resignFirstResponder];
    [regPassword resignFirstResponder];
    [regPasswordConf resignFirstResponder];
    [regEmail resignFirstResponder];
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
}

- (void)registerWithUsername:(NSString *)username password:(NSString *)password email:(NSString *)email completionBlock:(void (^)(BOOL)) block {
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"username=%@&email=%@&password=%@", username, email, password];
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"register.php"];
    
    // Open the connection
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // Check for failure
        
        if (error != nil || [data length] == 0) {
            
            [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"There was a problem reaching the servers. Please check your connection and retry."] animated:YES completion:nil];
            
            block(NO);
            return;
            
        }
        
        // Attempt to read JSON into dictionary
        
        NSDictionary *jsonResponse = [GeopegUtil parseJSONResponse:data];
        
        if ([[jsonResponse objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *errMsg = [jsonResponse objectForKey:@"Message"];
            
            if ([errMsg isEqualToString:@"Email already in use."] || [errMsg isEqualToString:@"Username already in use."]) {
                
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
                
                block(NO);
                
                return;
                
            }
            
            [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Something went wrong with the registration request. Please retry."] animated:YES completion:nil];
            
            NSLog(@"Error:%@", errMsg);
            
            block(NO);
            return;
            
        }
        
        // If we made it to here, registration succeded
        
        block(YES);
        
    }];
    
}

@end
