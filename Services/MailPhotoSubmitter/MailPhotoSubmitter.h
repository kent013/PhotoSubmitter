//
//  MailPhotoSubmitter.h
//  PhotoSubmitter for Twitter
//
//  Created by ISHITOYA Kentaro on 11/12/17.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#import "PhotoSubmitter.h"
#import "PhotoSubmitterProtocol.h"

@interface MailPhotoSubmitter : PhotoSubmitter<PhotoSubmitterInstanceProtocol>{
    BOOL subjectAsTitle_;
    BOOL bodyAsTitle_;
    BOOL connfirmMailContent_;
    NSString *defaultSubject_;
    NSString *defaultBody_;
    NSString *sendTo_;
}
@end
