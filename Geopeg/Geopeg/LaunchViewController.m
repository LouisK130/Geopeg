//
//  LaunchViewController.m
//  Geopeg
//
//  Created by Louis on 4/6/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "LaunchViewController.h"

@interface LaunchViewController ()

@end

@implementation LaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    GeopegLocationUtil *lUtil = [GeopegLocationUtil sharedInstance];
    
    [GeopegUtil loadUserValues];
    
    // See if credentials exist / are good
    
    
    [[IP refresh] continueWithBlock:^id(AWSTask *task) {
        
        if (task.error && task.error.code == GP_INVALID_CREDENTIALS) {

            // We're already back at the login screen, just stop here
            return nil;
            
        }
        
        // Start location services to find where they are
        
        int authorized = [CLLocationManager authorizationStatus];
        
        CLLocationManager *manager = [[CLLocationManager alloc] init];
        lUtil->locationManager = manager;
        manager.delegate = lUtil;
        manager.desiredAccuracy = kCLLocationAccuracyBest;
        
        if (authorized == kCLAuthorizationStatusNotDetermined) {
            
            // Check here for iOS 8, otherwise it would crash on 7
            
            if ([manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                
                [manager requestWhenInUseAuthorization];
                
                authorized = [CLLocationManager authorizationStatus];
                
            }
            else {
                
                [manager startUpdatingLocation];
                
            }
            
        }
        
        if (authorized == kCLAuthorizationStatusAuthorizedAlways || authorized == kCLAuthorizationStatusAuthorizedWhenInUse) {
    
            [manager startUpdatingLocation];
            
        }
        
        if((task.error && task.error.code == GP_CONNECTION_FAILURE) || !task.error) {
                
            // Send them to main screen
                
            UITabBarController *tabCont = [self.storyboard instantiateViewControllerWithIdentifier:@"Main Tab Bar Controller"];
            [self presentViewController:tabCont animated:YES completion:nil];
            
        }
        
        return nil;
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
