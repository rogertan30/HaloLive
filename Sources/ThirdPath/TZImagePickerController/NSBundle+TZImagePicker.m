//
//  NSBundle+TZImagePicker.m
//  TZImagePickerController
//
//  Created by 谭真 on 16/08/18.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "NSBundle+TZImagePicker.h"
#import "TZImagePickerController.h"

@implementation NSBundle (TZImagePicker)

+ (NSBundle *)tz_imagePickerBundle {
#ifdef SWIFT_PACKAGE
    // When building with Swift Package Manager, all resources declared with
    // Package.swift are embedded directly in the module's resource bundle.
    // There is no nested "TZImagePickerController.bundle" inside it, so we
    // should return the module bundle itself.
    return SWIFTPM_MODULE_BUNDLE;
#else
    NSBundle *bundle = [NSBundle bundleForClass:[TZImagePickerController class]];
    NSURL *url = [bundle URLForResource:@"TZImagePickerController" withExtension:@"bundle"];
    return [NSBundle bundleWithURL:url];
#endif
}

+ (NSString *)tz_localizedStringForKey:(NSString *)key {
    return [self tz_localizedStringForKey:key value:@""];
}

+ (NSString *)tz_localizedStringForKey:(NSString *)key value:(NSString *)value {
    NSBundle *bundle = [TZImagePickerConfig sharedInstance].languageBundle;
    NSString *value1 = [bundle localizedStringForKey:key value:value table:nil];
    return value1;
}

@end
