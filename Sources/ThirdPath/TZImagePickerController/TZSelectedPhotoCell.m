//
//  TZSelectedPhotoCell.m
//  TZImagePickerController
//
//  Created by HaloLive on 2024.
//

#import "TZSelectedPhotoCell.h"
#import "TZAssetModel.h"
#import "TZImageManager.h"
#import "UIView+TZLayout.h"

@implementation TZSelectedPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 设置cell尺寸为60x60
    self.frame = CGRectMake(0, 0, 60, 60);
    
    // 创建图片视图
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    _imageView.layer.cornerRadius = 6;
    _imageView.backgroundColor = [UIColor lightGrayColor];
    [self.contentView addSubview:_imageView];
    
    // 创建右上角半透明阴影覆盖层
    UIView *shadowOverlay = [[UIView alloc] init];
    shadowOverlay.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]; // #000000 30%透明度
    
    // 设置只有右上角和左下角的6px圆角
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 0)]; // 左上角
    [path addLineToPoint:CGPointMake(14, 0)]; // 右上角圆角开始点
    [path addQuadCurveToPoint:CGPointMake(20, 6) controlPoint:CGPointMake(20, 0)]; // 右上角6px圆角
    [path addLineToPoint:CGPointMake(20, 20)]; // 右下角
    [path addLineToPoint:CGPointMake(6, 20)]; // 左下角圆角开始点
    [path addQuadCurveToPoint:CGPointMake(0, 14) controlPoint:CGPointMake(0, 20)]; // 左下角6px圆角
    [path closePath];
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = path.CGPath;
    shadowOverlay.layer.mask = maskLayer;
    
    shadowOverlay.frame = CGRectMake(40, 0, 20, 20); // 20x20尺寸，位于照片右上角内部
    [self.contentView addSubview:shadowOverlay];
    
    // 创建删除按钮
    _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // 尝试加载close_white_img@2x图片，如果没有则使用系统图标
    UIImage *closeImage = [UIImage imageNamed:@"close_white_img@2x"];
    if (!closeImage) {
        closeImage = [UIImage systemImageNamed:@"xmark"];
    }
    if (!closeImage) {
        closeImage = [self createDeleteIcon];
    }
    
    // 设置图标颜色为白色
    closeImage = [closeImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_deleteButton setImage:closeImage forState:UIControlStateNormal];
    [_deleteButton setTintColor:[UIColor whiteColor]]; // 设置图标颜色为白色
    
    _deleteButton.backgroundColor = [UIColor clearColor]; // 透明背景，因为已经有阴影覆盖层
    _deleteButton.frame = CGRectMake(3, 3, 14, 14); // 14x14尺寸，添加3px padding
    [_deleteButton addTarget:self action:@selector(deleteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [shadowOverlay addSubview:_deleteButton];
    
    // 创建视频时间标签
    _videoTimeLabel = [[UILabel alloc] init];
    _videoTimeLabel.textColor = [UIColor whiteColor];
    _videoTimeLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightMedium];
    _videoTimeLabel.textAlignment = NSTextAlignmentRight;
    _videoTimeLabel.backgroundColor = [UIColor clearColor];
    _videoTimeLabel.hidden = YES; // 默认隐藏
    [self.contentView addSubview:_videoTimeLabel];
    
    // 设置约束
    _imageView.frame = CGRectMake(0, 0, 60, 60);
    // 视频时间标签位置：右下角，距离边缘8px，宽度调整为40px以完整显示时间
    _videoTimeLabel.frame = CGRectMake(60 - 8 - 40, 60 - 8 - 12, 40, 12);
}

- (void)setAssetModel:(TZAssetModel *)assetModel {
    _assetModel = assetModel;
    
    if (assetModel) {
        // 获取缩略图
        [[TZImageManager manager] getPhotoWithAsset:assetModel.asset photoWidth:120 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (photo) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = photo;
                });
            }
        }];
        
        // 根据资源类型显示/隐藏视频时间标签
        if (assetModel.type == TZAssetModelMediaTypeVideo) {
            _videoTimeLabel.hidden = NO;
            _videoTimeLabel.text = assetModel.timeLength;
        } else {
            _videoTimeLabel.hidden = YES;
        }
    } else {
        self.imageView.image = nil;
        _videoTimeLabel.hidden = YES;
    }
}

- (void)deleteButtonTapped {
    if ([self.delegate respondsToSelector:@selector(selectedPhotoCellDidTapDelete:)]) {
        [self.delegate selectedPhotoCellDidTapDelete:self];
    }
}

- (UIImage *)createDeleteIcon {
    // 创建一个简单的X图标
    CGSize size = CGSizeMake(12, 12);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 设置线条属性
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 2.0);
    CGContextSetLineCap(context, kCGLineCapRound);
    
    // 绘制X
    CGContextMoveToPoint(context, 2, 2);
    CGContextAddLineToPoint(context, size.width - 2, size.height - 2);
    CGContextMoveToPoint(context, size.width - 2, 2);
    CGContextAddLineToPoint(context, 2, size.height - 2);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
