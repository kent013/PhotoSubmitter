//
//  PhotoSubmitterContentEntity.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/03/16.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "PhotoSubmitterContentEntity.h"
#import "NSData+Digest.h"
#import "NSData+Base64.h"
#import "PhotoSubmitterSettings.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface PhotoSubmitterContentEntity(PrivateImplementatio)
@end

@implementation PhotoSubmitterContentEntity(PrivateImplementation)
@end

//-----------------------------------------------------------------------------
//Public Implementations
//----------------------------------------------------------------------------
@implementation PhotoSubmitterContentEntity
@synthesize data = data_;
@synthesize timestamp = timestamp_;
@synthesize path = path_;
@synthesize contentHash = contentHash_;
@synthesize comment;
@synthesize location;

/*!
 * init
 */
- (id)init{
    self = [super init];
    if(self){
        timestamp_ = [NSDate date];
    }
    return self;    
}

/*!
 * init with data
 */
- (id)initWithData:(NSData *)inData{
    self = [self init];
    if(self){
        data_ = inData;
        timestamp_ = [NSDate date];
    }
    return self;
}

/*!
 * init with data
 */
- (id)initWithPath:(NSString *)inPath{
    self = [self init];
    if(self){
        path_ = inPath;
        data_ = [NSData dataWithContentsOfFile:inPath];
        timestamp_ = [NSDate date];
    }
    return self;
}

/*!
 * md5 hash
 */
- (NSString *)md5{
    return self.data.MD5DigestString;
}

/*!
 * populate base64 data
 */
- (NSString *)base64String{
    NSString *base64 = [self.data base64EncodedString];
    return [base64 stringByReplacingOccurrencesOfString:@"\r" withString:@""];
}


/*!
 * get photo hash
 */
- (NSString *)contentHash{
    if(contentHash_ == nil){
        contentHash_ = self.md5;
    }
    return contentHash_;
}

/*!
 * encode
 */
- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:data_ forKey:@"data"];
    [coder encodeObject:timestamp_ forKey:@"timestamp"];
    [coder encodeObject:path_ forKey:@"path"];
}

/*!
 * init with coder
 */
- (id)initWithCoder:(NSCoder*)coder {
    self = [super init];
    if (self) {
        data_ = [coder decodeObjectForKey:@"data"]; 
        timestamp_ = [coder decodeObjectForKey:@"timestamp"];
        path_ = [coder decodeObjectForKey:@"path"];
    }
    return self;
}

/*!
 * type
 */
- (PhotoSubmitterContentType)type{
    return PhotoSubmitterContentTypeUnknown;
}

/*!
 * check is photo
 */
- (BOOL)isPhoto{
    return self.type == PhotoSubmitterContentTypePhoto;
}

/*!
 * check is video
 */
- (BOOL)isVideo{
    return self.type == PhotoSubmitterContentTypeVideo;
}
@end
