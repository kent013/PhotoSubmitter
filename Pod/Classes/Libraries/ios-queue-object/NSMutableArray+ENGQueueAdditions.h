/*
 Generic queue.
 */

@interface NSMutableArray (ENGQueueAdditions)
-(id) dequeue;
-(void) enqueue:(id)obj;
-(id) peek:(int)index;
-(id) peekHead;
-(id) peekTail;
-(BOOL) empty;
@end