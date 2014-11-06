//
//  ENGPhotoSubmitterVideoEntity.h
//
//  Created by Kentaro ISHITOYA on 12/03/16.
//

#import "ENGPhotoSubmitterContentEntity.h"

@interface ENGPhotoSubmitterVideoEntity : ENGPhotoSubmitterContentEntity{
    NSURL *url_;
    int length_;
    int width_;
    int height_;
}

@property NSURL *url;
@property int length;
@property int width;
@property int height;
-(id)initWithUrl:(NSURL *)url;
@end
