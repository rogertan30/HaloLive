//
//  TYCyclePagerViewCell.m
//  TYCyclePagerViewDemo
//
//  Created by tany on 2017/6/14.
//  Copyright © 2017年 tany. All rights reserved.
//

#import "TYCyclePagerViewCell.h"

@interface TYCyclePagerViewCell ()
@property (nonatomic, weak) UILabel *label;
@end

@implementation TYCyclePagerViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        [self addImg];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.backgroundColor = [UIColor clearColor];
        [self addImg];
    }
    return self;
}


- (void)addImg {
    UIImageView *imgView = [[UIImageView alloc]init];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:imgView];
    _img = imgView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _img.frame = self.bounds;
    _img.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    _img.layer.cornerRadius = 8;
    _img.layer.masksToBounds = true;
}

@end
