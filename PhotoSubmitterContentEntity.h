//
//  PhotoSubmitterContentEntity.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/03/16.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum{
    PhotoSubmitterContentTypeUnknown,
    PhotoSubmitterContentTypePhoto,
    PhotoSubmitterContentTypeVideo
} PhotoSubmitterContentType;

@interface PhotoSubmitterContentEntity : NSObject<NSCoding>{
__strong NSData *data_;
__strong NSDate *timestamp_;
__strong NSString *path_;
__strong NSString *contentHash_;
}

@property (strong, nonatomic) NSString *comment;
@property (strong, nonatomic) NSString *path;
@property (strong, nonatomic) NSString *contentHash;
@property (strong, nonatomic) CLLocation *location;
@property (readonly, nonatomic) NSData *data;
@property (readonly, nonatomic) NSString *base64String;
@property (readonly, nonatomic) NSString *md5;
@property (readonly, nonatomic) NSDate *timestamp;
@property (readonly, nonatomic) PhotoSubmitterContentType type;
@property (readonly, nonatomic) BOOL isVideo;
@property (readonly, nonatomic) BOOL isPhoto;

- (id) initWithData:(NSData *)data;
- (id) initWithPath:(NSString *)path;
@end
