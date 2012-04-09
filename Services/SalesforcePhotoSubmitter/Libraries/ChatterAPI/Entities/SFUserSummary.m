//
//  UserSummary.m
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

#import "SFUserSummary.h"

@implementation SFUserSummary

@synthesize userId;
@synthesize firstName;
@synthesize lastName;
@synthesize name;
@synthesize title;
@synthesize photo;

+(void)setupMapping:(RKObjectManager*)manager {
	RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[SFUserSummary class]];
	[SFUserSummary populateMapping:mapping];
	[manager.mappingProvider addObjectMapping:mapping];
}

+(void)populateMapping:(RKObjectMapping*)mapping {
	// TODO: Do repetitive tasks in a nicer way.
	
	[mapping mapAttributes:@"firstName", @"lastName", @"name", @"title", nil];
	[mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userId"]];
	
	// Assuming that the Photo mapping is registered.
	RKObjectMapping* photoMapping = [[[RKObjectManager sharedManager] mappingProvider] objectMappingForClass:[SFPhoto class]];
	[mapping addRelationshipMapping:[RKObjectRelationshipMapping mappingFromKeyPath:@"photo" toKeyPath:@"photo" withMapping:photoMapping]];
}

- (void)dealloc {
	[userId release];
	[firstName release];
	[lastName release];
	[name release];
	[title release];
	[photo release];
	
	[super dealloc];
}

@end
