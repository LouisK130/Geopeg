//
//  GeopegSQLiteUtil.h
//  Geopeg
//
//  Created by Louis on 6/21/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <FMDB.h>

@interface GeopegSQLiteUtil : NSObject {
    
    FMDatabase *db;
    
}

+ (GeopegSQLiteUtil *) sharedInstance;
- (void) insertGeopegWithS3Path:(NSString *) s3path posterid:(NSString *) posterid location:(NSString *) location datetime:(NSString *) datetime caption:(NSString *) caption geolocked:(NSNumber *) geolocked;

- (NSDictionary *) fetchGeopegWithS3Path:(NSString *) s3path;

@end
