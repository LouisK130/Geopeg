//
//  RegisterViewController.h
//  Geopeg
//
//  Created by Louis on 6/20/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RegisterViewController : UIViewController {
    
    // Register Values
    
    IBOutlet UITextField *regUsername;
    IBOutlet UITextField *regPassword;
    IBOutlet UITextField *regPasswordConf;
    IBOutlet UITextField *regEmail;
    
}

- (void)registerWithUsername:(NSString *) username password:(NSString *) password email:(NSString *) email completionBlock:(void (^)(BOOL)) block;

- (IBAction)submitRegisterPress:(id) sender;

@end