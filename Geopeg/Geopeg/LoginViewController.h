//
//  LoginViewController.h
//  Geopeg
//
//  Created by Louis on 5/17/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController {
    
    // Login Values
    
    IBOutlet UITextField *usernameField;
    IBOutlet UITextField *passwordField;
    
}

- (void)loginWithPassword:(NSString *) password block:(void(^)(BOOL)) block;

@end
