//
//  RegisterViewController.h
//  Geopeg
//
//  Created by Louis on 6/20/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWSCore/AWSCore.h"

@interface RegisterViewController : UIViewController {
    
    // Register Values
    
    IBOutlet UITextField *regUsername;
    IBOutlet UITextField *regPassword;
    IBOutlet UITextField *regPasswordConf;
    IBOutlet UITextField *regEmail;
    
}

- (AWSTask *)registerWithUsername:(NSString *) username password:(NSString *) password email:(NSString *) email;

- (IBAction)submitRegisterPress:(id) sender;

@end