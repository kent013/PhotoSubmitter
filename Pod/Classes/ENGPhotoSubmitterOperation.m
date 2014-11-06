//
//  ENGPhotoSubmitterOperation.m
//
//  Created by ISHITOYA Kentaro on 11/12/19.
//

#import "ENGPhotoSubmitterOperation.h"
#import "ENGPhotoSubmitterManager.h"
//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterOperation(PrivateImplementation)
- (void) finishOperation;
@end

@implementation ENGPhotoSubmitterOperation(PrivateImplementation)
#pragma mark -
#pragma mark NSOperation methods
/*!
 * is concurrent
 */
- (BOOL)isConcurrent {
    return self.submitter.isConcurrent;
}

/*!
 * return isExecuting
 */
- (BOOL)isExecuting {
    return isExecuting;
}

/*!
 * return isFinished
 */
- (BOOL)isFinished {
    return isFinished;
}

/*!
 * KVO key setting
 */
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString*)key {
    if ([key isEqualToString:@"isExecuting"] || 
        [key isEqualToString:@"isFinished"] || 
        [key isEqualToString:@"isCancelled"]|| 
        [key isEqualToString:@"isFailed"]) {
        return YES;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

/*!
 * start operation
 */
- (void)start{        
    if (self.submitter.isConcurrent == NO && [NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }

    [self setValue:[NSNumber numberWithBool:YES] forKey:@"isExecuting"];
    
    if(self.content.isPhoto){
        [self.submitter submitPhoto:(ENGPhotoSubmitterImageEntity *)self.content andOperationDelegate:self];
    }else if(self.content.isVideo){
        [self.submitter submitVideo:(ENGPhotoSubmitterVideoEntity *)self.content andOperationDelegate:self];
    }else{
        NSLog(@"type is unknown, %s", __PRETTY_FUNCTION__);
        [self setValue:[NSNumber numberWithBool:YES] forKey:@"isFinished"];       
        return;
    }
    
    do {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        if(isCancelled){
            [self.submitter cancelContentSubmit: self.content];
            break;
        }
    } while (isExecuting);
	[self setValue:[NSNumber numberWithBool:YES] forKey:@"isFinished"];
}

#pragma mark -
#pragma mark util methods
/*!
 * finish operation
 */
- (void) finishOperation{
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isExecuting"];
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//----------------------------------------------------------------------------
@implementation ENGPhotoSubmitterOperation
@synthesize submitter;
@synthesize content;
@synthesize delegates = delegates_;
@synthesize isFailed = isFailed_;

/*!
 * initialize with data
 */
- (id)initWithSubmitter:(id<ENGPhotoSubmitterProtocol>)inSubmitter 
             andContent:(ENGPhotoSubmitterContentEntity *)inContent{
    self = [super init];
    if(self){
        self.submitter = inSubmitter;
        self.content = inContent;
        delegates_ = [[NSMutableArray alloc] init];
    }
    return self;
}

/*!
 * encode
 */
- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:self.submitter.account forKey:@"account"];
    [coder encodeObject:self.content forKey:@"content"];
}

/*!
 * init with coder
 */
- (id)initWithCoder:(NSCoder*)coder {
    delegates_ = [[NSMutableArray alloc] init];
    self = [super init];
    if (self) {
        ENGPhotoSubmitterAccount *account = [coder decodeObjectForKey:@"account"];
        self.submitter = [ENGPhotoSubmitterManager submitterForAccount:account];
        self.content = [coder decodeObjectForKey:@"content"];
    }
    return self;
}

/*!
 * submitter operation delegate
 */
- (void)photoSubmitterDidOperationFinished:(BOOL)suceeded{
    [self finishOperation];
    if(suceeded == NO){
        [self setValue:[NSNumber numberWithBool:YES] forKey:@"isFailed"];
    }
    for(id<ENGPhotoSubmitterOperationDelegate> delegate in delegates_){
        [delegate photoSubmitterOperation:self didFinished:suceeded];
    }
}

/*!
 * submitter operation delegate
 */
- (void)photoSubmitterDidOperationCanceled{
    [self finishOperation];
    for(id<ENGPhotoSubmitterOperationDelegate> delegate in delegates_){
        [delegate photoSubmitterOperationDidCanceled:self];
    }    
}

/*!
 * create new instance from operation
 */
+ (id)operationWithOperation:(ENGPhotoSubmitterOperation *)operation{
    ENGPhotoSubmitterOperation *ret = [[ENGPhotoSubmitterOperation alloc] initWithSubmitter:operation.submitter andContent:operation.content];
    for(id<ENGPhotoSubmitterOperationDelegate> delegate in operation.delegates){
        [ret addDelegate:delegate];
    }
    return ret;
}

/*!
 * add delegate
 */
- (void)addDelegate:(id<ENGPhotoSubmitterOperationDelegate>)delegate{
    if([delegates_ containsObject:delegate]){
        return;
    }
    [delegates_ addObject:delegate];
}

/*!
 * remove delegate
 */
- (void)removeDelegate:(id<ENGPhotoSubmitterOperationDelegate>)delegate{
    [delegates_ removeObject:delegate];
}

/*!
 * clear delegate
 */
- (void)clearDelegate:(id<ENGPhotoSubmitterOperationDelegate>)delegate{
    [delegates_ removeAllObjects];
}

/*!
 * pause
 */
- (void)pause{
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"isCancelled"];
}

/*!
 * restart operation
 */
- (void)resume{
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isCancelled"];
}

/*!
 * return isCancelled
 */
- (BOOL)isCancelled{
    return isCancelled;
}
@end
