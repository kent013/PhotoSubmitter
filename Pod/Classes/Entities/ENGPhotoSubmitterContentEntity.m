//
//  ENGPhotoSubmitterContentEntity.m
//
//  Created by Kentaro ISHITOYA on 12/03/16.
//

#import "Base64.h"
#import "ENGPhotoSubmitterSettings.h"
#import "ENGPhotoSubmitterContentEntity.h"
#import "NSData+ENGDigest.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterContentEntity(PrivateImplementatio)
@end

@implementation ENGPhotoSubmitterContentEntity(PrivateImplementation)
@end

//-----------------------------------------------------------------------------
//Public Implementations
//----------------------------------------------------------------------------
@implementation ENGPhotoSubmitterContentEntity
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
- (ENGPhotoSubmitterContentType)type{
    return ENGPhotoSubmitterContentTypeUnknown;
}

/*!
 * check is photo
 */
- (BOOL)isPhoto{
    return self.type == ENGPhotoSubmitterContentTypePhoto;
}

/*!
 * check is video
 */
- (BOOL)isVideo{
    return self.type == ENGPhotoSubmitterContentTypeVideo;
}
@end
