//
//  GeopegDownloadUtil.m
//  Geopeg
//
//  Created by Louis on 6/21/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "GeopegDownloadUtil.h"

@implementation GeopegDownloadUtil

static GeopegDownloadUtil *_sharedInstance;

- (id) init {
    
    if (self = [super init]) {
        
        self->storedDataRequests = [[NSCache alloc] init];
        self->storedSelfImageData = [[NSMutableDictionary alloc] init];
        
    }
    
    return self;
    
}

+ (GeopegDownloadUtil *) sharedInstance {
    
    if (!_sharedInstance) {
        
        _sharedInstance = [[GeopegDownloadUtil alloc] init];
        
    }
    
    return _sharedInstance;
    
}

- (void)requestImageDataForLocation:(NSString *)mgrsid size:(NSNumber *)size startDate:(NSString *)startDate currentMGRS:(NSString *)currentMGRS completionBlock:(void (^)(int))block {
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"mgrsid=%@&startdate=%@&size=%d", mgrsid, startDate, [size intValue]];
    
    if (currentMGRS != nil) {
        
        post = [post stringByAppendingString:[NSString stringWithFormat:@"&user_mgrsid=%@", currentMGRS]];
        
    }
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"download.php"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error != nil || [data length] == 0) {
            
            NSLog(@"Error with image data fetch request");
            block(GP_CONNECTION_FAILURE);
            return;
            
        }
        
        // Attempt to make the response a nice NSDictionary
        
        NSDictionary *jsonResponse = [GeopegUtil parseJSONResponse:data];
        
        if ([[jsonResponse objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *msg = [jsonResponse objectForKey:@"Message"];
            
            NSLog(@"Image data request failed: %@", msg);
            
            if ([msg isEqualToString:@"Invalid token"]) {
                
                block(GP_INTERNAL_ERROR);
                return;
                
            }
            
            block(GP_INTERNAL_ERROR);
            return;
            
        }
        
        // If we got to here, request succeeded
        // Here we are only going to store the data in memory (an NSCache)
        // I considered storing this in SQLite for longer-term caching
        // But I'm not sure it would be very effective anyways
        
        NSString *tenbyten_mgrs = [mgrsid stringByReplacingCharactersInRange:NSMakeRange(9, 1) withString:@"0"];
        tenbyten_mgrs = [tenbyten_mgrs stringByReplacingCharactersInRange:NSMakeRange(14, 1) withString:@"0"];
        
        if (![self->storedDataRequests objectForKey:tenbyten_mgrs]) {
            
            [self->storedDataRequests setObject:[[NSMutableArray alloc] init] forKey:tenbyten_mgrs];
            
        }
        
        for (NSDictionary *imageData in jsonResponse[@"Results"]) {
            
            [(NSMutableArray *)([self->storedDataRequests objectForKey:tenbyten_mgrs]) addObject:imageData];
            
        }
        
        block(GP_SUCCESS);
        
        
    }];

}

- (void)requestSelfImageDataWithStartDate:(NSString *)startDate completionBlock:(void (^)(int))block {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"username=%@&token=%@&startdate=%@", IP.username, IP.geopegToken, startDate];
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"selfdownload.php"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error != nil || [data length] == 0) {
            
            // Returning -1 means a real error
            // Probably failed to make a connection
            
            NSLog(@"Error with fetching self image data");
            block(GP_CONNECTION_FAILURE);
            return;
            
        }
        
        // Attempt to make the response a nice NSDictionary
        
        NSDictionary *jsonResponse = [GeopegUtil parseJSONResponse:data];
        
        if ([[jsonResponse objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *msg = [jsonResponse objectForKey:@"Message"];
            
            NSLog(@"Self download request failed: %@", msg);
            
            if ([msg isEqualToString:@"Invalid token"]) {
                
                block(GP_INTERNAL_ERROR);
                return;
                
            }
            
            block(GP_INTERNAL_ERROR);
            return;
            
        }
        
        for (NSDictionary *imageData in jsonResponse[@"Results"]) {
            
            [self->storedSelfImageData setObject:imageData forKey:imageData[@"S3Path"]];
            
        }
        
        block(GP_SUCCESS);
        
        
    }];

}

- (void)uploadImageDataWithS3Path:(NSString *)s3path mgrsid:(NSString *)mgrsid caption:(NSString *)caption completionBlock:(void (^)(int))block {
    
    GeopegIdentityProvider *IP = [GeopegUtil getCredsProvider].identityProvider;
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"username=%@&token=%@&s3path=%@&mgrsid=%@&caption=%@", IP.username, IP.geopegToken, s3path, mgrsid, caption];
    
    NSMutableURLRequest *request = [GeopegUtil formatConnectionWithPostString:post filePath:@"upload.php"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error != nil || [data length] == 0) {
            
            // Returning -1 means a real error
            // Probably failed to make a connection
            
            NSLog(@"Error with uploading image data");
            block(GP_CONNECTION_FAILURE);
            return;
            
        }
        
        // Attempt to make the response a nice NSDictionary
        
        NSDictionary *jsonResponse = [GeopegUtil parseJSONResponse:data];
        
        if ([[jsonResponse objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            NSString *msg = [jsonResponse objectForKey:@"Message"];
            
            NSLog(@"Image upload request failed: %@", msg);
            
            if ([msg isEqualToString:@"Invalid token"]) {
                
                block(GP_INTERNAL_ERROR);
                return;
                
            }
            
            block(GP_INTERNAL_ERROR);
            return;
            
        }
        
        block(GP_SUCCESS);
        
        
    }];
    
}

@end
