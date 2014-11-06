//
//  ENGPhotoSubmitterAccountTableViewController.h
//
//  Created by Kentaro ISHITOYA on 12/02/18.
//

#import <UIKit/UIKit.h>
#import "ENGPhotoSubmitterProtocol.h"

@interface ENGPhotoSubmitterAccountTableViewController : UITableViewController<UITextFieldDelegate>{
    __strong UITextField *usernameTextField_;
    __strong UITextField *passwordTextField_;
    BOOL isDone_;
}

- (void)didLogin;
- (void)didLoginFailed;

@property (nonatomic, assign) id<ENGPhotoSubmitterPasswordAuthViewDelegate> delegate;
@end
