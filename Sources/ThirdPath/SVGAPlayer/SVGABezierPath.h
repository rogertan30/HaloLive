//
//  SVGABezierPath.h
//  SVGAPlayer
//
//  Created by 崔明辉 on 16/6/28.
//  Copyright © 2016年 UED Center. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
// For non-iOS platforms, provide minimal UIKit compatibility
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#endif

@interface SVGABezierPath : UIBezierPath

- (void)setValues:(nonnull NSString *)values;

- (nonnull CAShapeLayer *)createLayer;

@end
