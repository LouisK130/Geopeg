//
//  GeopegIdentityProvider.h
//  Geopeg
//
//  Created by Louis on 11/16/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWSIdentityProvider.h"
#import "GeopegUtil.h"

@interface GeopegIdentityProvider : AWSAbstractCognitoIdentityProvider

@property (strong, atomic) NSString *username;
@property (strong, atomic) NSString *email;
@property (strong, atomic) NSString *geopegToken;
@property (strong, atomic) NSString *geopegId;
@property (strong, atomic) NSString *token;

- (AWSTask *)logoutLocalOnly:(BOOL) localOnly;

@end
