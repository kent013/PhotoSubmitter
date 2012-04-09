//
//  User.m
//  DemoApp
//
//  Copyright 2011 Salesforce.com. All rights reserved.
//
//  This is sample code provided as a learning tool. Feel free to 
//  learn from it and incorporate elements into your own code. 
//  No guarantees are made about the quality or security of this code.
//
//  THIS SOFTWARE IS PROVIDED BY Salesforce.com "AS IS" AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Salesforce.com OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "SFUser.h"
#import "SFConfig.h"

@implementation SFUser

@synthesize about;
@synthesize email;
@synthesize managerId;
@synthesize managerName;
@synthesize url;
@synthesize address;

+(void)setupMapping:(RKObjectManager*)manager {
	RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[SFUser class]];
	[SFUserSummary populateMapping:mapping];
	[mapping mapAttributes:@"email", @"managerId", @"managerName", @"url", nil ];
	[mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"aboutMe" toKeyPath:@"about"]];
	
	// Assuming that the Address mapping is registered.
	RKObjectMapping* addressMapping = [[[RKObjectManager sharedManager] mappingProvider] objectMappingForClass:[SFAddress class]];
	[mapping addRelationshipMapping:[RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping]];
	
	[manager.router routeClass:[SFUser class] toResourcePath:[SFConfig addVersionPrefix:@"/chatter/users/:userId"] forMethod:RKRequestMethodGET];	
	[manager.mappingProvider addObjectMapping:mapping];
}

- (void)dealloc {
	[about release];
	[email release];
	[managerId release];
	[managerName release];
	[url release];
	[address release];
	
	[super dealloc];
}

@end
