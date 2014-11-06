//
//  MixiSDKAuthorizerWebViewController.m
//  iosSDK
//
//  Copyright (c) 2012 mixi Inc. All rights reserved.
//


#if __has_feature(objc_arc)
#error This file must be compiled with Non-ARC. use -fno-objc_arc flag (or convert project to Non-ARC)
#endif

#import "MixiSDKAuthorizerWebViewController.h"

@implementation MixiSDKAuthorizerWebViewController

@synthesize endpoint=endpoint_, authorizer=authorizer_;

- (IBAction)close:(id)sender {
    if (self.authorizer) {
        [self.authorizer performSelector:@selector(notifyCancelWithEndpoint:) withObject:self.endpoint];
    }
    [super close:sender];
}

- (void)dealloc {
    self.endpoint = nil;
    self.authorizer = nil;
    [super dealloc];
}

@end
