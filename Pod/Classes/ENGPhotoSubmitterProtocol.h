//
//  ENGPhotoSubmitterProtocol.h
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//

#import <Foundation/Foundation.h>
#import "ENGPhotoSubmitterAlbumEntity.h"
#import "ENGPhotoSubmitterContentEntity.h"
#import "ENGPhotoSubmitterImageEntity.h"
#import "ENGPhotoSubmitterVideoEntity.h"

@protocol ENGPhotoSubmitterAuthenticationDelegate;
@protocol ENGPhotoSubmitterPhotoDelegate;
@protocol ENGPhotoSubmitterPhotoOperationDelegate;
@protocol ENGPhotoSubmitterDataDelegate;
@protocol ENGPhotoSubmitterNavigationControllerDelegate;
@protocol ENGPhotoSubmitterAlbumDelegate;

@class ENGPhotoSubmitterServiceSettingTableViewController;
@class ENGPhotoSubmitterAccount;

/*!
 * protocol for submitter
 */
@protocol ENGPhotoSubmitterProtocol <NSObject>
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
@property (nonatomic, readonly) BOOL isSquare;
@property (nonatomic, assign) id<ENGPhotoSubmitterAuthenticationDelegate> authDelegate;
@property (nonatomic, assign) id<ENGPhotoSubmitterDataDelegate> dataDelegate;
@property (nonatomic, assign) id<ENGPhotoSubmitterAlbumDelegate> albumDelegate;
@property (nonatomic, assign) ENGPhotoSubmitterAlbumEntity *targetAlbum;
@property (nonatomic, assign) NSString *username;
@property (nonatomic, assign) NSArray *albumList;
@property (nonatomic, readonly) ENGPhotoSubmitterServiceSettingTableViewController *settingView;
@property (nonatomic, readonly) NSInteger maximumLengthOfComment;
@property (nonatomic, readonly) NSInteger maximumLengthOfVideo;
@property (nonatomic, readonly) ENGPhotoSubmitterAccount *account;

- (id) initWithAccount:(ENGPhotoSubmitterAccount *)account;
- (void) login;
- (void) logout;
- (void) enable;
- (void) disable;
- (void) refreshCredential;
- (void) clearCredentials;
- (void) submitPhoto:(ENGPhotoSubmitterImageEntity *)photo andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate;
- (void) submitVideo:(ENGPhotoSubmitterVideoEntity *)video andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate;
- (void) cancelContentSubmit:(ENGPhotoSubmitterContentEntity *)content;
- (BOOL) isProcessableURL:(NSURL *)url;
- (BOOL) didOpenURL:(NSURL *)url;
- (void) addPhotoDelegate:(id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) removePhotoDelegate: (id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate;

- (void) updateAlbumListWithDelegate: (id<ENGPhotoSubmitterDataDelegate>) delegate;
- (void) updateUsernameWithDelegate: (id<ENGPhotoSubmitterDataDelegate>) delegate;
- (void) createAlbum:(NSString *)title withDelegate:(id<ENGPhotoSubmitterAlbumDelegate>)delegate;
- (void) presentAuthenticationView:(UIViewController *)viewController;
- (void) presentModalViewController: (UIViewController *)viewController;
- (void) dismissModalViewController;
@end

/*!
 * protocol for submitter
 */
@protocol ENGPhotoSubmitterInstanceProtocol <NSObject>
- (void) onLogin;
- (void) onLogout;
- (id) onSubmitPhoto:(ENGPhotoSubmitterImageEntity *)photo andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate;
- (id) onSubmitVideo:(ENGPhotoSubmitterVideoEntity *)video andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate;
- (id) onCancelContentSubmit:(ENGPhotoSubmitterContentEntity *)content;
- (ENGPhotoSubmitterServiceSettingTableViewController *)settingViewInternal;
@end

/*!
 * protocol for authentication delegate
 */
@protocol ENGPhotoSubmitterAuthenticationDelegate <NSObject>
@required
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter willBeginAuthorization:(ENGPhotoSubmitterAccount *)account;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didAuthorizationFinished:(ENGPhotoSubmitterAccount *)account;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didLogin:(ENGPhotoSubmitterAccount *)account;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didLogout:(ENGPhotoSubmitterAccount *)account;
@end

/*!
 * protocol for photo delegate
 */
@protocol ENGPhotoSubmitterPhotoDelegate <NSObject>
@required
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter willStartUpload:(NSString *)imageHash;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didSubmitted:(NSString *)imageHash suceeded:(BOOL)suceeded message:(NSString *)message;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didProgressChanged:(NSString *)imageHash progress:(CGFloat)progress;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didCanceled:(NSString *)imageHash;
@end

/*!
 * protocol for operation
 */
@protocol ENGPhotoSubmitterPhotoOperationDelegate <NSObject>
- (void) photoSubmitterDidOperationFinished:(BOOL)suceeded;
- (void) photoSubmitterDidOperationCanceled;
@property (nonatomic, readonly) BOOL isCancelled;
@end

/*!
 * protocol for fetch data
 */
@protocol ENGPhotoSubmitterDataDelegate <NSObject>
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didAlbumUpdated: (NSArray *)albums;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didUsernameUpdated: (NSString *)username;
@end


/*!
 * protocol for album
 */
@protocol ENGPhotoSubmitterAlbumDelegate <NSObject>
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didAlbumCreated: (ENGPhotoSubmitterAlbumEntity *)album suceeded:(BOOL)suceeded withError:(NSError *)error;
@end

/*!
 * protocol for request authentication view
 */
@protocol ENGPhotoSubmitterNavigationControllerDelegate <NSObject>
- (UINavigationController *) requestNavigationControllerForPresentAuthenticationView;
- (UIViewController *)requestRootViewControllerForPresentModalView;
@end

/*!
 * protocol for request account info
 */
@protocol ENGPhotoSubmitterPasswordAuthViewDelegate <NSObject>
- (void) didCancelPasswordAuthView: (UIViewController *)passwordAuthViewController;
- (void) passwordAuthView: (UIViewController *)passwordAuthViewController didPresentUserId:(NSString *)userId password:(NSString *)password;
@end

/*!
 * setting view factory delegate
 */
@protocol ENGPhotoSubmitterSettingViewFactoryProtocol
- (id)createSettingViewWithSubmitter:(id<ENGPhotoSubmitterProtocol>)submitter;
@end