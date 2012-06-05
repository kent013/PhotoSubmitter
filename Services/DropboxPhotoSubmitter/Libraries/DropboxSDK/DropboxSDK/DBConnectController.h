//
//  DBConnectController.h
//  DropboxSDK
//
//  Created by Brian Smith on 5/4/12.
//  Copyright (c) 2012 Dropbox, Inc. All rights reserved.
//

@interface DBConnectController : UIViewController

- (id)initWithUrl:(NSURL *)url;

@property (assign, nonatomic) BOOL isModal;

@end
