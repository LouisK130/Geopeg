//
//  GeopegDownloadUtil.h
//  Geopeg
//
//  Created by Louis on 6/21/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeopegUtil.h"

@interface GeopegDownloadUtil : NSObject

+ (AWSTask *) requestImageDataForLocation:(NSString *)mgrsid size:(NSNumber *) size startDate:(NSString *) startDate currentMGRS:(NSString *) currentMGRS;

+ (AWSTask *) requestSelfImageDataWithStartDate:(NSString *)startDate;

+ (AWSTask *) uploadImageDataWithS3Path:(NSString *)s3path mgrsid:(NSString *)mgrsid caption:(NSString *)caption;

@end
