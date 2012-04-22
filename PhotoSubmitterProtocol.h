//
//  PhotoSubmitterProtocol.h
//  tottepost
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoSubmitterAlbumEntity.h"
#import "PhotoSubmitterContentEntity.h"
#import "PhotoSubmitterImageEntity.h"
#import "PhotoSubmitterVideoEntity.h"

@protocol PhotoSubmitterAuthenticationDelegate;
@protocol PhotoSubmitterPhotoDelegate;
@protocol PhotoSubmitterPhotoOperationDelegate;
@protocol PhotoSubmitterDataDelegate;
@protocol PhotoSubmitterNavigationControllerDelegate;
@protocol PhotoSubmitterAlbumDelegate;

@class PhotoSubmitterServiceSettingTableViewController;
@class PhotoSubmitterAccount;

/*!
 * protocol for submitter
 */
@protocol PhotoSubmitterProtocol <NSObject>
@required
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) UIImage *icon;
@property (nonatomic, readonly) UIImage *smallIcon;
@property (nonatomic, readonly) BOOL isLogined;
@property (nonatomic, readonly) BOOL isEnabled;
@property (nonatomic, readonly) BOOL isConcurrent;
@property (nonatomic, readonly) BOOL useOperation;
@property (nonatomic, readonly) BOOL isSequencial;
@property (nonatomic, readonly) BOOL isAlbumSupported;
@property (nonatomic, readonly) BOOL isVideoSupported;
@property (nonatomic, readonly) BOOL isPhotoSupported;
@property (nonatomic, readonly) BOOL isMultipleAccountSupported;
@property (nonatomic, readonly) BOOL isSessionValid;
@property (nonatomic, readonly) BOOL requiresNetwork;
@property (nonatomic, assign) id<PhotoSubmitterAuthenticationDelegate> authDelegate;
@property (nonatomic, assign) id<PhotoSubmitterDataDelegate> dataDelegate;
@property (nonatomic, assign) id<PhotoSubmitterAlbumDelegate> albumDelegate;
@property (nonatomic, assign) PhotoSubmitterAlbumEntity *targetAlbum;
@property (nonatomic, assign) NSString *username;
@property (nonatomic, assign) NSArray *albumList;
@property (nonatomic, readonly) PhotoSubmitterServiceSettingTableViewController *settingView;
@property (nonatomic, readonly) NSInteger maximumLengthOfComment;
@property (nonatomic, readonly) NSInteger maximumLengthOfVideo;
@property (nonatomic, readonly) PhotoSubmitterAccount *account;

- (id) initWithAccount:(PhotoSubmitterAccount *)account;
- (void) login;
- (void) logout;
- (void) enable;
- (void) disable;
- (void) refreshCredential;
- (void) clearCredentials;
- (void) submitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate;
- (void) submitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate;
- (void) cancelContentSubmit:(PhotoSubmitterContentEntity *)content;
- (BOOL) isProcessableURL:(NSURL *)url;
- (BOOL) didOpenURL:(NSURL *)url;
- (void) addPhotoDelegate:(id<PhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) removePhotoDelegate: (id<PhotoSubmitterPhotoDelegate>)photoDelegate;

- (void) updateAlbumListWithDelegate: (id<PhotoSubmitterDataDelegate>) delegate;
- (void) updateUsernameWithDelegate: (id<PhotoSubmitterDataDelegate>) delegate;
- (void) createAlbum:(NSString *)title withDelegate:(id<PhotoSubmitterAlbumDelegate>)delegate;
- (void) presentAuthenticationView:(UIViewController *)viewController;
- (void) presentModalViewController: (UIViewController *)viewController;
- (void) dismissModalViewController;
@end

/*!
 * protocol for submitter
 */
@protocol PhotoSubmitterInstanceProtocol <NSObject>
- (void) onLogin;
- (void) onLogout;
- (id) onSubmitPhoto:(PhotoSubmitterImageEntity *)photo andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate;
- (id) onSubmitVideo:(PhotoSubmitterVideoEntity *)video andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate;
- (id) onCancelContentSubmit:(PhotoSubmitterContentEntity *)content;
- (PhotoSubmitterServiceSettingTableViewController *)settingViewInternal;
@end

/*!
 * protocol for authentication delegate
 */
@protocol PhotoSubmitterAuthenticationDelegate <NSObject>
@required
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter willBeginAuthorization:(PhotoSubmitterAccount *)account;
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didAuthorizationFinished:(PhotoSubmitterAccount *)account;
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didLogin:(PhotoSubmitterAccount *)account;
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didLogout:(PhotoSubmitterAccount *)account;
@end

/*!
 * protocol for photo delegate
 */
@protocol PhotoSubmitterPhotoDelegate <NSObject>
@required
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter willStartUpload:(NSString *)imageHash;
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didSubmitted:(NSString *)imageHash suceeded:(BOOL)suceeded message:(NSString *)message;
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didProgressChanged:(NSString *)imageHash progress:(CGFloat)progress;
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didCanceled:(NSString *)imageHash;
@end

/*!
 * protocol for operation
 */
@protocol PhotoSubmitterPhotoOperationDelegate <NSObject>
- (void) photoSubmitterDidOperationFinished:(BOOL)suceeded;
- (void) photoSubmitterDidOperationCanceled;
@property (nonatomic, readonly) BOOL isCancelled;
@end

/*!
 * protocol for fetch data
 */
@protocol PhotoSubmitterDataDelegate <NSObject>
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didAlbumUpdated: (NSArray *)albums;
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didUsernameUpdated: (NSString *)username;
@end


/*!
 * protocol for album
 */
@protocol PhotoSubmitterAlbumDelegate <NSObject>
- (void) photoSubmitter:(id<PhotoSubmitterProtocol>)photoSubmitter didAlbumCreated: (PhotoSubmitterAlbumEntity *)album suceeded:(BOOL)suceeded withError:(NSError *)error;
@end

/*!
 * protocol for request authentication view
 */
@protocol PhotoSubmitterNavigationControllerDelegate <NSObject>
- (UINavigationController *) requestNavigationControllerForPresentAuthenticationView;
- (UIViewController *)requestRootViewControllerForPresentModalView;
@end

/*!
 * protocol for request account info
 */
@protocol PhotoSubmitterPasswordAuthViewDelegate <NSObject>
- (void) didCancelPasswordAuthView: (UIViewController *)passwordAuthViewController;
- (void) passwordAuthView: (UIViewController *)passwordAuthViewController didPresentUserId:(NSString *)userId password:(NSString *)password;
@end

/*!
 * setting view factory delegate
 */
@protocol PhotoSubmitterSettingViewFactoryProtocol
- (id)createSettingViewWithSubmitter:(id<PhotoSubmitterProtocol>)submitter;
@end