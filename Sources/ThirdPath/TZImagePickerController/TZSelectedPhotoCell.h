//
//  TZSelectedPhotoCell.h
//  TZImagePickerController
//
//  Created by HaloLive on 2024.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TZAssetModel;
@class TZSelectedPhotoCell;

@protocol TZSelectedPhotoCellDelegate <NSObject>
- (void)selectedPhotoCellDidTapDelete:(TZSelectedPhotoCell *)cell;
@end

@interface TZSelectedPhotoCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UILabel *videoTimeLabel;
@property (nonatomic, strong) TZAssetModel *assetModel;
@property (nonatomic, weak) id<TZSelectedPhotoCellDelegate> delegate;

- (void)setAssetModel:(TZAssetModel *)assetModel;

@end

NS_ASSUME_NONNULL_END

