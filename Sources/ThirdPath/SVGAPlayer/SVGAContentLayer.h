//
//  SVGAContentLayer.h
//  SVGAPlayer
//
//  Created by 崔明辉 on 2017/2/22.
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
#import "SVGAPlayer.h"

@class SVGABitmapLayer, SVGAVectorLayer, SVGAVideoSpriteFrameEntity;

@interface SVGAContentLayer : CALayer

@property (nonatomic, strong) NSString *imageKey;
@property (nonatomic, assign) BOOL dynamicHidden;
@property (nonatomic, copy) SVGAPlayerDynamicDrawingBlock dynamicDrawingBlock;
@property (nonatomic, strong) SVGABitmapLayer *bitmapLayer;
@property (nonatomic, strong) SVGAVectorLayer *vectorLayer;
@property (nonatomic, strong) CATextLayer *textLayer;

- (instancetype)initWithFrames:(NSArray<SVGAVideoSpriteFrameEntity *> *)frames;

- (void)stepToFrame:(NSInteger)frame;
- (void)resetTextLayerProperties:(NSAttributedString *)attributedString;

@end
