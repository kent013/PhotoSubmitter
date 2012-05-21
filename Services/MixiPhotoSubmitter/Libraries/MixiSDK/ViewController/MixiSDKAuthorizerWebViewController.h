/**
 * \file MixiSDKAuthorizerWebViewController.h
 * \brief SDK単体認可用のウェブビューコントローラーを定義します。
 *
 * Created by Platform Service Department on 12/03/26.
 * Copyright 2012 mixi Inc. All rights reserved.
 */

#import "MixiWebViewController.h"

@class MixiSDKAuthorizer;

/**
 * \brief SDK単体認可用のウェブビューコントローラー
 */
@interface MixiSDKAuthorizerWebViewController : MixiWebViewController {
    /** \brief エンドポイント */
    NSString *endpoint_;
    
    /** \brief 認可実行用オブジェクト */
    MixiSDKAuthorizer *authorizer_;
}

@property (nonatomic, copy) NSString *endpoint;
@property (nonatomic, retain) MixiSDKAuthorizer *authorizer;

@end
