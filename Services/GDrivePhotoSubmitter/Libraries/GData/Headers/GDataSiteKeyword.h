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
//  GDataSiteKeyword.h
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_WEBMASTERTOOLS_SERVICE

#import "GDataObject.h"

// keyword, like
//  <wt:keyword source='internal'>cake</wt:keyword>

@interface GDataSiteKeyword : GDataObject <GDataExtension>

+ (GDataSiteKeyword *)keywordWithSource:(NSString *)source
                            stringValue:(NSString *)value;

- (NSString *)source;
- (void)setSource:(NSString *)str;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_WEBMASTERTOOLS_SERVICE
