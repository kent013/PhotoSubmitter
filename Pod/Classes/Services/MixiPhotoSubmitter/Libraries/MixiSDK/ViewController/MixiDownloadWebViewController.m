//
//  MixiDownloadWebViewController.m
//  iosSDK
//
//  Created by Platform Service Department on 12/01/19.
//  Copyright (c) 2012 mixi Inc. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with Non-ARC. use -fno-objc_arc flag (or convert project to Non-ARC)
#endif

#import "MixiDownloadWebViewController.h"
#import "MixiDownloadWebViewDelegate.h"

@implementation MixiDownloadWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    webView_.delegate = downloadDelegate_;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)addCloseTaget:(id)target action:(SEL)action {
    downloadDelegate_ = [[MixiDownloadWebViewDelegate alloc] initWithCloseTarget:target action:action];
}

- (void)dealloc {
    [downloadDelegate_ release];
    [super dealloc];
}

@end
