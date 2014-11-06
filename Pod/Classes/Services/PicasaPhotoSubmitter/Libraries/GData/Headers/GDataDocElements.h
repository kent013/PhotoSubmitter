/* Copyright (c) 2011 Google Inc.
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
// GDataDocElements.m
//
// Elements used by the Docs API
//

#if !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_DOCS_SERVICE

#import "GDataPerson.h"
#import "GDataValueConstruct.h"

@interface GDataLastModifiedBy : GDataPerson <GDataExtension>
@end

@interface GDataQuotaBytesTotal : GDataValueElementConstruct <GDataExtension>
@end

@interface GDataQuotaBytesUsed : GDataValueElementConstruct <GDataExtension>
@end

@interface GDataDocLargestChangestamp : GDataValueConstruct <GDataExtension>
@end

#endif // !GDATA_REQUIRE_SERVICE_INCLUDES || GDATA_INCLUDE_DOCS_SERVICE
