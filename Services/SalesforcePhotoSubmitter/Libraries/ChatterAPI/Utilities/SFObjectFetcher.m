//
//  ObjectFetcher.m
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

#import "SFObjectFetcher.h"
#import "SFAuthContext.h"

@implementation SFObjectFetcher

@synthesize tag;
@synthesize obj;
@synthesize delegate;

- initWithTag:(NSString*)inTag object:(id)inObj delegate:(NSObject<SFObjectFetcherDelegate>*)inDelegate {
	self = [super init];
	
	if (self != nil) {
		self.tag = inTag;
		self.obj = inObj;
		self.delegate = inDelegate;
	}
	
	return self;
}

- (void)dealloc {
	[tag release];
	[obj release];
	
	[super dealloc];
}

- (void)fetch {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
	RKObjectLoader* loader = [[RKObjectManager sharedManager] objectLoaderForObject:self.obj method:RKRequestMethodGET delegate:self];
#pragma clang diagnostic pop
	[[SFAuthContext context] addOAuthHeader:loader];	
	
	[loader setObjectMapping:[[[RKObjectManager sharedManager] mappingProvider] objectMappingForClass:[self.obj class]]];
	[loader send];
}

// RKObjectLoaderDelegate implementation

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
	[delegate retrievalCompleted:self.tag withSuccess:TRUE];
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader {
	NSLog(@"Fetch for %@ failed unexpectedly", self.tag);
	[delegate retrievalCompleted:self.tag withSuccess:FALSE];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
	NSLog(@"Fetch for %@ failed with error: %@", self.tag, error); 
	[delegate retrievalCompleted:self.tag withSuccess:FALSE];
}

@end