//
//  FirstViewController.m
//  Geopeg
//
//  Created by Louis on 4/6/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    GeopegLocationUtil *lUtil = [GeopegLocationUtil sharedInstance];
    
    NSLog(@"Current location: %@", [lUtil getCurrentMGRSLocation]);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
