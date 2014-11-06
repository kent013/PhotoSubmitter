//
//  ENGPhotoSubmitterAccount.m
//
//  Created by Kentaro ISHITOYA on 12/04/17.
//

#import "ENGPhotoSubmitterAccount.h"
#import "NSData+ENGDigest.h"

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterAccount(PrivateImplementation)
@end

@implementation ENGPhotoSubmitterAccount(PrivateImplementation)
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation ENGPhotoSubmitterAccount
@synthesize type = type_;
@synthesize index = index_;
@synthesize accountHash = accountHash_;

/*!
 * initialize
 */
- (id)initWithType:(NSString *)inType andIndex:(int)inIndex{
    self = [super init];
    if(self){
        type_ = inType;
        index_ = inIndex;
    }
    return self;
}

/*!
 * get account hash
 */
- (NSString *)accountHash{
    if(accountHash_ == nil){
        accountHash_ = [[[NSString stringWithFormat:@"%@%f", type_, [[NSDate date] timeIntervalSince1970]] dataUsingEncoding:NSUTF8StringEncoding] MD5DigestString];
    }
    return accountHash_;
}


/*!
 * encode
 */
- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeInt32:index_ forKey:@"index"];
    [coder encodeObject:type_ forKey:@"type"];
    [coder encodeObject:accountHash_ forKey:@"accountHash"];
}

/*!
 * init with coder
 */
- (id)initWithCoder:(NSCoder*)coder {
    self = [super init];
    if (self) {
        index_ = [coder decodeInt32ForKey:@"index"];
        type_ = [coder decodeObjectForKey:@"type"]; 
        accountHash_ = [coder decodeObjectForKey:@"accountHash"];
    }
    return self;
}
@end
