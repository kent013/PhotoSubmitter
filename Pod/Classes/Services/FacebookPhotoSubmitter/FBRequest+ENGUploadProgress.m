//
//  FBRequest+ENGUploadProgress.m
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//

#import "FBRequest+ENGUploadProgress.h"

@implementation FBRequest(ENGUploadProgress)
/*!
 * delegate for upload progress
 */
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    id<ENGFBRequestWithUploadProgressDelegate> d = (id<ENGFBRequestWithUploadProgressDelegate>)_delegate;
    if ([d respondsToSelector:
         @selector(request:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [d request:self didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}
@end
