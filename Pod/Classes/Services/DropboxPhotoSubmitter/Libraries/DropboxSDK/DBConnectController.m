//
//  DBConnectController.m
//  DropboxSDK
//
//  Created by Brian Smith on 5/4/12.
//  Copyright (c) 2012 Dropbox, Inc. All rights reserved.
//

#import "DBConnectController.h"

#import <QuartzCore/QuartzCore.h>

#import "DBLog.h"
#import "DBRequest.h"
#import "DBSession+iOS.h"

#include "TargetConditionals.h"


extern id<DBNetworkRequestDelegate> dbNetworkRequestDelegate;

@interface DBConnectController () <UIWebViewDelegate, UIAlertViewDelegate>

- (void)loadRequest;
- (void)openUrl:(NSURL *)url;
- (void)dismiss;
- (void)dismissAnimated:(BOOL)animated;

@property (nonatomic, retain) UIAlertView *alertView;
@property (nonatomic, assign) BOOL hasLoaded;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) UIWebView *webView;

@end


@implementation DBConnectController

@synthesize alertView;
@synthesize isModal;

- (void)setAlertView:(UIAlertView *)pAlertView {
    if (pAlertView == alertView) return;
    alertView.delegate = nil;
    [alertView release];
    alertView = pAlertView;
}

@synthesize hasLoaded;
@synthesize url;
@synthesize webView;

- (id)initWithUrl:(NSURL *)connectUrl {
    if ((self = [super init])) {
        self.url = connectUrl;

        self.isModal = YES;
        self.title = @"Dropbox";
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    }
    return self;
}

- (void)dealloc {
    alertView.delegate = nil;
    [alertView release];
    [url release];
    if (webView.isLoading) {
        [webView stopLoading];
    }
    webView.delegate = nil;
    [webView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRed:241.0/255 green:249.0/255 blue:255.0/255 alpha:1.0];

    UIActivityIndicatorView *activityIndicator =
        [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    activityIndicator.autoresizingMask =
        UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    CGRect frame = activityIndicator.frame;
    frame.origin.x = floorf(self.view.bounds.size.width/2 - frame.size.width/2);
    frame.origin.y = floorf(self.view.bounds.size.height/2 - frame.size.height/2) - 20;
    activityIndicator.frame = frame;
    [activityIndicator startAnimating];
    [self.view addSubview:activityIndicator];

    self.webView = [[[UIWebView alloc] initWithFrame:self.view.frame] autorelease];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.scalesPageToFit = YES;
    self.webView.hidden = YES;
    [self.view addSubview:self.webView];

    [self loadRequest];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    if ([webView isLoading]) {
        [webView stopLoading];
    }
    webView.delegate = nil;
    [webView release];
    webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ||
            interfaceOrientation == UIInterfaceOrientationPortrait;
}


#pragma mark UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [dbNetworkRequestDelegate networkRequestStarted];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    [aWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout = \"none\";"]; // Disable touch-and-hold action sheet
    [aWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect = \"none\";"]; // Disable text selection
    webView.frame = self.view.bounds;

    CATransition* transition = [CATransition animation];
    transition.duration = 0.25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.type = kCATransitionFade;
    [self.view.layer addAnimation:transition forKey:nil];

    webView.hidden = NO;

    hasLoaded = YES;
    [dbNetworkRequestDelegate networkRequestStopped];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [dbNetworkRequestDelegate networkRequestStopped];

    // ignore "Fame Load Interrupted" errors and cancels
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) return;
    if (error.code == NSURLErrorCancelled && [error.domain isEqual:NSURLErrorDomain]) return;

    DBLogWarning(@"DropboxSDK: error loading DBConnectController - %@", error);

    NSString *title = @"";
    NSString *message = @"";

    if ([error.domain isEqual:NSURLErrorDomain] && error.code == NSURLErrorNotConnectedToInternet) {
        title = NSLocalizedString(@"No internet connection", @"");
        message = NSLocalizedString(@"Try again once you have an internet connection.", @"");
    } else if ([error.domain isEqual:NSURLErrorDomain] &&
               (error.code == NSURLErrorTimedOut || error.code == NSURLErrorCannotConnectToHost)) {
        title = NSLocalizedString(@"Internet connection lost", @"");
        message    = NSLocalizedString(@"Please try again.", @"");
    } else {
        title = NSLocalizedString(@"Unknown Error Occurred", @"");
        message = NSLocalizedString(@"There was an error loading Dropbox. Please try again.", @"");
    }

    if (self.hasLoaded) {
        // If it has loaded, it means it's a form submit, so users can cancel/retry on their own
        NSString *okStr = NSLocalizedString(@"OK", nil);

        self.alertView =
            [[UIAlertView alloc]
             initWithTitle:title message:message delegate:nil cancelButtonTitle:okStr otherButtonTitles:nil];
    } else {
        // if the page hasn't loaded, this alert gives the user a way to retry
        NSString *retryStr = NSLocalizedString(@"Retry", @"Retry loading a page that has failed to load");

        self.alertView =
            [[UIAlertView alloc]
             initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
             otherButtonTitles:retryStr, nil];
    }

    [self.alertView show];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {

    NSString *appScheme = [[DBSession sharedSession] appScheme];
    if ([[[request URL] scheme] isEqual:appScheme]) {

        [self openUrl:[request URL]];
        [self dismiss];
        return NO;
    } else if ([[[request URL] scheme] isEqual:@"itms-apps"]) {
#if TARGET_IPHONE_SIMULATOR
        DBLogError(@"DropboxSDK - Can't open on simulator. Run on an iOS device to test this functionality");
#else
        [[UIApplication sharedApplication] openURL:[request URL]];
        [self cancelAnimated:NO];
#endif
        return NO;
    } else if (![[[request URL] pathComponents] isEqual:[self.url pathComponents]]) {
        DBConnectController *childController = [[[DBConnectController alloc] initWithUrl:[request URL]] autorelease];

        NSDictionary *queryParams = [DBSession parseURLParams:[[request URL] query]];
        NSString *title = [queryParams objectForKey:@"embed_title"];
        if (title) {
            childController.title = title;
        } else {
            childController.title = self.title;
        }
        childController.navigationItem.rightBarButtonItem = nil;

        [self.navigationController pushViewController:childController animated:YES];
        return NO;
    }
    return YES;
}


