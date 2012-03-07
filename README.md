PhotoSubmitter
==========================================
The purpose of the PhotoSubmitter iOS class library is to facilitate the development of photo upload application.

There are a lot of Social Network Services and Cloud Storage Services. And each services have their own SDK to connect to their service. Unfortunately SDKs are not compatible each other.　Especially between Social Network Services and Cloud Storage Services are completely different. 

So, I developed PhotoSubmitter library as an abstraction layer for this situation.

PhotoSubmitter Client Code
------------------------------------------
PhotoSubmitter supports authentication with code like,

```
[[PhotoSubmitterManager submitterForType:@"FacebookPhotoSubmitter"] login];
```

This code will brings up Safari or Facebook app in your iPhone for authentication. You can receive messages from PhotoSubmitter while authenticating with implementing `PhotoSubmitterAuthenticationDelegate`. 

There are a lot of supported services, Facebook, Twitter, Dropbox and so on. You can enable submitter with just calling login method.

```
[[PhotoSubmitterManager submitterForType:@"DropboxPhotoSubmitter"] login];
[[PhotoSubmitterManager submitterForType:@"EvernotePhotoSubmitter"] login];
```

Once PhotoSubmitter is enabled and authenticated, you can submit photo to the service like this,

```
PhotoSubmitterImageEntity *photo = 
    [[PhotoSubmitterImageEntity alloc] initWithData:data];
[PhotoSubmitterManager submitPhoto:photo];
```

This code is creating photo entity and submitting photo to the authenticated services asynchronously. You can receive messages from PhotoSubmitter while submitting photo with implementing `PhotoSubmitterPhotoDelegate`.


Supported Services
-------------------------------------------
Below is the list of supported Social Network and Cloud Storage services.

<table>
<tr>
<th>Service Name</th>
<th>Auth Type</th>
<th>Requirement</th>
<th>Upload Type</th>
<th>Album Support</th>
</tr>
<tr>
<td>Facebook</td>
<td>OAuth (Safari/FacebookApp)</td>
<td>URLScheme: fb[appId]</td>
<td>Concurrent</td>
<td>YES</td>
</tr>
<tr>
<td>Twitter</td>
<td>iOS</td>
<td>-</td>
<td>Sequencial<sup>*1</sup></td>
<td>NO</td>
</tr>
<tr>
<td>Dropbox</td>
<td>OAuth (Safari/DropboxApp)</td>
<td>URLScheme: db-[appId]</td>
<td>Concurrent</td>
<td>YES</td>
</tr>
<tr>
<td>Flickr</td>
<td>OAuth (Safari)</td>
<td>URLScheme: photosubmitter</td>
<td>Concurrent</td>
<td>YES</td>
</tr>
<tr>
<td>Evernote</td>
<td>OAuth (Safari)</td>
<td>URLScheme: photosubmitter</td>
<td>Concurrent</td>
<td>YES</td>
</tr>
<tr>
<td>Picasa<sup>*2</sup></td>
<td>OAuth (In App WebView)</td>
<td>PhotoSubmitterAuthControllerDelegate</td>
<td>Concurrent</td>
<td>YES</td>
</tr>
<tr>
<td>Minus</td>
<td>OAuth (In App PasswordView)</td>
<td>PhotoSubmitterAuthControllerDelegate</td>
<td>Concurrent</td>
<td>YES</td>
</tr>
<tr>
<td>Mixi<sup>*3</sup></td>
<td>OAuth (In App WebView)</td>
<td>PhotoSubmitterAuthControllerDelegate</td>
<td>Concurrent</td>
<td>YES</td>
</tr>
<tr>
<td>Fotolife<sup>*3</sup></td>
<td>BASIC (In App PasswordView)</td>
<td>PhotoSubmitterAuthControllerDelegate</td>
<td>Concurrent</td>
<td>NO</td>
</tr>
<tr>
<td>File</td>
<td>-</td>
<td>-</td>
<td>-</td>
<td>NO</td>
</tr>
</table>

*1 Uploading multiple photo at same time will cause 400 error.
*2 Currently Google+ does not permit write access to images.
*3 Japanese services.

