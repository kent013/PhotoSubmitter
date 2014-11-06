/* Copyright (c) 2009 Google Inc.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

//
//  GDataServiceACL.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_ACLS \
  || GDATA_INCLUDE_CALENDAR_SERVICE || GDATA_INCLUDE_DOCS_SERVICE

#import "GDataServiceGoogle.h"

@class GDataEntryACL;

// GDataServiceGoogle is the version of the service class that supports
// Google authentication.
@interface GDataServiceGoogle (GDataServiceACLAdditions)

- (GDataServiceTicket *)fetchACLFeedWithURL:(NSURL *)feedURL
                                   delegate:(id)delegate
                          didFinishSelector:(SEL)finishedSelector;

- (GDataServiceTicket *)fetchACLEntryByInsertingEntry:(GDataEntryACL *)entryToInsert
                                           forFeedURL:(NSURL *)feedURL
                                             delegate:(id)delegate
                                    didFinishSelector:(SEL)finishedSelector;

- (GDataServiceTicket *)fetchACLEntryByUpdatingEntry:(GDataEntryACL *)entryToUpdate
                                            delegate:(id)delegate
                                   didFinishSelector:(SEL)finishedSelector;

- (GDataServiceTicket *)fetchACLEntryByUpdatingEntry:(GDataEntryACL *)entryToUpdate
                                         forEntryURL:(NSURL *)entryURL
                                            delegate:(id)delegate
                                   didFinishSelector:(SEL)finishedSelector;

- (GDataServiceTicket *)deleteACLEntry:(GDataEntryACL *)entryToDelete
                              delegate:(id)delegate
                     didFinishSelector:(SEL)finishedSelector;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDE || GDATA_INCLUDE_*
