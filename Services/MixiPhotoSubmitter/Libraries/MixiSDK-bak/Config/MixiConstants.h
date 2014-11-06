/**
 * \file MixiConstants.h
 * \brief 共通で使用される定数を定義します。
 *
 * Created by Platform Service Department on 11/06/29.
 * Copyright 2011 mixi Inc. All rights reserved.
 */

#include "MixiErrorCodes.h"


/** SDKのバージョン番号 */
#define kMixiSDKVersion @"1.3.2"

/** mixi公式アプリのID */
#define kMixiApplicationId @"jp.co.mixi.iphone"

/** mixi公式アプリが使用するURIスキーム */
#define kMixiAppScheme @"mixi-connect"

/** 認可終了時に公式アプリを呼び出すためのURL */
#define kMixiDefaultRedirectUrl (kMixiAppScheme @"://success")

/** mixi公式アプリからクライアントシークレットを取得するためのURI */
#define kMixiAppTokenUri (kMixiAppScheme @"://token")

/** mixi公式アプリで認可状態を解除するためのURI */
#define kMixiAppRevokeUri (kMixiAppScheme @"://revoke")

/** エラー時にmixi公式アプリを呼び出すためのURI */
#define kMixiAppErrorUri (kMixiAppScheme @"://error")

/** mixi公式アプリで実行したAPIが認可処理 */
#define kMixiAppApiTypeToken @"token"

/** mixi公式アプリで実行したAPIが認可解除処理 */
#define kMixiAppApiTypeRevoke @"revoke"

/** リクエストを受信 */
#define kMixiAppApiTypeReceiveRequest @"request"

/** mixi公式アプリにOAuthクライアントIDを渡すためのキー */
#define kMixiSDKClientIdKey @"key"

/** mixi公式アプリにスコープを渡すためのキー */
#define kMixiSDKPermissionsKey @"permissions"

/** mixi公式アプリに結果受け取り用のURLスキームを渡すためのキー */
#define kMixiSDKReturnSchemeKey @"return_scheme"

/** mixi公式アプリにトークンを渡すためのキー */
#define kMixiSDKTokenKey @"token"

/** mixi API呼び出しのベースURL */
#define kMixiApiBaseUrl @"http://api.mixi-platform.com/2"

/** トークンリフレッシュのためのエンドポイント */
#define kMixiApiRefreshTokenEndpoint @"https://secure.mixi-platform.com/2/token"

/** トークン取得のためのエンドポイント */
#define kMixiApiTokenEndpoint @"/token"

/** 認可状態解除のためのエンドポイント */
#define kMixiApiRevokeEndpoint @"/authorize/revoke"

/** 不正なエンドポイント。エラー通知でのみ使用されます。 */
#define kMixiApiUnknownEndpoint @"[unknown]"

/** UU測定のためのエンドポイント */
#define kMixiApiPingEndpoint @"/apps/user/count/all"

/** mAPのためのエンドポイント */
#define kMixiApiMapEndpoint @"/apps/user/count"

/** 
 * SDKの使用するUserAgentのプレフィクス。実際のUserAgentは
 * kMixiSDKUserAgentPrefix + " " + UIWebViewのUA
 * になります。
 */
#define kMixiSDKUserAgentPrefix (@"mixi-phone-ios/" kMixiSDKVersion)

/** KeychainのID */
#define kMixiSDKKeychainIdentifier @"kMixiSDKKeychainIdentifier"

/** mixi公式アプリのダウンロードページURL */
#define kMixiOfficialAppDownloadURL [NSURL URLWithString:@"http://mixi.jp/official_app_introduction.pl"]

#define kMixiConnectAuthorizeURL @"https://mixi.jp/connect_authorize.pl"
