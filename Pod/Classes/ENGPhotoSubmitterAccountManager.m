//
//  ENGPhotoSubmitterAccountManager.m
//
//  Created by Kentaro ISHITOYA on 12/04/17.
//

#import "ENGPhotoSubmitterAccountManager.h"

static ENGPhotoSubmitterAccountManager *PhotoSubmitterAccountManagerInstance;
static NSString *kAccounts = @"PhotoSubmitterAccounts";

//-----------------------------------------------------------------------------
//Private Implementations
//-----------------------------------------------------------------------------
@interface ENGPhotoSubmitterAccountManager(PrivateImplementation)
- (void) load;
- (void) save;
@end

@implementation ENGPhotoSubmitterAccountManager(PrivateImplementation)
/*!
 * load accounts
 */
- (void) load{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults valueForKey:kAccounts];
    if([value isKindOfClass:[NSData class]]){
        value = [NSKeyedUnarchiver unarchiveObjectWithData: value];
    }
    
    if([value isKindOfClass:[NSMutableDictionary class]]){
        accounts_ = value;
    }else{
        accounts_ = [[NSMutableDictionary alloc] init];
    }
}

/*!
 * save accounts
 */
- (void) save{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSKeyedArchiver archivedDataWithRootObject:accounts_] 
                forKey:kAccounts];
    [defaults synchronize];    
}
@end

//-----------------------------------------------------------------------------
//Public Implementations
//-----------------------------------------------------------------------------
@implementation ENGPhotoSubmitterAccountManager
@synthesize accounts;

/*!
 * initialize
 */
- (id)init{
    self = [super init];
    if(self){
        [self load];
    }
    return self;
}

/*!
 * dealloc
 */
- (void)dealloc{
    [self save];
}

/*!
 * create account fort type
 */
- (ENGPhotoSubmitterAccount *)createAccountForType:(NSString *)type{
    int index = [self countAccountForType:type];
    ENGPhotoSubmitterAccount *account = [[ENGPhotoSubmitterAccount alloc] initWithType:type andIndex:index];
    [self addAccount:account];
    return account;
}

/*!
 * add account
 */
- (void)addAccount:(ENGPhotoSubmitterAccount *)account{
    if([accounts_ objectForKey:account.accountHash] != nil){
        NSLog(@"account %@, %@ already exists. %s", account.type, account.accountHash, __PRETTY_FUNCTION__);
        return;
    }
    [accounts_ setObject:account forKey:account.accountHash];
    [self save];
}

/*!
 * remove account
 */
- (void)removeAccount:(ENGPhotoSubmitterAccount *)account{
    if([accounts_ objectForKey:account.accountHash] == nil){
        NSLog(@"account %@, %@ not exist. %s", account.type, account.accountHash, __PRETTY_FUNCTION__);
        return;        
    }
    [accounts_ removeObjectForKey:account.accountHash];
    [self save];
}

/*!
 * count matched account
 */
- (int)countAccountForType:(NSString *)type{
    return [self accountsForType:type].count;
}

/*!
 * check for account existance
 */
- (BOOL)containsAccount:(ENGPhotoSubmitterAccount *)account{
    return [accounts_ objectForKey:account.accountHash] != nil;
}

/*!
 * get list of accounts of type
 */
- (NSArray *)accountsForType:(NSString *)type{
    type = [type lowercaseString];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for(NSString *key in accounts_){
        ENGPhotoSubmitterAccount *account = [accounts_ objectForKey:key];
        
        if([[account.type lowercaseString] isEqualToString:type]){
            [array addObject:account];
        }
    }
    return array;
}

/*!
 * get single account
 */
- (ENGPhotoSubmitterAccount *)accountForType:(NSString *)type andIndex:(int)index{
    for(NSString *key in accounts_){
        ENGPhotoSubmitterAccount *account = [accounts_ objectForKey:key];
        if([account.type isEqualToString:type] &&
           account.index == index){
            return account;
        }
    }
    ENGPhotoSubmitterAccount *account = [[ENGPhotoSubmitterAccount alloc] initWithType:type andIndex:index];
    [self addAccount:account];
    return account;
}

/*!
 * get account hash
 */
- (ENGPhotoSubmitterAccount *)accountForHash:(NSString *)hash{
    return [accounts_ objectForKey:hash];
}

/*!
 * accounts
 */
- (NSArray *)accounts{
    return [accounts_ allValues];
}

/*!
 * singleton
 */
+ (ENGPhotoSubmitterAccountManager *)sharedManager{
    if(PhotoSubmitterAccountManagerInstance == nil){
        PhotoSubmitterAccountManagerInstance = 
        [[ENGPhotoSubmitterAccountManager alloc] init];
    }
    return PhotoSubmitterAccountManagerInstance;
}
@end
