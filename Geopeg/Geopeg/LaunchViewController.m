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
    
    GeopegUtil *util = [GeopegUtil sharedInstance];
    GeopegLocationUtil *lUtil = [GeopegLocationUtil sharedInstance];
    
    // See if credentials exist / are good

    [util refreshAWSTokenWithBlock:^void(NSNumber * result) {
        
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
        
        if (!util->username || !util->geopegToken || result == 0) {
            
            // If we have no username or token, we have to send them to login screen
            // If refreshing AWS credentials fails, we have to send them to login screen
            
            UINavigationController *navCont = [self.storyboard instantiateViewControllerWithIdentifier:@"Login Navigation Controller"];
            [self presentViewController:navCont animated:YES completion:nil];
            
            return;
            
        }
        
        // Send them to main screen
        
        UITabBarController *tabCont = [self.storyboard instantiateViewControllerWithIdentifier:@"Main Tab Bar Controller"];
        [self presentViewController:tabCont animated:YES completion:nil];
        
        if([result isEqualToNumber:[NSNumber numberWithInt:-1]]) {
            
            // If there was a connection issue, alert them
            
            [tabCont presentViewController:[util createOkAlertWithTitle:@"Error" message:@"Unable to reach the servers."] animated:YES completion:nil];

            
        }
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
