//
//  GeopegS3Util.m
//  Geopeg
//
//  Created by Louis on 8/4/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "GeopegS3Util.h"

@implementation GeopegS3Util

static GeopegS3Util *_sharedInstance;

- (id) init {
    
    return self;
    
}

+ (GeopegS3Util *) sharedInstance {
    
    if(!_sharedInstance) {
        
        _sharedInstance = [[GeopegS3Util alloc] init];
        
    }
    
    return _sharedInstance;
    
}

@end
