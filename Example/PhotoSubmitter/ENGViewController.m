//
//  ENGViewController.m
//  PhotoSubmitter
//
//  Created by kent013 on 11/06/2014.
//  Copyright (c) 2014 kent013. All rights reserved.
//

#import "ENGViewController.h"
#import "ENGPhotoSubmitterManager.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGViewController(PrivateImplementation)
- (void) setupInitialState;
@end

@implementation ENGViewController(PrivateImplementation)
/*!
 * initialization
 */
- (void)setupInitialState{
    //You can enable specific services like this
    //[ENGPhotoSubmitterManager unregisterAllPhotoSubmitters];
    //[ENGPhotoSubmitterManager registerPhotoSubmitterWithTypeNames:[NSArray arrayWithObjects: @"facebook", @"twitter", @"dropbox", @"minus", @"file", nil]];
    
    //these three delegates are important.
    [[ENGPhotoSubmitterManager sharedInstance] addPhotoDelegate:self];
    [ENGPhotoSubmitterManager sharedInstance].navigationControllerDelegate = self;
    [ENGPhotoSubmitterManager sharedInstance].submitPhotoWithOperations = YES;
    
    //initialize setting view controller
    settingViewController_ = [[ENGPhotoSubmitterSettingTableViewController alloc] init];
    settingViewController_.delegate = self;
    settingNavigationController_ = [[UINavigationController alloc] initWithRootViewController:settingViewController_];
    settingNavigationController_.modalPresentationStyle = UIModalPresentationFormSheet;
    settingNavigationController_.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
}
@end

@implementation ENGViewController
/*!
 * when the photo taken, submit photo to logined services
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    ENGPhotoSubmitterImageEntity *photo = [[ENGPhotoSubmitterImageEntity alloc] initWithImage:image];
    [[ENGPhotoSubmitterManager sharedInstance] submitPhoto:photo];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - ENGPhotoSubmitterNavigationControllerDelegate
/*!
 * request UINavigationController to present authentication view
 */
- (UINavigationController *) requestNavigationControllerForPresentAuthenticationView{
    return settingNavigationController_;
}

/*!
 * request to present modalview
 */
- (UIViewController *)requestRootViewControllerForPresentModalView{
    return self;
}

#pragma mark - ENGPhotoSubmitterPhotoDelegate
/*!
 * photo did submitted
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didSubmitted:(NSString *)imageHash suceeded:(BOOL)suceeded message:(NSString *)message{
    NSLog(@"submitted: %@,%d,%@", imageHash,suceeded,message);
}

/*!
 * progress changed
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didProgressChanged:(NSString *)imageHash progress:(CGFloat)progress{
    NSLog(@"progress: %@,%f",imageHash,progress);
}

/*!
 * photo did canceled
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter didCanceled:(NSString *)imageHash{
}

/*!
 * photo will statrt upload
 */
- (void)photoSubmitter:(id<ENGPhotoSubmitterProtocol>)photoSubmitter willStartUpload:(NSString *)imageHash{
}

#pragma mark - ENGPhotoSubmitterSettingViewControllerDelegate
/*!
 * setting view dismissed
 */
- (void)didDismissSettingTableViewController{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupInitialState];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*!
 * setting button tapped, present SettingView
 */
- (void)onSettingButtonTapped:(id)sender{
    [UIApplication sharedApplication].statusBarHidden = NO;
    [self presentViewController:settingNavigationController_ animated:YES completion:nil];
}

/*!
 * camera button tapped, present UIImagePickerController
 */
- (IBAction)onCameraButtonTapped:(id)sender{
    if([UIImagePickerController
        isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
        ipc.delegate = self;
        ipc.sourceType =
        UIImagePickerControllerSourceTypeCamera;
        ipc.allowsEditing = YES;
        [self presentViewController:ipc animated:YES completion:nil];
        imagePicker_ = ipc;
    }
}
@end
