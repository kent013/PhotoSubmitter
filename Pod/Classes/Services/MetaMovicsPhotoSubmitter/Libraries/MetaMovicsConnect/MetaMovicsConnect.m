//
//  MetaMovicsConnect.m
//  MetaMovicsConnect
//
//  Created by Kentaro ISHITOYA on 12/02/21.
//  Copyright (c) 2012 Kentaro ISHITOYA. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "MetaMovicsConnect.h"
#import "NSData+Digest.h"
#import "NSObject+SBJson.h"
#import "MetaMovicsConstants.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface MetaMovicsConnect(PrivateImplementation)
- (void)setupInitialState;
- (void)utfAppendBody:(NSMutableData *)body data:(NSString *)data;
- (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
               httpMethod:(NSString *)httpMethod;
- (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params;
- (NSMutableData *)generatePostBody:(NSDictionary *)params 
                    dataContentType:(NSString*)dataContentType;
- (MetaMovicsRequest *) createRequestWithURLString:(NSString *)url 
                                        param:(NSDictionary *)params 
                                   httpMethod:(NSString *)httpMethod
                              dataContentType:(NSString *)dataContentType
                                  andDelegate:(id<MetaMovicsRequestDelegate>)delegate;
- (MetaMovicsRequest *) createRequestWithURLString:(NSString *)url 
                                        param:(NSDictionary *)params 
                                   httpMethod:(NSString *)httpMethod
                                       andDelegate:(id<MetaMovicsRequestDelegate>)delegate;
- (MetaMovicsRequest *) createRequestWithURLString2:(NSString *)url
                                             param:(NSDictionary *)params
                                        httpMethod:(NSString *)httpMethod
                                       andDelegate:(id<MetaMovicsRequestDelegate>)delegate;
- (NSDictionary *) dictionaryToPostString:(NSDictionary *)dict andKey:(NSString *)key;
@end

@implementation MetaMovicsConnect(PrivateImplementation)
/*!
 * initialize
 */
- (void)setupInitialState{
    requests_ = [[NSMutableSet alloc] init];
}

/*!
  * Body append for POST method
  */
- (void)utfAppendBody:(NSMutableData *)body data:(NSString *)data {
    [body appendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
}

/**
 * Generate get URL
 */
- (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params {
    return [self serializeURL:baseUrl params:params httpMethod:kHTTPGET];
}

/**
 * Generate get URL
 */
- (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
               httpMethod:(NSString *)httpMethod {
    baseUrl = [NSString stringWithFormat:@"%@/%@", kMetaMovicsBaseURL, baseUrl];
    NSURL* parsedURL = [NSURL URLWithString:baseUrl];
    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
    
    NSMutableArray* pairs = [NSMutableArray array];
    if([httpMethod isEqualToString:@"GET"]){
        for (NSString* key in [params keyEnumerator]) {
            if (([[params valueForKey:key] isKindOfClass:[UIImage class]])
                ||([[params valueForKey:key] isKindOfClass:[NSData class]])) {
                if ([httpMethod isEqualToString:@"GET"]) {
                    NSLog(@"can not use GET to upload a file");
                }
                continue;
            }
            
            NSString* escaped_value =
            (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                  (__bridge CFStringRef)[params objectForKey:key],
                                                                                  NULL,
                                                                                  (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                  kCFStringEncodingUTF8);
            
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
        }
    }
    NSString* query = [pairs componentsJoinedByString:@"&"];
    
    return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

/*!
 * Generate body for POST method
 */
- (NSMutableData *)generatePostBody:(NSDictionary *)params dataContentType:(NSString *)dataContentType{
    NSMutableData *body = [NSMutableData data];
    NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    [self utfAppendBody:body data:[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]];
    
    for (id key in [params keyEnumerator]) {
        
        if (([[params valueForKey:key] isKindOfClass:[UIImage class]])
            ||([[params valueForKey:key] isKindOfClass:[NSData class]])) {
            
            [dataDictionary setObject:[params valueForKey:key] forKey:key];
            continue;
            
        }
        
        [self utfAppendBody:body
                       data:[NSString
                             stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",
                             key]];
        [self utfAppendBody:body data:[params valueForKey:key]];
        
        [self utfAppendBody:body data:endLine];
    }
    
    NSLog(@"%@", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
    if ([dataDictionary count] > 0) {
        for (id key in dataDictionary) {
            NSObject *dataParam = [dataDictionary valueForKey:key];
            if ([dataParam isKindOfClass:[UIImage class]]) {
                dataParam = UIImageJPEGRepresentation((UIImage*)dataParam, 1.0);
            }
            NSAssert([dataParam isKindOfClass:[NSData class]],
                     @"dataParam must be a UIImage or NSData");
            [self utfAppendBody:body
                           data:[NSString stringWithFormat:
                                 @"Content-Disposition: form-data; filename=\"%@\"; name=\"%@\"\r\n", key, key]];
            if(dataContentType){
                [self utfAppendBody:body
                               data:[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", dataContentType]];
            }else{
                [self utfAppendBody:body
                               data:@"Content-Type: content/unknown\r\n\r\n"];
            }
            [body appendData:(NSData*)dataParam];
            [self utfAppendBody:body data:endLine];
            
        }
    }
    //NSLog(@"%@", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
    
    return body;
}

/*!
 * create request
 */
- (MetaMovicsRequest *) createRequestWithURLString:(NSString *)url param:(NSDictionary *)params httpMethod:(NSString *)httpMethod andDelegate:(id<MetaMovicsRequestDelegate>)delegate{
    return [self createRequestWithURLString:url param:params httpMethod:httpMethod dataContentType:nil andDelegate:delegate];
}


/*!
 * create request
 */
- (MetaMovicsRequest *) createRequestWithURLString2:(NSString *)url param:(NSDictionary *)params httpMethod:(NSString *)httpMethod andDelegate:(id<MetaMovicsRequestDelegate>)delegate{
    
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator]) {
        if (([[params valueForKey:key] isKindOfClass:[UIImage class]])
            ||([[params valueForKey:key] isKindOfClass:[NSData class]])) {
            if ([httpMethod isEqualToString:@"GET"]) {
                NSLog(@"can not use GET to upload a file");
            }
            continue;
        }
        
        NSString* escaped_value =
        (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                              (__bridge CFStringRef)[params objectForKey:key],
                                                                              NULL,
                                                                              (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                              kCFStringEncodingUTF8);
        
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    NSString* query = [pairs componentsJoinedByString:@"&"];
    NSString *serializedUrl = [self serializeURL:url params:params httpMethod:httpMethod];
    
    NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serializedUrl]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kTimeoutInterval];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    
    
    [request setHTTPMethod:httpMethod];
    [request setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
    return [[MetaMovicsRequest alloc] initWithURLRequest:request andDelegate:delegate];
}

/*!
 * create request
 */
- (MetaMovicsRequest *)createRequestWithURLString:(NSString *)url param:(NSDictionary *)params httpMethod:(NSString *)httpMethod dataContentType:(NSString *)dataContentType andDelegate:(id<MetaMovicsRequestDelegate>)delegate{
    
    NSString *serializedUrl = [self serializeURL:url params:params httpMethod:httpMethod];
    NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serializedUrl]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kTimeoutInterval];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    
    
    [request setHTTPMethod:httpMethod];
    if ([httpMethod isEqualToString: @"POST"]) {
        NSString* contentType = [NSString
                                 stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        [request setHTTPBody:[self generatePostBody:params dataContentType:dataContentType]];
    }
    return [[MetaMovicsRequest alloc] initWithURLRequest:request andDelegate:delegate];    
}

- (NSDictionary *) dictionaryToPostString:(NSDictionary *)dict andKey:(NSString *)key{
    NSMutableDictionary *retval = [[NSMutableDictionary alloc] init];
    for(id k in dict){
        id value = [dict objectForKey:k];
        NSString *newkey = k;
        if(key != nil){
            newkey = [NSString stringWithFormat:@"%@[%@]", key, k];
        }
        
        if([value isKindOfClass:[NSDictionary class]]){
            NSDictionary *subDict = [self dictionaryToPostString:value andKey:newkey];
            for(id subkey in subDict){
                [retval setObject:[subDict objectForKey:subkey] forKey:subkey];
            }
        }else{
            [retval setObject:value forKey:newkey];
        }
    }
    return retval;
}
@end
//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public implementation
@implementation MetaMovicsConnect
@synthesize sessionDelegate = sessionDelegate_;
/*!
 * initialize
 */
- (id)initWithUsername:(NSString *)username
              password:(NSString *)password
                 token:(NSString *)token
           andDelegate:(id<MetaMovicsSessionDelegate>)delegate{
    self = [super init];
    if(self){
        auth_ = [[MetaMovicsAuth alloc] initWithUsername:username password:password token:token andDelegate:self];
        self.sessionDelegate = delegate;
        [self setupInitialState];
    }
    return self;
}

#pragma mark - authentication
/*!
 * login
 */
- (void)loginWithUsername:(NSString *)username password:(NSString *)password andPermission:(NSArray *)permission{
    if([auth_ isSessionValid] == NO){
        [auth_ loginWithUsername:username andPassword:password];
    }else{
        [self metamovicsDidLogin];
    }
}

/*!
 * logout
 */
- (void)logout{
    if([auth_ isSessionValid]){
        [auth_ logout];
    }else{
        [self metamovicsDidLogout];
    }
}

/*!
 * did logined
 */
- (void)metamovicsDidLogin{
    [self.sessionDelegate metamovicsDidLogin];
}

/*!
 * did logout
 */
- (void)metamovicsDidLogout{
    [auth_ clearCredential];
    [self.sessionDelegate metamovicsDidLogout];
}

/*!
 * did not login
 */
- (void)metamovicsDidNotLogin{
    [auth_ clearCredential];
    [self.sessionDelegate metamovicsDidNotLogin];
}

/*!
 * is session valid
 */
- (BOOL)isSessionValid{
    return [auth_ isSessionValid];
}

/*!
 * refresh token
 */
- (void)refreshCredentialWithUsername:(NSString *)username password:(NSString *)password andPermission:(NSArray *)permission
{
    [auth_ loginWithUsername:username andPassword:password];
}

#pragma mark - get upload session token
/*!
 * get upload session token
 */
- (MetaMovicsRequest *)getUploadSessionTokenWithDelegate:(id<MetaMovicsRequestDelegate>)delegate{
    MetaMovicsRequest *request = [self createRequestWithURLString:@"create_upload_session" param:nil httpMethod:kHTTPGET andDelegate:delegate];
    request.tag = kMetaMovicsRequestGetSessionToken;
    [request start];
    return request;
}

/*!
 * upload file
 */
- (MetaMovicsRequest *)uploadVideoFileWithSessionId:(NSString *)sessionId
                                           duration:(int) duration
                                              width:(int) width
                                             height:(int) height
                                               data:(NSData *)data
                                        andDelegate:(id<MetaMovicsRequestDelegate>)delegate{
    NSDictionary *param = @{
        @"upload_session": @{ @"id" : sessionId },
        @"token": auth_.token,
        @"video": @{
            @"original_filename" : @"tottepost.mp4",
            @"original_duration_msec" : [NSString stringWithFormat:@"%d", duration],
            @"original_size" : [NSString stringWithFormat:@"%d", data.length],
            @"original_digest" : data.MD5DigestString
        },
        @"video_files" : @{
            @"1" : @{
                @"width": [NSString stringWithFormat:@"%d", width],
                @"height" : [NSString stringWithFormat:@"%d", height],
                @"size" : [NSString stringWithFormat:@"%d", data.length],
                @"pixel_aspect_ratio" : @"1:1",
                @"display_aspect_ratio" : @"4:3"
            }
        }
    };
    NSMutableDictionary *params =
        [NSMutableDictionary dictionaryWithDictionary:
                [self dictionaryToPostString:param andKey:nil]];
    [params setObject:data forKey:@"zipfile"];
    MetaMovicsRequest *request =
        [self createRequestWithURLString:@"upload" param:params
                              httpMethod:kHTTPPOST dataContentType:@"application/zip" andDelegate:delegate];
    
    request.tag = kMetaMovicsRequestUpload;
    [request start];
    return request;
}

/*!
 * upload file
 */
- (MetaMovicsRequest *)createPageWithVideoId:(NSString *)videoId
                                  categoryId:(NSString *)categoryId
                                     caption:(NSString *)caption
                                 andDelegate:(id<MetaMovicsRequestDelegate>)delegate{
    if(caption == nil || [caption isEqualToString:@""]){
        caption = @"tottepost";
    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyyMMdd";
    
    NSDictionary *params = @{
        @"token": auth_.token,
        @"content": @{
            @"title" : caption,
            @"is_published" : @"true",
            @"date_to_open" : [df stringFromDate:[NSDate date]]
        },
        @"video_id" : videoId,
        @"tag_id" : categoryId
    };
    params =
        [NSMutableDictionary dictionaryWithDictionary:
            [self dictionaryToPostString:params andKey:nil]];
    MetaMovicsRequest *request =
    [self createRequestWithURLString2:@"content" param:params
                          httpMethod:kHTTPPOST andDelegate:delegate];
    
    request.tag = kMetaMovicsRequestCreatePage;
    [request start];
    return request;
}

/*!
 * get token
 */
- (NSString *) token{
    return auth_.token;
}
@end
