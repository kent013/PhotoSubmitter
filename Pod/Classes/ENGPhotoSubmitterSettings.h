//
//  ENGPhotoSubmitterSettings.h
//
//  Created by ISHITOYA Kentaro on 11/12/21.
//

#import <Foundation/Foundation.h>

@interface ENGPhotoSubmitterSettings : NSObject{
}
@property (nonatomic, assign) BOOL commentPostEnabled;
@property (nonatomic, assign) BOOL gpsEnabled;
@property (nonatomic, assign) BOOL autoEnhance;
@property (nonatomic, assign) NSDictionary *submitterEnabledDates;
+ (ENGPhotoSubmitterSettings *)getInstance;
@end


