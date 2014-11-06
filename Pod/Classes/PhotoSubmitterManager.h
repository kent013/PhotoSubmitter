//
//  PhotoSubmitter.h
//  tottepost
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PhotoSubmitterImageEntity.h"
#import "PhotoSubmitterAccount.h"
#import "PhotoSubmitterSequencialOperationQueue.h"
#import "PhotoSubmitterServiceSettingViewFactory.h"

@protocol PhotoSubmitterManagerDelegate;

/*!
 * photo submitter aggregation class
 */
@interface PhotoSubmitterManager : NSObject<CLLocationManagerDelegate, PhotoSubmitterPhotoDelegate, PhotoSubmitterOperationDelegate, PhotoSubmitterSequencialOperationQueueDelegate>{
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
    int errorOperationCount_;
    
    /*!
     * an array of id<PhotoSubmitterPhotoDelegate>
     */
    __strong NSMutableArray *photoDelegates_;
    id<PhotoSubmitterAuthenticationDelegate> authDelegate_;
}

@property (nonatomic, assign) id<PhotoSubmitterNavigationControllerDelegate> navigationControllerDelegate;
@property (nonatomic, assign) id<PhotoSubmitterAuthenticationDelegate> authenticationDelegate;
@property (nonatomic, readonly) int enabledSubmitterCount;
@property (nonatomic, readonly) int uploadOperationCount;
@property (nonatomic, readonly) int errorOperationCount;
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
@property (nonatomic, assign) id<PhotoSubmitterSettingViewFactoryProtocol> settingViewFactory;

- (void) submitPhoto:(PhotoSubmitterImageEntity *)photo;
- (void) submitVideo:(PhotoSubmitterVideoEntity *)video;
- (void) loadSubmitters;
- (void) suspend;
- (void) wakeup;
- (void) pause;
- (void) cancel;
- (void) restart;
- (void) refreshCredentials;
- (id<PhotoSubmitterProtocol>) submitterForAccount:(PhotoSubmitterAccount *)account;
- (void) removeSubmitterForAccount:(PhotoSubmitterAccount *)account;
- (NSArray *) submittersForType:(NSString *)type;
- (BOOL) didOpenURL: (NSURL *)url;

- (void) addDelegate:(id<PhotoSubmitterManagerDelegate>)delegate;
- (void) removeDelegate:(id<PhotoSubmitterManagerDelegate>)delegate;
- (void) clearDelegate;

- (void) addPhotoDelegate:(id<PhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) removePhotoDelegate: (id<PhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) clearPhotoDelegate;

+ (PhotoSubmitterManager *)sharedInstance;
+ (id<PhotoSubmitterProtocol>) submitterForAccount:(PhotoSubmitterAccount *)account;
+ (void) removeSubmitterForAccount:(PhotoSubmitterAccount *)account;
+ (int) registeredPhotoSubmitterCount;
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


@protocol PhotoSubmitterManagerDelegate <NSObject>
- (void) photoSubmitterManager:(PhotoSubmitterManager *)photoSubmitterManager didOperationAdded:(PhotoSubmitterOperation *)operation;
- (void) didUploadCanceled;
@end