//
//  OAuthViewController.h
//  DemoApp
//
//  Created by Chris Seymour on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
@protocol SFOAuthViewControllerDelegate;

@interface SFOAuthViewController : UIViewController<UIWebViewDelegate> {
	UIWebView* webView;
}

@property(nonatomic, retain) IBOutlet UIWebView* webView;
@property(nonatomic, assign) id<SFOAuthViewControllerDelegate> delegate;

@end

@protocol SFOAuthViewControllerDelegate <NSObject>
- (void)authViewControllerDismissed:(SFOAuthViewController *)controller;
@end