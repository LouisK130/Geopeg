//
//  GeopegUtil.m
//  Geopeg
//
//  Created by Louis on 5/16/15.
//  Copyright (c) 2015 Geopeg App. All rights reserved.
//

#import "GeopegUtil.h"

@implementation GeopegUtil

static GeopegUtil *_sharedInstance;

- (id) init {
    
    if (self = [super init]) {
        
        [self loadUserValues];
        
    }
    
    return self;
    
}

+ (GeopegUtil *) sharedInstance {
    
    if (!_sharedInstance) {
        
        _sharedInstance = [[GeopegUtil alloc] init];
        
    }
    
    return _sharedInstance;
    
}

- (NSMutableURLRequest *)formatConnectionWithPostString:(NSString *)post filePath:(NSString *)path {
    
    // Converted to POST data
    
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    // Length of post data
    
    NSString *postLength = [NSString stringWithFormat:@"%d", (int)[postData length]];
    
    // Create a request
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    // Set some parameters of the request
    
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"http://192.168.1.2:8000/", path]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    return request;
}

- (NSDictionary *)parseJSONResponse:(NSData *)data {
    
    // Parse it into JSON that we can work with
    
    NSError *jsonError;
    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    
    if (!jsonResponse) {
        NSLog(@"Error parsing JSON");
        return nil;
    }
    
    return jsonResponse;
    
}

- (BOOL)saveUserValues {
    
    NSError *error;
    
    // Find the place to save it
    
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"UserData.plist"];
    
    // Build the values into a dictionary
    
    NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:
        [NSArray arrayWithObjects: geopegToken, awsID, awsToken, username, nil]
        forKeys:[NSArray arrayWithObjects:@"Geopeg_Token", @"AWSId", @"AWSToken", @"username", nil]];
    
    // Format it as savable data
    
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plistDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if (!plistData) {
        
        NSLog(@"Error saving user values");
        return NO;
        
    }
    
    [plistData writeToFile:plistPath atomically:YES];
    
    return YES;
    
}

- (BOOL)loadUserValues {
    
    // Setup values
    
    NSError *error;
    NSPropertyListFormat format;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"UserData.plist"];
    
    // Make sure we have the right file path
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        
        NSLog(@"UserData.plist did not exist for loading");
        return NO;
        
    }
    
    // Read the file
    
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    
    // Fromat as a dictionary we can read
    
    NSDictionary *tempDict = (NSDictionary *)[NSPropertyListSerialization propertyListWithData:plistXML options:NSPropertyListImmutable format:&format error:&error];
    
    if (!tempDict) {
        
        NSLog(@"Error reading plist: %@, format: %d", error, (int)format);
        return NO;
        
    }
    
    // Put values in our memory
    
    self->username = [tempDict objectForKey:@"username"];
    self->geopegToken = [tempDict objectForKey:@"Geopeg_Token"];
    self->awsID = [tempDict objectForKey:@"AWSId"];
    self->awsToken = [tempDict objectForKey:@"AWSToken"];
    
    return YES;
    
}

- (void)refreshAWSTokenWithBlock:(void (^) (NSNumber *)) block {
    
    // We need a username stored
    
    if (!self->username || !self->geopegToken) {
        
        // Call the callback block with a failed result
        
        block(0);
        return;
        
    }
    
    // Format the request
    
    NSString *post = [NSString stringWithFormat:@"token=%@&username=%@", self->geopegToken, self->username];
    
    NSMutableURLRequest *request = [self formatConnectionWithPostString:post filePath:@"login.php"];
    
    // Make the connection
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
       
        if (error != nil || [data length] == 0) {
            
            // Returning -1 means a real error
            // Probably failed to make a connection
            
            NSLog(@"Error with AWS Token Refresh request");
            block([NSNumber numberWithInt:-1]);
            return;
            
        }
        
        // Attempt to make the response a nice NSDictionary
        
        NSDictionary *jsonResponse = [self parseJSONResponse:data];
        
        if ([[jsonResponse objectForKey:@"Result"] isEqualToString:@"Failure"]) {
            
            // Now this sort of error likely means that the token is invalid
            // We want to force them to attempt login, so return 0
            
            NSLog(@"AWS Token Refresh request failed: %@", [jsonResponse objectForKey:@"Message"]);
            block(0);
            return;
            
        }
        
        // Save all the values we got as a response

        self->geopegToken = [jsonResponse objectForKey:@"Geopeg_Token"];
        self->awsID = [jsonResponse objectForKey:@"AWSId"];
        self->awsToken = [jsonResponse objectForKey:@"AWSToken"];
        
        [self saveUserValues];
        
        block([NSNumber numberWithInt:1]);
        
        
    }];
    
}

- (UIAlertController *)createOkAlertWithTitle:(NSString *)title message:(NSString *)message {

    UIAlertController *alertCont = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAct = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
    
    [alertCont addAction:okAct];
    
    return alertCont;
    
}

@end
