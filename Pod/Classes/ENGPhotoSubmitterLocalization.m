//
//  ENGPhotoSubmitterLocalization.h
//  Pods
//
//  Created by ISHITOYA Kentaro on 2014/11/10.
//
//

#import "ENGPhotoSubmitterLocalization.h"

NSString *ENGPhotoSubmitterLocalization(NSString *key){
    static NSBundle *bundle = nil;
    if (!bundle) {
        NSString *bundlePath = [NSBundle.mainBundle pathForResource:@"ENGPhotoSubmitter" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:bundlePath];
        NSString *language = NSLocale.preferredLanguages.count? NSLocale.preferredLanguages.firstObject: @"en";
        if (![bundle.localizations containsObject:language]) {
            language = [language componentsSeparatedByString:@"-"].firstObject;
        }
        if ([bundle.localizations containsObject:language]) {
            bundlePath = [bundle pathForResource:language ofType:@"lproj"];
        }
        bundle = [NSBundle bundleWithPath:bundlePath] ?: NSBundle.mainBundle;
    }
    
    NSString *defaultString = [bundle localizedStringForKey:key value:key table:nil];
    return [NSBundle.mainBundle localizedStringForKey:key value:defaultString table:nil];
}