//
//  ENGPhotoSubmitterOperation.h
//
//  Created by ISHITOYA Kentaro on 11/12/19.
//

#import <Foundation/Foundation.h>
#import "ENGPhotoSubmitterProtocol.h"

@protocol ENGPhotoSubmitterOperationDelegate;

/*!
 * NSOperation subclass for submitting photo
 */
@interface ENGPhotoSubmitterOperation : NSOperation<NSCoding, ENGPhotoSubmitterPhotoOperationDelegate>{
    BOOL isExecuting;
    BOOL isFinished;
    BOOL isCancelled;
    BOOL isFailed;
    NSMutableArray *delegates_;
}
@property (strong, nonatomic) id<ENGPhotoSubmitterProtocol> submitter;
@property (strong, nonatomic) ENGPhotoSubmitterContentEntity *content;
@property (assign, nonatomic) BOOL isFailed;
@property (readonly, nonatomic) NSMutableArray *delegates;

- (void) resume;
- (void) addDelegate:(id<ENGPhotoSubmitterOperationDelegate>)delegate;
- (void) removeDelegate:(id<ENGPhotoSubmitterOperationDelegate>)delegate;
- (void) clearDelegate:(id<ENGPhotoSubmitterOperationDelegate>)delegate;
- (void) pause;

- (id)initWithSubmitter:(id<ENGPhotoSubmitterProtocol>)submitter andContent:(ENGPhotoSubmitterContentEntity *)content;
+ (id)operationWithOperation:(ENGPhotoSubmitterOperation *)operation;
@end

/*!
 * delegate for operation
 */
@protocol ENGPhotoSubmitterOperationDelegate <NSObject>
- (void) photoSubmitterOperation:(ENGPhotoSubmitterOperation *)operation didFinished:(BOOL)suceeeded;
- (void) photoSubmitterOperationDidCanceled:(ENGPhotoSubmitterOperation *)operation;
@end