Custom URL schema setting is needed for Safari or App authentication. See [Implementing Custom URL Schemes](https://developer.apple.com/library/ios/#DOCUMENTATION/iPhone/Conceptual/iPhoneOSProgrammingGuide/AdvancedAppTricks/AdvancedAppTricks.html)
 and [Launching Your Own Application via a Custom URL Scheme](http://iphonedevelopertips.com/cocoa/launching-your-own-application-via-a-custom-url-scheme.html) for more information.

UINavigationController is needed to present built-in WebView and PasswordView. To provide UINavigationController to the PhotoSubmitter, you may implement `PhotoSubmitterAuthControllerDelegate`'s method `(UINavigationController *) requestNavigationControllerToPresentAuthenticationView` in your client code.

Before using OAuth services, you must submit to their developer program to obtain API-Key and API-Secret. After you've got key and secret pair, copy `PhotoSubmitter/Services/[ServiceName]PhotoSubmitter/[ServiceName]APIKey-template.h` as `PhotoSubmitter/Services/[ServiceName]PhotoSubmitter/[ServiceName]APIKey.h` in the same directory and modify appropriate constants with your key and secret. For instance, if you want to use flickr, you may modify

```
#define PHOTO_SUBMITTER_FLICKR_API_KEY @""
#define PHOTO_SUBMITTER_FLICKR_API_SECRET @""
```
these constants with your key and secret pair.

Probrem in mixture of ARC and Non-ARC libraries
-------------------------------------------------
**PhotoSubmitter is ARC project**, and some dependent libraries are **Non-ARC**. **Non-ARC Libraries cause build error**. You must set '-fno-objc-arc' flag to their source codes to disable ARC. Please check out [stackoverflow: How can I disable ARC for a single file in a project?](http://stackoverflow.com/questions/6646052/how-can-i-disable-arc-for-a-single-file-in-a-project). (Tip: You can set flag to multiple source codes at once with selecting multiple source code and pressing ENTER key)

Library Dependencies for PhotoSubmitter library
-------------------------------------------------
AssetsLibrary, CFNetwork, CoreLocation, Foundation, ImageIO, Security and SystemConfiguration.framework are needed to be added in your project. Also libicucore.dylib is required by <a href="http://regexkit.sourceforge.net/RegexKitLite/">RegexKitLite</a> and libxml2.dylib is required by <a href="https://github.com/ddeville/KissXML">KissXML</a>.

libxml2 needs "Header Search Path" to be configured as `/usr/include/libxml2`(or other path to libxml2's header files are placed.

Library Dependencies of Service Implementation
-------------------------------------------------
PhotoSubmitter's common libraries are stored in `Libraries`. And libraries for service implementation are stored in `Services/[ServiceName]PhotoSubmitter/Libraries`. PhotoSubmitter service implementations are designed to be work properly when they added to project independently. Because of this issue, libraries may be duplicated when you add multiple PhotoSubmitter service implementations to your project. If so, please delete all libraries duplicated, leaving only one library.

<table>
<tr>
<th>Service Name</th>
<th>SDK</th>
<th>Libraries</th>
</tr>
<tr>
<td>Facebook</td>
<td><a href="https://github.com/facebook/facebook-ios-sdk">Facebook SDK</a></td>
<td>-</td>
</tr>
<tr>
<td>Twitter</td>
<td><a href="https://developer.apple.com/library/ios/#documentation/"Twitter/Reference/TwitterFrameworkReference/_index.html">Twitter.framework</a></td>
<td>Accounts.framework</td>
</tr>
<tr>
<td>Dropbox</td>
<td><a href="https://www.dropbox.com/developers/reference/sdk">Dropbox SDK</a></td>
<td>-</td>
</tr>
<tr>
<td>Flickr</td>
<td><a href="https://github.com/lukhnos/objectiveflickr">ObjectiveFlickr</a></td>
<td>-</td>
</tr>
<tr>
<td>Evernote</td>
<td><a href="https://github.com/kent013/EVNConnect">EVNConnect</a><sup>1</sup></td>
<td>-</td>
</tr>
<tr>
<td>Picasa</td>
<td><a href="http://code.google.com/p/gdata-objectivec-client/">gdata-objectivec-client</a></td>
<td>-</td>
</tr>
<tr>
<td>Minus</td>
<td><a href="https://github.com/kent013/MinusConnect">MinusConnect</a></td>
<td><a href="https://github.com/nxtbgthng/OAuth2Client">OAuth2Client</a>, CoreData.framework, MobileCoreServices.framework, libz.dylib</td>
</tr>
<tr>
<td>Mixi</td>
<td><a href="http://developer.mixi.co.jp/connect/mixi_graph_api/ios/">Mixi SDK</a></td>
<td>-</td>
</tr>
<tr>
<td>Fotolife</td>
<td><a href="https://github.com/kent013/objc-atompub">objc-atompub</a></td>
<td>-</td>
</tr>
<tr>
<td>File</td>
<td>-</td>
<td>AssetsLibrary.framework, ImageIO.framework</td>
</tr>
</table>

*1 EvernoteConnect needs "Header Search Path" to be configured as `[submodule path]/Services/EvernotePhotoSubmitter/Libraries/Evernote/thrift` and `recursive` checked.  
*2 libxml2 needs "Header Search Path" to be configured as `/usr/include/libxml2`


PhotoSubmitter SettingViewController
---------------------------------------
There are useful setting component for PhotoSubmitter. PhotoSubmitterSetting component provides comment/GPS toggle switch, PhotoSubmitter toggle switches, album listing and creating.

Source codes are stored in [Settings](https://github.com/kent013/PhotoSubmitter/Settings).


Implementing New PhotoSubmitter
---------------------------------------
Fast way to implement new PhotoSubmitter, you may copy existing PhotoSubmitter's source code.
FacebookPhotoSubmitter is suitable for Safari or App authentication. If the service needed to present WebView, copy Mixi or Picasa. And If the service needed to present PasswordView, copy Minus or Fotolife.

### Directory structure
PhotoSubmitter service implementation must obey rule of file/directory structure as below.

```
Services
 |-[ServiceName]PhotoSubmitter
    |- Resources
    |  |- Images                               (Service specific images)
    |  |  |- [lowercase-servicename]_16.png    (16 x 16, icon for progress)
    |  |  |- [lowercase-servicename]_16@2x.png (32 x 32, icon for progress, Retina)
    |  |  |- [lowercase-servicename]_32.png    (32 x 32, icon for setting)
    |  |  |- [lowercase-servicename]_32@2x.png (64 x 64, icon for setting, Retina)
    |  |- Localizations
    |     |- [lang].lproj                      (lang: en, ja etc)
    |         |- [ServiceName].strings         (Localized string)
    |- Libraries                               (Dependent libraries)
    |- [ServiceName]PhotoSubmitter.h
    |- [ServiceName]PhotoSubmitter.m

```

For example, When you going to implement PhotoSubmitter Facebook, [lowercase-servicename] is facebook, [ServiceName] is Facebook.

-
### PhotoSubmitter Interface declaration
* Class name must be [Hoge]PhotoSubmitter where Hoge is service name.
* Extend `PhotoSubmitter`.
* Implement `PhotoSubmitterInstanceProtocol`.

For example,

```
@interface FacebookPhotoSubmitter : 
    PhotoSubmitter<PhotoSubmitterInstanceProtocol, FBSessionDelegate, 
                   FBRequestWithUploadProgressDelegate>{
    __strong Facebook *facebook_;
}
@end
```

-
### PhotoSubmitter Implementation
####Call configuration method in initialize method.  
```
[self setSubmitterIsConcurrent:YES 
                  isSequencial:NO 
                 usesOperation:YES 
               requiresNetwork:YES 
              isAlbumSupported:YES];
```
<table>
<tr>
<th>Configuration Name</th>
<th>Explanation</th>
</tr>
<tr>
<td>isConcurrent</td>
<td>indicates photo upload process uses thread.<br/>
    When the flag is NO, photo upload process will called in main thread.</td> 
</tr>
<tr>
<td>isSequencial</td>
<td>indicates photo upload process uses PhotoSubmitterSequencialOperationQueue.<br/>
    Flag for services not permit upload multiple photo at same time like Twitter.</td>
</tr>
<tr>
<td>usesOperation</td>
<td>indicates use NSOperationQueue for upload process.</td>
</tr>
<tr>
<td>requireNetwork</td>
<td>indicates the PhotoSubmitter needs network.</td>
</tr> 
<tr>
<td>isAlbumSupported</td>
<td>indicates the PhotoSubmitter implements album methods.</td>
</tr>
</table>


-
#### Implement PhotoSubmitterInstanceProtocol
**Implement login process in `-(void)onLogin`.**  
This method will call when `[PhotoSubmitterProtocol login]` is called. For example,

```
-(void)onLogin{
    NSArray *permissions = 
    [NSArray arrayWithObjects:@"publish_stream", @"user_location", 
                              @"user_photos", @"offline_access", nil];
    [facebook_ authorize:permissions];
}
```

When login process is done, usually in the delegate method like fbDidLogin, you must call `[PhotoSubmitter completeLogin]`. 

```
- (void)fbDidLogin {
    [self setSetting:[facebook_ accessToken] forKey:PS_FACEBOOK_AUTH_TOKEN];
    [self setSetting:[facebook_ expirationDate] forKey:PS_FACEBOOK_AUTH_EXPIRATION_DATE];
    
    [self completeLogin];
    [self getUserInfomation];
}
```

And if login process is failed, usually in the delegate method like fbDidNotLogin, you must call `[PhotoSubmitter completeLoginFailed]`.

```
-(void)fbDidNotLogin:(BOOL)cancelled {
    [self completeLoginFailed];
}
```

**Implement logout process in `-(void)onLogout`**  
This method will call when `[PhotoSubmitterProtocol logout]` is called.

```
- (void)onLogout{
    [facebook_ logout:self];   
}
```

When the logout process is finished(In the delegate method, if logout process is asynchronous), you must call `[PhotoSubmitter completeLogout]`.

```
- (void) fbDidLogout {
    [self completeLogout];
}
```

If there are no specific logout process, you must call `[PhotoSubmitter completeLogout]` in `(void)onLogout`. This method clear credentials. For example, FlickrPhotoSubmitter's onLogout is like this,

```
- (void)onLogout{
    [self completeLogout];
}
```

**Implement upload photo process in `-(id)onSubmitPhoto: andOperationDelegate:`**  
This method will call when the `[PhotoSubmitter submitPhoto]` called.
Return value of the method may not be nil (nil means upload is not started), like FBRequest, NSURLConnection or some instance represents individual request. 

```
- (id)onSubmitPhoto:(PhotoSubmitterImageEntity *)photo 
andOperationDelegate:(id<PhotoSubmitterPhotoOperationDelegate>)delegate{
    CGSize size = CGSizeMake(PS_FACEBOOK_PHOTO_WIDTH, PS_FACEBOOK_PHOTO_HEIGHT);
    if(photo.image.size.width < photo.image.size.height){
        size = CGSizeMake(PS_FACEBOOK_PHOTO_HEIGHT, PS_FACEBOOK_PHOTO_WIDTH);
    }
    
    NSMutableDictionary *params = 
    [NSMutableDictionary dictionaryWithObjectsAndKeys: 
       [photo resizedImage:size], @"source", 
                   photo.comment, @"name", nil];
    NSString *path = @"me/photos";
    if(self.targetAlbum != nil){
        path = [NSString stringWithFormat:@"%@/photos", self.targetAlbum.albumId];
    }
    FBRequest *request = 
       [facebook_ requestWithGraphPath:path 
                             andParams:params 
                         andHttpMethod:@"POST" 
                           andDelegate:self];
    return request;
}
```

When the upload process is finished(In the delegate method, if upload process is asynchronous), you must call `[PhotoSubmitter completeSubmitPhoto:(id)request]`. Where request must be same object as Return value.

```
- (void)request:(FBRequest *)request didLoad:(id)result {
    if([request.url isMatchedByRegex:@"photos$"]){
        [self completeSubmitPhotoWithRequest:request];
    }
}
```

If the upload process is failed, you must call `[PhotoSubmitter completeSubmitPhoto:(id)request andError:(NSError *)error]`.

```
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    if([request.url isMatchedByRegex:@"photos$"]){
        [self completeSubmitPhotoWithRequest:request andError:error];
    }
}
```

**Implement cancel photo code in `-(id)onCancelPhoto:(PhotoSubmitterImageEntity *)photo`**  
This method invoked when the `[PhotoSubmitter cancel]` called.
You can obtain request object calling `[self requestForPhoto:photo.photoHash]`.
Return value of the method is NSURLConnection or some instance represents individual request. And may not be nil(nil means upload is not started).

```
- (id)onCancelPhotoSubmit:(PhotoSubmitterImageEntity *)photo{
    FBRequest *request = (FBRequest *)[self requestForPhoto:photo.photoHash];
    [request.connection cancel];
    return request;
}
```

-
#### Override PhotoSubmitter's method.
**isSessionValid**  
return your submitter's authentication is valid.

```
- (BOOL)isSessionValid{
    if ([self settingForKey:PS_FACEBOOK_AUTH_TOKEN]) {
        return YES;
    }
    return NO;
}
```
