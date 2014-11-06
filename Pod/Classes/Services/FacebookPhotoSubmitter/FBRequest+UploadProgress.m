//
//  FBRequest+UploadProgress.m
//  tottepost
//
//  Created by ISHITOYA Kentaro on 11/12/13.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#if __has_feature(objc_arc)
#error This file must be compiled with Non-ARC. use -fno-objc_arc flag (or convert project to Non-ARC)
#endif

#import "FBRequest+UploadProgress.h"

@implementation FBRequest(UploadProgress)
/*!
 * delegate for upload progress
 */
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    id<FBRequestWithUploadProgressDelegate> d = (id<FBRequestWithUploadProgressDelegate>)_delegate;
    if ([d respondsToSelector:
         @selector(request:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [d request:self didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}
@end
