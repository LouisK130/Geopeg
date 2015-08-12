//
//  PassResetViewController.h
//  Geopeg
//
//  Created by Louis on 6/20/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PassResetViewController : UIViewController {
    
    IBOutlet UITextField *emailField;
    IBOutlet UITextField *codeField;
    IBOutlet UITextField *newPassField;
    IBOutlet UITextField *newPassConfField;
    
}

- (void)requestPassResetForEmail:(NSString *) email completionBlock:(void(^)(BOOL)) block;

- (void)resetPassWithToken:(NSString *) token email:(NSString *) email newPass:(NSString *) newPass completionBlock:(void(^)(BOOL)) block;

@end
