//
//  ENGPhotoSubmitterSequencialOperationQueue.m
//
//  Created by ISHITOYA Kentaro on 12/01/25.
//

#import "ENGPhotoSubmitterSequencialOperationQueue.h"

#define PS_SEQ_INTERVAL 5

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterSequencialOperationQueue(PrivateImplementation)
- (ENGPhotoSubmitterOperation *)peek;
@end

@implementation ENGPhotoSubmitterSequencialOperationQueue(PrivateImplementation)
/*!
 * peek
 */
- (ENGPhotoSubmitterOperation *)peek{
    [self dequeue];
    if(self.count == 0){
        return nil;
    }
    ENGPhotoSubmitterOperation *operation = [queue_ peekHead];
    [delegate_ sequencialOperationQueue:self didPeeked:operation];
    return operation;    
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//----------------------------------------------------------------------------
@implementation ENGPhotoSubmitterSequencialOperationQueue
@synthesize type = type_;
@synthesize interval;
/*!
 * init with photo submitter type
 */
-(id)initWithPhotoSubmitterType:(NSString *)inType andDelegate:(id<ENGPhotoSubmitterSequencialOperationQueueDelegate>)inDelegate{
    self = [super init];
    if(self){
        queue_ = [[NSMutableArray alloc] init];
        type_ = inType;
        delegate_ = inDelegate;
        interval = PS_SEQ_INTERVAL;
    }
    return self;
}

/*!
 * enqueue
 */
- (void)enqueue:(ENGPhotoSubmitterOperation *)operation{
    [operation addDelegate:self];
    [queue_ enqueue:operation];
    if(queue_.count == 1){
        [delegate_ sequencialOperationQueue:self didPeeked:operation];
    }
}

/*!
 * dequeue
 */
- (ENGPhotoSubmitterOperation *)dequeue{
    ENGPhotoSubmitterOperation *operation = [queue_ dequeue];
    return operation;
}

/*!
 * count
 */
- (NSInteger) count{
    return queue_.count;
}

/*!
 * cancel
 */
-(void)cancel{
    [queue_ removeAllObjects];
}

#pragma mark -
#pragma mark operation delegate
/*!
 * if current operation finished, dequeue next operation
 */
- (void)photoSubmitterOperation:(ENGPhotoSubmitterOperation *)operation didFinished:(BOOL)suceeeded{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(peek) withObject:nil afterDelay:interval];
    });
}

/*!
 * if current operation did canceled
 */
- (void)photoSubmitterOperationDidCanceled:(ENGPhotoSubmitterOperation *)operation{
    [queue_ removeAllObjects];
}
@end
