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
#import "PhotoSubmitterSequencialOperationQueue.h"

@protocol PhotoSubmitterManagerDelegate;

/*!
 * photo submitter aggregation class
 */
@interface PhotoSubmitterManager : NSObject<CLLocationManagerDelegate, PhotoSubmitterPhotoDelegate, PhotoSubmitterOperationDelegate, PhotoSubmitterSequencialOperationQueueDelegate>{
    @protected 
    __strong NSMutableDictionary *submitters_;
    __strong NSMutableDictionary *operations_;
    __strong NSMutableDictionary *sequencialOperationQueues_;
    __strong NSMutableArray *loadedSubmitterTypes_;
    __strong NSOperationQueue *operationQueue_;
    __strong NSMutableArray *delegates_;
    __strong CLLocationManager *locationManager_;
    __strong CLLocation *location_;
    BOOL geoTaggingEnabled_;
    BOOL isPausingOperation_;
    BOOL isConnected_;
    
    /*!
     * an array of id<PhotoSubmitterPhotoDelegate>
     */
    __strong NSMutableArray *photoDelegates_;
}

@property (nonatomic, assign) id<PhotoSubmitterAuthControllerDelegate> authControllerDelegate;
@property (nonatomic, assign) id<PhotoSubmitterAuthenticationDelegate> authenticationDelegate;
@property (nonatomic, readonly) NSArray* loadedSubmitterTypes;
@property (nonatomic, readonly) int enabledSubmitterCount;
@property (nonatomic, readonly) int uploadOperationCount;
@property (nonatomic, readonly) CLLocation *location;
@property (nonatomic, assign) BOOL submitPhotoWithOperations;
@property (nonatomic, assign) BOOL enableGeoTagging;
@property (nonatomic, readonly) BOOL requiresNetwork;
@property (nonatomic, readonly) BOOL isUploading;
@property (nonatomic, readonly) BOOL isPausingOperation;

- (void) submitPhoto:(PhotoSubmitterImageEntity *)photo;
- (void) loadSubmitters;
- (void) suspend;
- (void) wakeup;
- (void) pause;
- (void) cancel;
- (void) restart;
- (void) refreshCredentials;
- (id<PhotoSubmitterProtocol>) submitterForType:(NSString *)type;
- (BOOL) didOpenURL: (NSURL *)url;

- (void) addDelegate:(id<PhotoSubmitterManagerDelegate>)delegate;
- (void) removeDelegate:(id<PhotoSubmitterManagerDelegate>)delegate;
- (void) clearDelegate;

- (void) addPhotoDelegate:(id<PhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) removePhotoDelegate: (id<PhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) clearPhotoDelegate;

+ (PhotoSubmitterManager *)sharedInstance;
+ (id<PhotoSubmitterProtocol>) submitterForType:(NSString *)type;
+ (int) registeredPhotoSubmitterCount;
+ (NSArray *) registeredPhotoSubmitters;
+ (void) unregisterAllPhotoSubmitters;
+ (void) unregisterPhotoSubmitterWithTypeName:(NSString *)type;
+ (void) registerPhotoSubmitterWithTypeName:(NSString *)type;
+ (void) registerPhotoSubmitterWithTypeNames:(NSArray *)types;
+ (NSString *) normalizeTypeName:(NSString *)type;
@end


@protocol PhotoSubmitterManagerDelegate <NSObject>
- (void) photoSubmitterManager:(PhotoSubmitterManager *)photoSubmitterManager didOperationAdded:(PhotoSubmitterOperation *)operation;
- (void) didUploadCanceled;
@end