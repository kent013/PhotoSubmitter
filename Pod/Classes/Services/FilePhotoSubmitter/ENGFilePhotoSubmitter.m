//
//  FilePhotoSubmitter.m
//  PhotoSubmitter for Camera Roll
//
//  Created by ISHITOYA Kentaro on 11/12/24.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "ENGFilePhotoSubmitter.h"
#import "ENGPhotoSubmitterManager.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGFilePhotoSubmitter(PrivateImplementation)
- (void) setupInitialState;
@end

@implementation ENGFilePhotoSubmitter(PrivateImplementation)
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
@implementation ENGFilePhotoSubmitter
/*!
 * initialize
 */
- (id)initWithAccount:(ENGPhotoSubmitterAccount *)account{
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
- (id)onSubmitPhoto:(ENGPhotoSubmitterImageEntity *)photo andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
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
            id<ENGPhotoSubmitterPhotoOperationDelegate> operationDelegate = [self operationDelegateForRequest:hash];
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
- (id)onSubmitVideo:(ENGPhotoSubmitterVideoEntity *)video andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate{
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
             id<ENGPhotoSubmitterPhotoOperationDelegate> operationDelegate = [self operationDelegateForRequest:hash];
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
- (id)onCancelContentSubmit:(ENGPhotoSubmitterContentEntity *)content{
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
- (ENGPhotoSubmitterServiceSettingTableViewController *)settingView{
    return nil;
}
@end
