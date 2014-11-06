//
//  ENGPhotoSubmitterManager.h
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "ENGPhotoSubmitterImageEntity.h"
#import "ENGPhotoSubmitterAccount.h"
#import "ENGPhotoSubmitterSequencialOperationQueue.h"
#import "ENGPhotoSubmitterServiceSettingViewFactory.h"

@protocol ENGPhotoSubmitterManagerDelegate;

/*!
 * photo submitter aggregation class
 */
@interface ENGPhotoSubmitterManager : NSObject<CLLocationManagerDelegate, ENGPhotoSubmitterPhotoDelegate, ENGPhotoSubmitterOperationDelegate, ENGPhotoSubmitterSequencialOperationQueueDelegate>{
    @protected 
    __strong NSMutableDictionary *submitters_;
    __strong NSMutableDictionary *operations_;
    __strong NSMutableDictionary *sequencialOperationQueues_;
    __strong NSOperationQueue *operationQueue_;
    __strong NSMutableArray *delegates_;
    __strong CLLocationManager *locationManager_;
    __strong CLLocation *location_;
    BOOL geoTaggingEnabled_;
    BOOL isPausingOperation_;
    BOOL isConnected_;
    BOOL isError_;
    NSInteger errorOperationCount_;
    
    /*!
     * an array of id<PhotoSubmitterPhotoDelegate>
     */
    __strong NSMutableArray *photoDelegates_;
    id<ENGPhotoSubmitterAuthenticationDelegate> authDelegate_;
}

@property (nonatomic, assign) id<ENGPhotoSubmitterNavigationControllerDelegate> navigationControllerDelegate;
@property (nonatomic, assign) id<ENGPhotoSubmitterAuthenticationDelegate> authenticationDelegate;
@property (nonatomic, readonly) NSInteger enabledSubmitterCount;
@property (nonatomic, readonly) NSInteger uploadOperationCount;
@property (nonatomic, readonly) NSInteger errorOperationCount;
@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, assign) BOOL submitPhotoWithOperations;
@property (nonatomic, assign) BOOL enableGeoTagging;
@property (nonatomic, readonly) BOOL requiresNetwork;
@property (nonatomic, readonly) BOOL isUploading;
@property (nonatomic, readonly) BOOL isError;
@property (nonatomic, readonly) BOOL isPausingOperation;
@property (nonatomic, readonly) BOOL isSquarePhotoRequired;
@property (nonatomic, readonly) NSInteger maxCommentLength;
@property (nonatomic, readonly) NSArray *submitters;
@property (nonatomic, assign) id<ENGPhotoSubmitterSettingViewFactoryProtocol> settingViewFactory;

- (void) submitPhoto:(ENGPhotoSubmitterImageEntity *)photo;
- (void) submitVideo:(ENGPhotoSubmitterVideoEntity *)video;
- (void) loadSubmitters;
- (void) suspend;
- (void) wakeup;
- (void) pause;
- (void) cancel;
- (void) restart;
- (void) refreshCredentials;
- (id<ENGPhotoSubmitterProtocol>) submitterForAccount:(ENGPhotoSubmitterAccount *)account;
- (void) removeSubmitterForAccount:(ENGPhotoSubmitterAccount *)account;
- (NSArray *) submittersForType:(NSString *)type;
- (BOOL) didOpenURL: (NSURL *)url;

- (void) addDelegate:(id<ENGPhotoSubmitterManagerDelegate>)delegate;
- (void) removeDelegate:(id<ENGPhotoSubmitterManagerDelegate>)delegate;
- (void) clearDelegate;

- (void) addPhotoDelegate:(id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) removePhotoDelegate: (id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) clearPhotoDelegate;

+ (ENGPhotoSubmitterManager *)sharedInstance;
+ (id<ENGPhotoSubmitterProtocol>) submitterForAccount:(ENGPhotoSubmitterAccount *)account;
+ (void) removeSubmitterForAccount:(ENGPhotoSubmitterAccount *)account;
+ (NSInteger) registeredPhotoSubmitterCount;
+ (BOOL) isSubmitterEnabledForType:(NSString *)type;
+ (NSArray *) registeredPhotoSubmitters;
+ (void) unregisterAllPhotoSubmitters;
+ (void) unregisterPhotoSubmitterWithTypeName:(NSString *)type;
+ (void) registerPhotoSubmitterWithTypeName:(NSString *)type;
+ (void) registerPhotoSubmitterWithTypeNames:(NSArray *)types;
+ (NSString *) normalizeTypeName:(NSString *)type;
+ (NSString *) photoSubmitterCustomSchemaSuffix;
+ (void) setPhotoSubmitterCustomSchemaSuffix:(NSString *)suffix;
@end


@protocol ENGPhotoSubmitterManagerDelegate <NSObject>
- (void) photoSubmitterManager:(ENGPhotoSubmitterManager *)photoSubmitterManager didOperationAdded:(ENGPhotoSubmitterOperation *)operation;
- (void) didUploadCanceled;
@end