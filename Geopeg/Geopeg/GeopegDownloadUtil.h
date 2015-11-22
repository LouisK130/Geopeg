//
//  GeopegDownloadUtil.h
//  Geopeg
//
//  Created by Louis on 6/21/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeopegUtil.h"

@interface GeopegDownloadUtil : NSObject {
    
    @public NSCache *storedDataRequests;
    @public NSMutableDictionary *storedSelfImageData;
    
}

// Get the only available instance

+ (GeopegDownloadUtil *)sharedInstance;

// Both of these functions store information in their
// respective NSCache declared above

- (void) requestImageDataForLocation:(NSString *)mgrsid size:(NSNumber *) size startDate:(NSString *) startDate currentMGRS:(NSString *) currentMGRS completionBlock:(void (^) (int)) block;

- (void) requestSelfImageDataWithStartDate:(NSString *)startDate completionBlock:(void (^) (int)) block;

- (void) uploadImageDataWithS3Path:(NSString *)s3path mgrsid:(NSString *)mgrsid caption:(NSString *)caption completionBlock:(void (^) (int)) block;

@end