#pragma mark UIAlertView methods

- (void)alertView:(UIAlertView *)pAlertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != pAlertView.cancelButtonIndex) {
        [self loadRequest];
    } else {
        if ([self.navigationController.viewControllers count] > 1) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismiss];
        }
    }

    self.alertView = nil;
}


#pragma mark private methods

- (void)loadRequest {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:self.url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:20];
    [self.webView loadRequest:urlRequest];
}

- (void)openUrl:(NSURL *)openUrl {
    UIApplication *app = [UIApplication sharedApplication];
    id<UIApplicationDelegate> delegate = app.delegate;

    if ([delegate respondsToSelector:@selector(application:openURL:sourceApplication:annotation:)]) {
        [delegate application:app openURL:openUrl sourceApplication:@"com.getdropbox.Dropbox" annotation:nil];
    } else if ([delegate respondsToSelector:@selector(application:handleOpenURL:)]) {
        [delegate application:app handleOpenURL:openUrl];
    }
}

- (void)cancelAnimated:(BOOL)animated {
    [self dismissAnimated:animated];

    NSString *cancelUrl = [NSString stringWithFormat:@"%@://%@/cancel", [[DBSession sharedSession] appScheme], kDBDropboxAPIVersion];
    [self openUrl:[NSURL URLWithString:cancelUrl]];
}

- (void)cancel {
	[self cancelAnimated:YES];
}

- (void)dismissAnimated:(BOOL)animated {
    if ([webView isLoading]) {
        [webView stopLoading];
    }
    if(self.isModal){
        [self.navigationController dismissModalViewControllerAnimated:animated];
    }else{
        [self.navigationController popViewControllerAnimated:animated];
    }
}

- (void)dismiss {
    [self dismissAnimated:YES];
}

@end
