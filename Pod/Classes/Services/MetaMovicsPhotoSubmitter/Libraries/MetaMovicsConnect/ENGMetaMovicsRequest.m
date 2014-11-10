//
//  MetaMovicsRequest.m
//  MetaMovicsConnect
//
//  Created by Kentaro ISHITOYA on 12/02/21.
//

#import "ENGMetaMovicsRequest.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGMetaMovicsRequest(PrivateImplementation)
@end

@implementation ENGMetaMovicsRequest(PrivateImplementation)
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
#pragma mark - authentication
@implementation ENGMetaMovicsRequest
@dynamic url;
@dynamic httpMethod;
@synthesize tag = tag_;
@synthesize connection = connection_;
@synthesize delegate = delegate_;

/*!
 * initialize
 */
- (id)initWithURLRequest:(NSURLRequest*)request 
             andDelegate:(id<ENGMetaMovicsRequestDelegate>)aDelegate{
    self = [super init];
    if(self){
        delegate_ = aDelegate;
        connection_ = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    }
    return self;
}

/*!
 * start
 */
- (void)start{
    if([self.delegate respondsToSelector:@selector(requestLoading:)]){
        [self.delegate requestLoading:self];
    }
    [connection_ start];
}

/*!
 * cancel connection
 */
- (void)cancel{
    [self.connection cancel];
}

/*!
 * get url
 */
- (NSURL *)url{
    return connection_.currentRequest.URL;
}

/*!
 * get method
 */
- (NSString *)httpMethod{
    return connection_.currentRequest.HTTPMethod;
}

#pragma mark - NSURLConnection[Data]Delegate methods
/*!
 * did receive response
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    data_ = [[NSMutableData alloc] init]; // _data being an ivar
    
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
    NSInteger statusCode = [httpResponse statusCode];
    if (statusCode != 200) {
        [connection cancel];
        if([self.delegate respondsToSelector:@selector(request:didFailWithError:)]){
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Server returned status code %d",@""), statusCode] forKey:NSLocalizedDescriptionKey];
            
            [self.delegate request:self didFailWithError:[NSError errorWithDomain:@"NSHTTPPropertyStatusCodeKey" code:statusCode userInfo:errorInfo]];
        }
        return;
    }
    if([self.delegate respondsToSelector:@selector(request:didReceiveResponse:)]){
        [self.delegate request:self didReceiveResponse:response];
    }
}

/*!
 * append data
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [data_ appendData:data];
}


/*!
 * did fail with error
 */
-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error{
    if([self.delegate respondsToSelector:@selector(request:didFailWithError:)]){
        [self.delegate request:self didFailWithError:error];
    }
}

/*!
 * did finish loading
 */
-(void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    if([self.delegate respondsToSelector:@selector(request:didLoadRawResponse:)]){
        [self.delegate request:self didLoadRawResponse:data_];
    }
    
    NSError *parseError = nil;
    NSString *json = [[NSString alloc] initWithData:data_ encoding:NSUTF8StringEncoding];
    NSDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&parseError];
    
    if (parseError) {
        if([self.delegate respondsToSelector:@selector(request:didFailWithError:)]){
            [self.delegate request:self didFailWithError:parseError];
        }
        return;
    }  
    if([self.delegate respondsToSelector:@selector(request:didLoad:)]){
        [self.delegate request:self didLoad:parsedData];
    }
}

/*!
 * progress
 */
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    if([self.delegate respondsToSelector:@selector(request:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]){
        [self.delegate request:self didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}
@end
