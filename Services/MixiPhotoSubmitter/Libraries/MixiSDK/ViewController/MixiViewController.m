//
//  MixiViewController.m
//
//  Created by Platform Service Department on 11/07/27.
//  Copyright 2011 mixi Inc. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with Non-ARC. use -fno-objc_arc flag (or convert project to Non-ARC)
#endif

#import "MixiViewController.h"
#import "Mixi.h"
#import "MixiConfig.h"
#import "MixiConstants.h"
#import "MixiDelegate.h"
#import "MixiOrientationDelegate.h"
#import "MixiRequest.h"
#import "MixiUtils.h"
#import "SBJson.h"

/** \cond */
@interface MixiViewController (Private)
/* キャンセルをデリゲートに通知 */
- (void)notifyCancel;
@end
/** \endcond */


@implementation MixiViewController

@synthesize mixi=mixi_,
    request=request_, 
    delegate=delegate_, 
    orientationDelegate=orietationDelegate_;

- (id)initWithMixi:(Mixi*)mixi request:(MixiRequest*)request delegate:(id<MixiDelegate>)delegate
{
    if ((self = [self initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle mainBundle]])) {
        self.mixi = mixi;
        self.request = request;
        self.delegate = delegate;
    }
    return self;
}

- (void)openURL:(NSURL*)url {
    NSString *jsonString = [[url fragment] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
    NSDictionary *json = [parser objectWithString:jsonString error:&error];
    MixiRequest *request = [MixiRequest postRequestWithEndpoint:[url path] params:json]; 
    NSString *result = [self.mixi rawSendSynchronousRequest:request error:&error];
    if (self.delegate && [self.delegate respondsToSelector:@selector(mixi:didFinishLoading:)]) {
        [self.delegate mixi:nil didFinishLoading:result];
    }
    NSURL *redirectURL = [NSURL URLWithString:result];
    NSString *host = [redirectURL host];
    if ([host isEqualToString:@"success"]) {
        NSDictionary *params = MixiUtilParseURLOptionsByString(redirectURL, @"?");
        if (self.delegate && [self.delegate respondsToSelector:@selector(mixi:didSuccessWithJson:)]) {
            [self.delegate mixi:self.mixi didSuccessWithJson:params];
        }
    }
    else if ([host isEqualToString:@"error"]) {
        NSDictionary *params = MixiUtilParseURLOptionsByString(redirectURL, @"?");
        if (self.delegate && [self.delegate respondsToSelector:@selector(mixi:didFailWithError:)]) {
            [self.delegate mixi:self.mixi didFailWithError:[NSError errorWithDomain:kMixiErrorDomain 
                                                                         code:kMixiAPIErrorInvalidJson 
                                                                     userInfo:params]];
        }
    }
    else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(mixi:didFailWithError:)]) {
            [self.delegate mixi:self.mixi 
               didFailWithError:[NSError errorWithDomain:kMixiErrorDomain 
                                                    code:kMixiErrorUnknown 
                                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          @"Unknown result", @"message", 
                                                          host, @"type", nil]]];
        }
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc
{
    self.mixi = nil;
    self.request = nil;
    self.delegate = nil;
    self.orientationDelegate = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mixi.mixiViewController = self;
    webView_.delegate = self;
    [self.mixi sendRequest:self.request delegate:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.mixi.mixiViewController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (self.orientationDelegate) {
        return [self.orientationDelegate shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    else {
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

#pragma mark - MixiDelegate

- (void)mixi:(Mixi*)mixi didFinishLoading:(NSString*)data {
    NSString *htmlString = [data stringByReplacingOccurrencesOfString:@"__MIXI_URL_SCHEME__" withString:mixi.config.urlScheme];
    [webView_ loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"http://mixi.co.jp"]];
    [indicator_ stopAnimating];
}

- (void)mixi:(Mixi*)mixi didFailWithConnection:(NSURLConnection*)connection error:(NSError*)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mixi:didFailWithError:)]) {
        [self.delegate mixi:self.mixi didFailWithError:error];
    }
    [indicator_ stopAnimating];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[[request URL] host] isEqualToString:@"cancel"]) {
        [self notifyCancel];
        [self dismissModalViewControllerAnimated:YES];
        return NO;
    }
    else if ([[[request URL] scheme] isEqualToString:[Mixi sharedMixi].config.urlScheme]) {
        [self openURL:[request URL]];
        return NO;
    }
    return YES;
}

#pragma mark - Event Handlers

- (IBAction)close:(id)sender {
    [self notifyCancel];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private

- (void)notifyCancel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mixi:didFailWithError:)]) {
        [self.delegate mixi:self.mixi didFailWithError:[NSError errorWithDomain:kMixiErrorDomain 
                                                                           code:kMixiCancelled 
                                                                       userInfo:[NSDictionary dictionaryWithObject:@"Your request was cancelled." forKey:@"message"]]];
    }    
}

@end
