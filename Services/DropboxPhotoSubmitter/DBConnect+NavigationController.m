//
//  DBConnect+NavigationController.m
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/06/05.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "DBConnect+NavigationController.h"

@implementation DBConnectController(NavigationController)
- (void)dismissAnimated:(BOOL)animated {
    if ([webView isLoading]) {
        [webView stopLoading];
    }
    [self.navigationController popViewControllerAnimated:animated];
}

@end

@implementation DBSession(NavigationController)
- (void)linkUserId:(NSString *)userId fromController:(UIViewController *)rootController {
    if (![self appConformsToScheme]) {
        DBLogError(@"DropboxSDK: unable to link; app isn't registered for correct URL scheme (%@)", [self appScheme]);
        return;
    }
    
    extern NSString *kDBDropboxUnknownUserId;
    NSString *userIdStr = @"";
    if (userId && ![userId isEqual:kDBDropboxUnknownUserId]) {
        userIdStr = [NSString stringWithFormat:@"&u=%@", userId];
    }
    
    NSString *consumerKey = [baseCredentials objectForKey:kMPOAuthCredentialConsumerKey];
    
    NSData *consumerSecret =
    [[baseCredentials objectForKey:kMPOAuthCredentialConsumerSecret] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(consumerSecret.bytes, [consumerSecret length], md);
    NSUInteger sha_32 = htonl(((NSUInteger *)md)[CC_SHA1_DIGEST_LENGTH/sizeof(NSUInteger) - 1]);
    NSString *secret = [NSString stringWithFormat:@"%x", sha_32];
    
    NSString *urlStr = nil;
    
    NSURL *dbURL =
    [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/connect", kDBProtocolDropbox, kDBDropboxAPIVersion]];
    if ([[UIApplication sharedApplication] canOpenURL:dbURL]) {
        urlStr = [NSString stringWithFormat:@"%@?k=%@&s=%@%@", dbURL, consumerKey, secret, userIdStr];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
    } else {
        urlStr = [NSString stringWithFormat:@"%@://%@/%@/connect_login?k=%@&s=%@&easl=1%@",
                  kDBProtocolHTTPS, kDBDropboxWebHost, kDBDropboxAPIVersion, consumerKey, secret, userIdStr];
        UIViewController *connectController = [[[DBConnectController alloc] initWithUrl:[NSURL URLWithString:urlStr]] autorelease];
        
        if([rootController isKindOfClass: [UINavigationController class]]){
            UINavigationController *navController = (UINavigationController *)rootController;
            [navController pushViewController:connectController animated:YES];
        }else{
            UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:connectController] autorelease];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                connectController.modalPresentationStyle = UIModalPresentationFormSheet;
                navController.modalPresentationStyle = UIModalPresentationFormSheet;
            }
            
            [rootController presentModalViewController:navController animated:YES];
        }
    }
}
@end
