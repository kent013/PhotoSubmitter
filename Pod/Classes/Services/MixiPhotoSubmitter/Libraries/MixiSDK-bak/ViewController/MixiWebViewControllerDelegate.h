//
//  MixiWebViewControllerDelegate.h
//  tottepost
//
//  Created by Kentaro ISHITOYA on 12/03/10.
//  Copyright (c) 2012 cocotomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MixiWebViewController;

@protocol MixiWebViewControllerDelegate <NSObject>
- (void) didDismissMixiWebView:(MixiWebViewController *)webViewController;
@end
