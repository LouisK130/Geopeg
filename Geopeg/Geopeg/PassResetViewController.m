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
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    IP.email = [emailField text];
    
    if ([IP.email isEqualToString:@""]) {
        
        [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Email cannot be empty."] animated:YES completion:nil];
        
        return;
        
    }
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    [[self requestPassResetForEmail:IP.email] continueWithBlock:^id(AWSTask *task) {
        
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        if (task.result) {
            
            UIViewController *resetPage = [self.storyboard instantiateViewControllerWithIdentifier:@"ResetPassView"];
            UINavigationController *navCont = (UINavigationController *)[self parentViewController];
            [navCont pushViewController:resetPage animated:YES];
            
        }
        
        return nil;
        
    }];
    
}

- (IBAction)pressResetPass:(id) sender {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    NSString *code = [codeField text];
    NSString *newPass = [newPassField text];
    NSString *newPassConf = [newPassConfField text];
    
    if (!([newPass isEqualToString:newPassConf])) {
        
        [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Passwords do not match."] animated:YES completion:nil];
        
        return;
        
    }
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    [[self resetPassWithToken:code email:IP.email newPass:newPass] continueWithBlock:^id(AWSTask *task) {
        
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        
        if (task.result) {
            
            UIAlertController *alertCont = [UIAlertController alertControllerWithTitle:@"Success" message:@"Password changed." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAct = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                
                // Go back to login page when they click OK
                
                [((UINavigationController *)[self parentViewController]) popToRootViewControllerAnimated:YES];
                
            }];
            
            [alertCont addAction:okAct];
            
            [self presentViewController:alertCont animated:YES completion:nil];
            
        }
        
        return nil;
        
    }];
    
}

- (AWSTask *)requestPassResetForEmail:(NSString *) email {
    
    // Format post string
    
    NSString *post = [NSString stringWithFormat:@"email=%@", email];
    
    // Format request
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"forgotpass.php"];
    
    // Open conn
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [[GeopegUtil makeAsyncRequest:request] continueWithSuccessBlock:^id(AWSTask *task) {
        
        NSDictionary *json = task.result;
        
        if ([[json objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"There was an internal issue. Please retry later."] animated:YES completion:nil];
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[json objectForKey:@"Message"] forKey:NSLocalizedDescriptionKey];
            
            NSError *error = [NSError errorWithDomain:@"Geopeg" code:GP_INTERNAL_ERROR userInfo:userInfo];
            
            [taskSource setError:error];
            
        }
        
        else {
            
            [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Email sent" message:@"Please go check your email for your recovery code."] animated:YES completion:nil];
            
            [taskSource setResult:GP_SUCCESS];
            
        }
        
        return nil;
    
    }];
    
    return taskSource.task;
    
}

- (AWSTask *)resetPassWithToken:(NSString *) token email:(NSString *) email newPass:(NSString *) newPass {
    
    // Format post string
    
    NSString *post = [NSString stringWithFormat:@"recovery_token=%@&email=%@&new_pass=%@", token, email, newPass];
    
    // Format request
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"resetpass.php"];
    
    // Open conn
    
    AWSTaskCompletionSource *taskSource = [AWSTaskCompletionSource taskCompletionSource];
    
    [[GeopegUtil makeAsyncRequest:request] continueWithSuccessBlock:^id(AWSTask *task) {
        
        NSDictionary *json = task.result;
        
        if ([[json objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *msg = [json objectForKey:@"Message"];
            
            NSError *credsError = [NSError errorWithDomain:@"Geopeg" code:GP_INVALID_CREDENTIALS userInfo:nil];
            
            if ([msg isEqualToString:@"Token expired"]) {
                
                [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Your recovery code has expired. Please request a new one."] animated:YES completion:nil];
                
                [taskSource setError:credsError];
                
            }
            
            else if ([msg isEqualToString:@"Invalid token"]) {
                
                [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"This is not a valid recovery code. Please make sure you copied it correctly."] animated:YES completion:nil];
                
                [taskSource setError:credsError];
                
            }
            
            else {
                
                [self presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"An internal error occured. Please retry."] animated:YES completion:nil];
                
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:msg forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:@"Geopeg" code:GP_INTERNAL_ERROR userInfo:userInfo];
                
                [taskSource setError:error];
                
            }
            
        }
        
        [taskSource setResult:GP_SUCCESS];
        
        return nil;
    
    }];
    
    return taskSource.task;
    
}


@end
