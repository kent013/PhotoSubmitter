//
//  ENGPhotoSubmitterSequencialOperationQueue.h
//
//  Created by ISHITOYA Kentaro on 12/01/25.
//

#import <Foundation/Foundation.h>
#import "ENGPhotoSubmitterOperation.h"
#import "ENGPhotoSubmitterProtocol.h"
#import "NSMutableArray+ENGQueueAdditions.h"

@protocol ENGPhotoSubmitterSequencialOperationQueueDelegate;

@interface ENGPhotoSubmitterSequencialOperationQueue : NSObject<ENGPhotoSubmitterOperationDelegate>{
    __strong NSMutableArray *queue_;
    __strong NSString *type_;
    id<ENGPhotoSubmitterSequencialOperationQueueDelegate> delegate_;
}
@property (readonly, nonatomic) NSString *type;
@property (readonly, nonatomic) NSInteger count;
@property (readonly, nonatomic) NSInteger interval;
- (id) initWithPhotoSubmitterType:(NSString *)type andDelegate:(id<ENGPhotoSubmitterSequencialOperationQueueDelegate>)delegate;
- (void) enqueue: (ENGPhotoSubmitterOperation *)operation;
- (ENGPhotoSubmitterOperation *) dequeue;
- (void) cancel;
@end

@protocol ENGPhotoSubmitterSequencialOperationQueueDelegate <NSObject>
- (void) sequencialOperationQueue:(ENGPhotoSubmitterSequencialOperationQueue *)sequencialOperationQueue didPeeked:(ENGPhotoSubmitterOperation *)operation;
@end
