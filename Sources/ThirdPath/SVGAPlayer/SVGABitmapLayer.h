//
//  SVGABitmapLayer.h
//  SVGAPlayer
//
//  Created by 崔明辉 on 2017/2/20.
//  Copyright © 2017年 UED Center. All rights reserved.
//

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#else
// For non-iOS platforms, provide minimal UIKit compatibility
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#endif

@class SVGAVideoSpriteFrameEntity;

@interface SVGABitmapLayer : CALayer

- (instancetype)initWithFrames:(NSArray<SVGAVideoSpriteFrameEntity *> *)frames;

- (void)stepToFrame:(NSInteger)frame;

@end
