//
//  FilePhotoSubmitter.m
//  PhotoSubmitter for Camera Roll
//
//  Created by ISHITOYA Kentaro on 11/12/24.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "FilePhotoSubmitter.h"
#import "PhotoSubmitterManager.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface FilePhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
@end

@implementation FilePhotoSubmitter(PrivateImplementation)
#pragma mark - private implementations
/*!
 * initializer
 */
-(void)setupInitialState{
    [self setSubmitterIsConcurrent:NO 
                      isSequencial:NO 
                     usesOperation:NO 
                   requiresNetwork:NO 
                  isAlbumSupported:NO];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - public PhotoSubmitter Protocol implementations
@implementation FilePhotoSubmitter
/*!
 * initialize
 */
- (id)initWithAccount:(PhotoSubmitterAccount *)account{
    self = [super initWithAccount:account];
    if (self) {
        [self setupInitialState];
    }
    return self;
}

#pragma mark - authorization
/*!
 * login to file
 */
-(void)onLogin{
}

/*!
 * logoff from file
 */
- (void)onLogout{
}

/*!
 * is session valid
 */
- (BOOL)isSessionValid{
    return YES;
}

#pragma mark - photo
/*!
 * submit photo
 */
- (id)onSubmitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *hash = photo.contentHash;
        ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
        [lib writeImageDataToSavedPhotosAlbum:photo.data
                                     metadata:photo.metadata
                              completionBlock:^(NSURL* url, NSError* error)
        {
            [self photoSubmitter:self didProgressChanged:hash progress:0.75];
            if(error == nil){
                [self photoSubmitter:self didSubmitted:hash suceeded:YES message:@"Photo upload succeeded"];
            }else{
                [self photoSubmitter:self didSubmitted:hash suceeded:NO message:[error localizedDescription]];
            }
            id<PhotoSubmitterPhotoOperationDelegate> operationDelegate = [self operationDelegateForRequest:hash];
            [operationDelegate photoSubmitterDidOperationFinished:YES];
            [self clearRequest:hash];
        }];
        [self photoSubmitter:self willStartUpload:hash];
        [self photoSubmitter:self didProgressChanged:hash progress:0.25];
        [self setOperationDelegate:delegate forRequest:hash];
    });
    return nil;
}

/*!
 * submit video
 */
- (id)onSubmitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *hash = video.contentHash;
        ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
        [lib writeVideoAtPathToSavedPhotosAlbum:video.url 
                                completionBlock:^(NSURL* url, NSError* error)
         {
             [self photoSubmitter:self didProgressChanged:hash progress:0.75];
             if(error == nil){
                 [self photoSubmitter:self didSubmitted:hash suceeded:YES message:@"Photo upload succeeded"];
             }else{
                 [self photoSubmitter:self didSubmitted:hash suceeded:NO message:[error localizedDescription]];
             }
             id<PhotoSubmitterPhotoOperationDelegate> operationDelegate = [self operationDelegateForRequest:hash];
             [operationDelegate photoSubmitterDidOperationFinished:YES];
             [self clearRequest:hash];
         }];
        [self photoSubmitter:self willStartUpload:hash];
        [self photoSubmitter:self didProgressChanged:hash progress:0.25];
        [self setOperationDelegate:delegate forRequest:hash];
    });    
    return nil;
}

/*!
 * cancel content upload
 */
- (id)onCancelContentSubmit:(PhotoSubmitterContentEntity *)content{
    return nil;
}

#pragma mark - other properties
/*!
 * display name
 */
- (NSString *)displayName{
    return @"Camera Roll";
}

/*!
 * get setting view
 */
- (PhotoSubmitterServiceSettingTableViewController *)settingView{
    return nil;
}
@end
