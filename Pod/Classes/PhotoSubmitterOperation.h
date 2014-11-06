//
//  PhotoSubmitterOperation.h
//  tottepost
//
//  Created by ISHITOYA Kentaro on 11/12/19.
//  Copyright (c) 2011 cocotomo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoSubmitterProtocol.h"

@protocol PhotoSubmitterOperationDelegate;

/*!
 * NSOperation subclass for submitting photo
 */
@interface PhotoSubmitterOperation : NSOperation<NSCoding, PhotoSubmitterPhotoOperationDelegate>{
    BOOL isExecuting;
    BOOL isFinished;
    BOOL isCancelled;
    BOOL isFailed;
    NSMutableArray *delegates_;
}
@property (strong, nonatomic) id<PhotoSubmitterProtocol> submitter;
@property (strong, nonatomic) PhotoSubmitterContentEntity *content;
@property (assign, nonatomic) BOOL isFailed;
@property (readonly, nonatomic) NSMutableArray *delegates;

- (void) resume;
- (void) addDelegate:(id<PhotoSubmitterOperationDelegate>)delegate;
- (void) removeDelegate:(id<PhotoSubmitterOperationDelegate>)delegate;
- (void) clearDelegate:(id<PhotoSubmitterOperationDelegate>)delegate;
- (void) pause;

- (id)initWithSubmitter:(id<PhotoSubmitterProtocol>)submitter andContent:(PhotoSubmitterContentEntity *)content;
+ (id)operationWithOperation:(PhotoSubmitterOperation *)operation;
@end

/*!
 * delegate for operation
 */
@protocol PhotoSubmitterOperationDelegate <NSObject>
- (void) photoSubmitterOperation:(PhotoSubmitterOperation *)operation didFinished:(BOOL)suceeeded;
- (void) photoSubmitterOperationDidCanceled:(PhotoSubmitterOperation *)operation;
@end