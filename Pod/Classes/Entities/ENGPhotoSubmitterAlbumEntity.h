//
//  ENGPhotoSubmitterAlbumEntity.h
//
//  Created by ISHITOYA Kentaro on 11/12/22.
//

#import <Foundation/Foundation.h>

@interface ENGPhotoSubmitterAlbumEntity : NSObject<NSCoding>
@property (strong, nonatomic) NSString *albumId;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *privacy;

- (id)initWithId:(NSString*)albumId name:(NSString *)name privacy:(NSString *)privacy;
@end
