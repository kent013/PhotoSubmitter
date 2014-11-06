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
//  GDataServiceGoogleBlogger.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_BLOGGER_SERVICE

#import "GDataServiceGoogle.h"


@interface GDataServiceGoogleBlogger : GDataServiceGoogle

// use kGDataServiceDefaultUser for the feed for the authenticated user
+ (NSURL *)blogFeedURLForUserID:(NSString *)user;

// clients may use these fetch methods of GDataServiceGoogle
//
// feed fetch calls must specify the expected object return class,
// [GDataFeedBlog class] or [GDataFeedBlogPost class] or [GDataFeedBlogComment class]
//
//  - (GDataServiceTicket *)fetchFeedWithURL:(NSURL *)feedURL feedClass:(Class)feedClass delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)fetchFeedWithQuery:(GDataQuery *)query feedClass:(Class)feedClass delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//
// entry fetch calls must specify the expected object return class,
// [GDataEntryBlog class] or [GDataEntryBlogPost class] or [GDataEntryBlogComment class]
//
//  - (GDataServiceTicket *)fetchEntryWithURL:(NSURL *)entryURL entryClass:(Class)entryClass delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//
// Additional calls:
//
//  - (GDataServiceTicket *)fetchEntryByInsertingEntry:(GDataEntryBase *)entryToInsert forFeedURL:(NSURL *)feedURL delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)fetchEntryByUpdatingEntry:(GDataEntryBase *)entryToUpdate delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)deleteEntry:(GDataEntryBase *)entryToDelete delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//  - (GDataServiceTicket *)deleteResourceURL:(NSURL *)resourceEditURL ETag:(NSString *)etag delegate:(id)delegate didFinishSelector:(SEL)finishedSelector;
//
// finishedSelector has a signature like this for feed fetches:
// - (void)serviceTicket:(GDataServiceTicket *)ticket finishedWithFeed:(GDataFeedBase *)feed error:(NSError *)error;
//
// or this for entry fetches:
// - (void)serviceTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataEntryBase *)entry error:(NSError *)error;
//
// The class of the returned feed or entry is determined by the URL fetched.

+ (NSString *)serviceRootURLString;

@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_BLOGGER_SERVICE
