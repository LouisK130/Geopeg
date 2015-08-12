//
//  PassResetViewController.m
//  Geopeg
//
//  Created by Louis on 6/20/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "PassResetViewController.h"
#import "GeopegUtil.h"

@implementation PassResetViewController

- (IBAction)pressRecoverPass:(id)sender {
    
    GeopegUtil *util = [GeopegUtil sharedInstance];
    
    util->email = [emailField text];
    
    if ([util->email isEqualToString:@""]) {
        
        [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"Email cannot be empty."] animated:YES completion:nil];
        
        return;
        
    }
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    [self requestPassResetForEmail:util->email completionBlock:^(BOOL result) {
        
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        if (result == YES) {
            
            UIViewController *resetPage = [self.storyboard instantiateViewControllerWithIdentifier:@"ResetPassView"];
            UINavigationController *navCont = (UINavigationController *)[self parentViewController];
            [navCont pushViewController:resetPage animated:YES];
            
        }
        
    }];
    
}

- (IBAction)pressResetPass:(id) sender {
    
    GeopegUtil *util = [GeopegUtil sharedInstance];
    
    NSString *code = [codeField text];
    NSString *newPass = [newPassField text];
    NSString *newPassConf = [newPassConfField text];
    
    if (!([newPass isEqualToString:newPassConf])) {
        
        [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"Passwords do not match."] animated:YES completion:nil];
        
        return;
        
    }
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    [self resetPassWithToken:code email:util->email newPass:newPass completionBlock:^(BOOL result) {
        
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        if (result == YES) {
            
            UIAlertController *alertCont = [UIAlertController alertControllerWithTitle:@"Success" message:@"Password changed." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAct = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                // Go back to login page when they click OK
                
                [((UINavigationController *)[self parentViewController]) popToRootViewControllerAnimated:YES];
                
            }];
            
            [alertCont addAction:okAct];
            
            [self presentViewController:alertCont animated:YES completion:nil];
            
        }
        
    }];
    
}

- (void)requestPassResetForEmail:(NSString *) email completionBlock:(void(^)(BOOL)) block {
    
    // Helper functions
    
    GeopegUtil *util = [GeopegUtil sharedInstance];
    
    // Format post string
    
    NSString *post = [NSString stringWithFormat:@"email=%@", email];
    
    // Format request
    
    NSMutableURLRequest *request = [util formatConnectionWithPostString:post filePath:@"forgotpass.php"];
    
    // Open conn
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // Check for failure
        
        if (error != nil || [data length] == 0) {
            
            [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"Unable to reach the servers."] animated:YES completion:nil];
            block(NO);
            return;
            
        }
        
        // Attempt to read JSON into dictionary
        
        NSDictionary *jsonResponse = [util parseJSONResponse:data];
        
        if ([[jsonResponse objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *errMsg = [jsonResponse objectForKey:@"Message"];
            
            if ([errMsg isEqualToString:@"Token expired"]) {
                
                [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"Your recovery code is expired. Please request a new one."] animated:YES completion:nil];
                block(NO);
                return;
                
            }
            
            else if ([errMsg isEqualToString:@"Invalid token"]) {
                
                [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"Your recovery code is not valid. Please check to make sure you copied it properly."] animated:YES completion:nil];
                block(NO);
                return;
                
            }
            
            [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"There was an internal issue. Please retry later."] animated:YES completion:nil];
            block(NO);
            return;
            
        }
        
        // If we made it to here, it succeded
        
        block(YES);
        
    }];
    
}

- (void)resetPassWithToken:(NSString *) token email:(NSString *) email newPass:(NSString *) newPass completionBlock:(void(^)(BOOL)) block {
    
    // Helper functions
    
    GeopegUtil *util = [GeopegUtil sharedInstance];
    
    // Format post string
    
    NSString *post = [NSString stringWithFormat:@"recovery_token=%@&email=%@&new_pass=%@", token, email, newPass];
    
    // Format request
    
    NSMutableURLRequest *request = [util formatConnectionWithPostString:post filePath:@"resetpass.php"];
    
    // Open conn
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        // Check for failure
        
        if (error != nil || [data length] == 0) {
            
            [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"There was a problem reaching the servers. Please check your connection and retry."] animated:YES completion:nil];
            block(NO);
            return;
            
        }
        
        // Attempt to read JSON into dictionary
        
        NSDictionary *jsonResponse = [util parseJSONResponse:data];
        
        if ([[jsonResponse objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            [self presentViewController:[util createOkAlertWithTitle:@"Error" message:@"There was an internal issue. Please retry later."] animated:YES completion:nil];
            
            block(NO);
            return;
            
        }
        
        // If we made it to here, it succeded
        
        block(YES);
        
    }];
    
}


@end
