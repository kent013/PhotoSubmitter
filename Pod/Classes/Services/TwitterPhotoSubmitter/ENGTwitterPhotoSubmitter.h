//
//  ENGTwitterPhotoSubmitter.h
//  PhotoSubmitter for Twitter
//
//  Created by ISHITOYA Kentaro on 11/12/17.
//

#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "ENGPhotoSubmitter.h"
#import "ENGPhotoSubmitterProtocol.h"
#import "ENGTwitterPhotoSubmitterSettingTableViewController.h"

@interface ENGTwitterPhotoSubmitter : ENGPhotoSubmitter<ENGPhotoSubmitterInstanceProtocol, NSURLConnectionDataDelegate, NSURLConnectionDelegate, UIAlertViewDelegate>{
    __strong ENGTwitterPhotoSubmitterSettingTableViewController *settingView_;
    __strong ACAccountStore *accountStore_;
    __strong NSString *defaultComment_;
}

@property (nonatomic, readonly) NSArray *accounts;
@property (nonatomic, assign) NSString *selectedAccountUsername;
@property (nonatomic, strong) NSString *defaultComment;
@end
