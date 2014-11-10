//
//  MetaMovicsRequest.h
//  MetaMovicsConnect
//
//  Created by Kentaro ISHITOYA on 12/02/21.
//

#import <Foundation/Foundation.h>
#import "ENGMetaMovicsProtocol.h"

@interface ENGMetaMovicsRequest : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>{
    __strong NSString *tag_;
    __strong NSURLConnection *connection_;
    __strong NSMutableData *data_;
    __weak id<ENGMetaMovicsRequestDelegate> delegate_;
}
@property (nonatomic, readonly) NSURL *url;
@property (nonatomic, readonly) NSString *httpMethod;
@property (nonatomic, readonly) NSURLConnection *connection;
@property (nonatomic, strong) NSString *tag;
@property (nonatomic, weak) id<ENGMetaMovicsRequestDelegate> delegate;

- (id)initWithURLRequest:(NSURLRequest*)request 
             andDelegate:(id<ENGMetaMovicsRequestDelegate>)aDelegate;
-(void) cancel;
-(void) start;
@end
