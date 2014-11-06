//
//  MailPhotoSubmitter.h
//  PhotoSubmitter for Twitter
//
//  Created by ISHITOYA Kentaro on 11/12/17.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#import "PhotoSubmitter.h"
#import "PhotoSubmitterProtocol.h"
#import "MailPhotoSubmitterSettingTableViewController.h"
#import <MessageUI/MessageUI.h>

@interface MailPhotoSubmitter : PhotoSubmitter<PhotoSubmitterInstanceProtocol, MFMailComposeViewControllerDelegate>{
    __strong MailPhotoSubmitterSettingTableViewController *settingView_;
}

@property (nonatomic, assign) BOOL commentAsSubject;
@property (nonatomic, assign) BOOL commentAsBody;
@property (nonatomic, assign) BOOL confirm;
@property (nonatomic, strong) NSString *defaultSubject;
@property (nonatomic, strong) NSString *defaultBody;
@property (nonatomic, strong) NSString *sendTo;
@property (nonatomic, readonly) BOOL validSendTo;
@end
