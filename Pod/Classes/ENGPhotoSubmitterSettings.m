//
//  ENGPhotoSubmitterSettings.m
//
//  Created by ISHITOYA Kentaro on 11/12/21.
//

#import "ENGPhotoSubmitterSettings.h"
#import "ENGPhotoSubmitterManager.h"
#import "RegexKitLite.h"

/*!
 * singleton instance
 */
static ENGPhotoSubmitterSettings* PhotoSubmitterSettingsSingletonInstance;

#define PS_KEY_COMMENT_POST_ENABLED @"commentPostEnabled"
#define PS_KEY_GPS_ENABLED @"gpsEnabled"
#define PS_KEY_AUTO_ENHANCE @"autoEnhance"
#define PS_KEY_SUBMITTER_ENABLED_DATES @"submitterEnabledDates"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterSettings(PrivateImplementation)
- (void) writeSetting:(NSString *)key value:(id)value;
- (id)readSetting:(NSString *)key;
@end

@implementation ENGPhotoSubmitterSettings(PrivateImplementation)
/*!
 * write settings to user defaults
 */
- (void)writeSetting:(NSString *)key value:(id)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:value forKey:key];
    [defaults synchronize];
}

/*!
 * read settings from user defaults
 */
- (id)readSetting:(NSString *)key{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults valueForKey:key];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//----------------------------------------------------------------------------
@implementation ENGPhotoSubmitterSettings

- (id)init{
    self = [super init];
    if(self){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary* defaultValue = [[NSMutableDictionary alloc] init];
        NSArray* supportedTypes = [ENGPhotoSubmitterManager registeredPhotoSubmitters];
        [defaultValue setObject:supportedTypes forKey:PS_KEY_SUBMITTER_ENABLED_DATES];
        [defaults registerDefaults:defaultValue];
        [defaults synchronize];
        
    }
    return self;
}
#pragma mark -
#pragma mark values
/*!
 * get comment post enabled
 */
- (BOOL)commentPostEnabled{
    NSNumber *value = (NSNumber *)[self readSetting:PS_KEY_COMMENT_POST_ENABLED];
    if(value == nil){
        return NO;
    }
    return [value boolValue];
}

/*!
 * set comment post enabled
 */
- (void)setCommentPostEnabled:(BOOL)commentPostEnabled{
    [self writeSetting:PS_KEY_COMMENT_POST_ENABLED value:[NSNumber numberWithBool:commentPostEnabled]];
}

/*!
 * get gps enabled
 */
- (BOOL)gpsEnabled{
    NSNumber *value = (NSNumber *)[self readSetting:PS_KEY_GPS_ENABLED];
    if(value == nil){
        return NO;
    }
    return [value boolValue];
}

/*!
 * set gps enabled
 */
- (void)setGpsEnabled:(BOOL)gpsEnabled{
    [self writeSetting:PS_KEY_GPS_ENABLED value:[NSNumber numberWithBool:gpsEnabled]];
}

/*!
 * get auto enhance
 */
- (BOOL)autoEnhance{
    NSNumber *value = (NSNumber *)[self readSetting:PS_KEY_AUTO_ENHANCE];
    if(value == nil){
        return NO;
    }
    return [value boolValue];
}

/*!
 * set auto enhance
 */
- (void)setAutoEnhance:(BOOL)autoEnhance{
    [self writeSetting:PS_KEY_AUTO_ENHANCE value:[NSNumber numberWithBool:autoEnhance]];
}

/*!
 * get supported type indexes
 */
- (NSMutableDictionary *)submitterEnabledDates{
    id retval = [self readSetting:PS_KEY_SUBMITTER_ENABLED_DATES];
    
    if([retval isKindOfClass:[NSMutableDictionary class]]){
        NSMutableDictionary *dates = (NSMutableDictionary *)retval;
        if([[dates allKeys] objectAtIndex:0] != nil &&
           [[[dates allKeys] objectAtIndex:0] isKindOfClass:[NSString class]] &&
           [[[dates allKeys] objectAtIndex:0] isMatchedByRegex:@"PhotoSubmitter$"] == NO){
            return retval;
        }
    }
    [self writeSetting:PS_KEY_SUBMITTER_ENABLED_DATES value:nil];
    return nil;
}

/*!
 * set supported type indexes
 */
- (void)setSubmitterEnabledDates:(NSDictionary *)submitterEnabledDates{
    [self writeSetting:PS_KEY_SUBMITTER_ENABLED_DATES value:submitterEnabledDates];
}

#pragma mark -
#pragma mark static methods
/*!
 * singleton method
 */
+ (ENGPhotoSubmitterSettings *)getInstance{
    if(PhotoSubmitterSettingsSingletonInstance == nil){
        PhotoSubmitterSettingsSingletonInstance = [[ENGPhotoSubmitterSettings alloc] init];
    }
    return PhotoSubmitterSettingsSingletonInstance;
}
@end
