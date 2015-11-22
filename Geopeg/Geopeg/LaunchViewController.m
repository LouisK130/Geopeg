//
//  LaunchViewController.m
//  Geopeg
//
//  Created by Louis on 4/6/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "LaunchViewController.h"
# import "GeopegS3Util.h" // remove me

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
        
        if (!task.result && (!task.error || task.error.code != GP_CONNECTION_FAILURE)) {

            // We're already back at the login screen, just stop here
            return [AWSTask taskWithResult:nil];
            
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
        
        // Send them to main screen
        
        UITabBarController *tabCont = [self.storyboard instantiateViewControllerWithIdentifier:@"Main Tab Bar Controller"];
        [self presentViewController:tabCont animated:YES completion:nil];
        
        if(task.error.code != GP_INTERNAL_ERROR && task.error.code != GP_JSONPARSE_FAILURE) {
            
            // If there was a connection issue, alert them
            
            [tabCont presentViewController:[GeopegUtil createOkAlertWithTitle:@"Error" message:@"Unable to reach the servers."] animated:YES completion:nil];

            
        }
        
        return [AWSTask taskWithResult:nil];
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
