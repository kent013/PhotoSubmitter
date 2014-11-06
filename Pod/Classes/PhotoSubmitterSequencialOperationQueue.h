//
//  PhotoSubmitterSequencialOperationQueue.h
//  tottepost
//
//  Created by ISHITOYA Kentaro on 12/01/25.
//  Copyright (c) 2012 ISHITOYA Kentaro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoSubmitterOperation.h"
#import "PhotoSubmitterProtocol.h"
#import "NSMutableArray+QueueAdditions.h"

@protocol PhotoSubmitterSequencialOperationQueueDelegate;

@interface PhotoSubmitterSequencialOperationQueue : NSObject<PhotoSubmitterOperationDelegate>{
    __strong NSMutableArray *queue_;
    __strong NSString *type_;
    id<PhotoSubmitterSequencialOperationQueueDelegate> delegate_;
}
@property (readonly, nonatomic) NSString *type;
@property (readonly, nonatomic) int count;
@property (readonly, nonatomic) int interval;
- (id) initWithPhotoSubmitterType:(NSString *)type andDelegate:(id<PhotoSubmitterSequencialOperationQueueDelegate>)delegate;
- (void) enqueue: (PhotoSubmitterOperation *)operation;
- (PhotoSubmitterOperation *) dequeue;
- (void) cancel;
@end

@protocol PhotoSubmitterSequencialOperationQueueDelegate <NSObject>
- (void) sequencialOperationQueue:(PhotoSubmitterSequencialOperationQueue *)sequencialOperationQueue didPeeked:(PhotoSubmitterOperation *)operation;
@end
