//
//  MessageSegment.m
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

#import "SFMessageSegment.h"


@implementation SFMessageSegment

@synthesize type;
@synthesize text;
@synthesize name;
@synthesize tag;
@synthesize url;
@synthesize user;

+(void)setupMapping:(RKObjectManager*)manager {
	RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[SFMessageSegment class]];
	
	[mapping mapAttributes:@"text", @"type", @"name", @"tag", @"url", nil];
	
	// Assuming that UserSummary already registered mappings.
	RKObjectMapping* userSummaryMapping = [[[RKObjectManager sharedManager] mappingProvider] objectMappingForClass:[SFUserSummary class]];
	[mapping hasOne:@"user" withMapping:userSummaryMapping];
	
	[manager.mappingProvider addObjectMapping:mapping];
}

- (void)dealloc {
	[type release];
	[text release];
	[name release];
	[tag release];
	[url release];
	[user release];
	
	[super dealloc];
}

@end
