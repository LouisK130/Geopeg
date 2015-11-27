//
//  PassResetViewController.h
//  Geopeg
//
//  Created by Louis on 6/20/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWSCore/AWSCore.h"

@interface PassResetViewController : UIViewController {
    
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *codeField;
    IBOutlet UITextField *newPassField;
    IBOutlet UITextField *newPassConfField;
    
}

- (AWSTask *)requestPassResetForEmail:(NSString *) email;

- (AWSTask *)resetPassWithToken:(NSString *) token email:(NSString *) email newPass:(NSString *) newPass;

@end
