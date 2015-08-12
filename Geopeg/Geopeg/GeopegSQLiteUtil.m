//
//  GeopegSQLiteUtil.m
//  Geopeg
//
//  Created by Louis on 6/21/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "GeopegSQLiteUtil.h"

@implementation GeopegSQLiteUtil

static GeopegSQLiteUtil *_sharedInstance;

- (id) init {
    
    if (self = [super init]) {
        
        // Make sure the db exists, create if needed
        // Find the documents directory and get db path
        
        NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
            objectAtIndex:0];
        NSString *databasePath = [docsDir stringByAppendingString:@"geopeg.db"];
        
        db = [FMDatabase databaseWithPath:databasePath];
        
        if ([db open]) {
            
            NSString *sql_stmt = @"CREATE TABLE IF NOT EXISTS geopegs (s3path TEXT PRIMARY KEY, posterid TEXT, gzd TEXT, easting TEXT, northing TEXT, datetime TEXT, caption TEXT, geolocked INTEGER)";
            
            if ([db executeUpdate:sql_stmt] == NO) {
                
                NSLog(@"Error creating table");
                
            }
            
            [db close];
            
        }
        else {
            
            NSLog(@"Error opening DB");
            
        }
        
    }
    
    return self;
    
}

+ (GeopegSQLiteUtil *) sharedInstance {
    
    if(!_sharedInstance) {
        
        _sharedInstance = [[GeopegSQLiteUtil alloc] init];
        
    }
    
    return _sharedInstance;
    
}

- (void) insertGeopegWithS3Path:(NSString *)s3path posterid:(NSString *)posterid location:(NSString *)location datetime:(NSString *)datetime caption:(NSString *)caption geolocked:(NSNumber *)geolocked {
    
    if ([db open]) {
    
        NSString *gzd = [location substringWithRange:NSMakeRange(0, 5)];
        NSString *easting = [location substringWithRange:NSMakeRange(5, 5)];
        NSString *northing = [location substringWithRange:NSMakeRange(10, 5)];
    
        NSString *sqlStmt = @"INSERT OR REPLACE INTO geopegs (s3path, posterid, gzd, easting, northing, datetime, caption, geolocked) values (?, ?, ?, ?, ?, ?, ?, ?);";
        
        NSArray *values = [NSArray arrayWithObjects:s3path, posterid, gzd, easting, northing, datetime, caption, geolocked, nil];

        if ([db executeUpdate:sqlStmt withArgumentsInArray:values] == NO) {
            
            NSLog(@"Error inserting new geopeg");
            
        }
        
        [db close];
        
        
    }
    else {
        
        NSLog(@"Error opening database for insert");
        
    }
    
    
}

- (NSDictionary *)fetchGeopegWithS3Path:(NSString *)s3path {
    
    if ([db open]) {
        
        NSString *sqlStmt = @"SELECT * FROM geopegs WHERE s3path = ?";
        
        FMResultSet *set = [db executeQuery:sqlStmt withArgumentsInArray:[NSArray arrayWithObject:s3path]];
        NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
            
        while ([set next]) {
                
            // s3path is unique, we'll never loop more than one row
                
            NSString *posterid = [set stringForColumn:@"posterid"];
            NSString *gzd = [set stringForColumn:@"gzd"];
            NSString *easting = [set stringForColumn:@"easting"];
            NSString *northing = [set stringForColumn:@"northing"];
            NSString *datetime = [set stringForColumn:@"datetime"];
            NSString *caption = [set stringForColumn:@"caption"];
            NSNumber *geolocked = [NSNumber numberWithBool:[set boolForColumn:@"geolocked"]];
                
            NSString *location = [[gzd stringByAppendingString:easting] stringByAppendingString:northing];
                
            [result setObject:s3path forKey:@"s3path"];
            [result setObject:posterid forKey:@"posterid"];
            [result setObject:location forKey:@"location"];
            [result setObject:datetime forKey:@"datetime"];
            [result setObject:caption forKey:@"caption"];
            [result setObject:geolocked forKey:@"geolocked"];
            
        }
        
        [db close];
        return result;
        
    }
    else {
        
        NSLog(@"Error opening database for query");
        return NULL;
        
    }
    
}

@end
