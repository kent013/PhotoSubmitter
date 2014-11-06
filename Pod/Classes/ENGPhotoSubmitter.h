//
//  ENGPhotoSubmitter.h
//
//  Created by ISHITOYA Kentaro on 11/12/17.
//

#import <Foundation/Foundation.h>
#import "ENGPhotoSubmitterProtocol.h"
#import "ENGPhotoSubmitterOperation.h"
#import "ENGPhotoSubmitterImageEntity.h"
#import "ENGPhotoSubmitterAccount.h"

/*!
 * this class manages 
 * image hash <-> request hash, conversion table for asyncronous request
 * and request objects.
 */
@interface ENGPhotoSubmitter : NSObject<ENGPhotoSubmitterProtocol>{
@private
    __strong NSMutableDictionary *photos_;
    __strong NSMutableDictionary *requests_;

    /*!
     * an array of id<ENGPhotoSubmitterOperationDelegate>
     */
    __strong NSMutableDictionary *operationDelegates_;
    
    /*!
     * an array of id<ENGPhotoSubmitterPhotoDelegate>
     */
    __strong NSMutableArray *photoDelegates_;
    
    /*!
     * account
     */
    __strong ENGPhotoSubmitterAccount *account_;
    
    BOOL isConcurrent_;
    BOOL isSequencial_;
    BOOL useOperation_;
    BOOL requiresNetwork_;
    BOOL isAlbumSupported_;
}

/*!
 * set photosubmitter's setting
 */
- (void) setSubmitterIsConcurrent:(BOOL)isConcurrent 
                     isSequencial:(BOOL)isSequencial 
                    usesOperation:(BOOL)usesOperation
                  requiresNetwork:(BOOL)requiresNetwork 
                 isAlbumSupported:(BOOL)isAlbumSupported;

/*!
 * send signal to delegates
 */
- (void) completeSubmitContentWithRequest:(id)request;
- (void) completeSubmitContentWithRequest:(id)request andError:(NSError *)error;
- (void) completeLogin;
- (void) completeLoginFailed;
- (void) completeLogout;

//request methods
- (void) addRequest:(NSObject *)request;
- (void) removeRequest:(NSObject *)request;
- (ENGPhotoSubmitterServiceSettingTableViewController *)settingViewInternal;

//operation delegate methods
- (void) setOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)operation forRequest:(NSObject *)request;
- (void) removeOperationDelegateForRequest:(NSObject *)request;
- (id<ENGPhotoSubmitterPhotoOperationDelegate>) operationDelegateForRequest:(NSObject *)request;

//photo delegate methods
- (void) addPhotoDelegate:(id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) removePhotoDelegate: (id<ENGPhotoSubmitterPhotoDelegate>)photoDelegate;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter willStartUpload:(NSString *)imageHash;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didSubmitted:(NSString *)imageHash suceeded:(BOOL)suceeded message:(NSString *)message;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didProgressChanged:(NSString *)imageHash progress:(CGFloat)progress;
- (void) photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didCanceled:(NSString *)imageHash;

//photo hash methods
- (void) setPhotoHash:(NSString *)photoHash forRequest:(NSObject *)request;
- (void) removePhotoForRequest:(NSObject *)request;
- (NSString*) photoForRequest:(NSObject *)request;
- (NSObject*) requestForPhoto:(NSString *)photoHash;

//util
- (void) clearRequest: (NSObject *)request;
- (void) recoverOldSettings;

//submit photo
- (void) submitPhoto:(ENGPhotoSubmitterImageEntity *)photo andOperationDelegate:(id<ENGPhotoSubmitterPhotoOperationDelegate>)delegate;

//setting methods
- (void)setSetting:(id)value forKey:(NSString *)key;
- (id)settingForKey:(NSString *)key;
- (void) removeSettingForKey: (NSString *)key;
- (BOOL) settingExistsForKey: (NSString *)key;
- (void)setComplexSetting:(id)value forKey:(NSString *)key;
- (id)complexSettingForKey:(NSString *)key;

//secure setting methods
- (void)setSecureSetting:(id)value forKey:(NSString *)key;
- (id)secureSettingForKey:(NSString *)key;
- (void) removeSecureSettingForKey: (NSString *)key;
- (BOOL) secureSettingExistsForKey: (NSString *)key;
@end
