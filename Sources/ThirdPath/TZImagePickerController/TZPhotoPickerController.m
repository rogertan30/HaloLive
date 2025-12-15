//
//  TZPhotoPickerController.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "TZPhotoPickerController.h"
#import "TZImagePickerController.h"
#import "TZPhotoPreviewController.h"
#import "TZAssetCell.h"
#import "TZAssetModel.h"
#import "UIView+TZLayout.h"
#import "TZImageManager.h"
#import "TZVideoPlayerController.h"
#import "TZGifPhotoPreviewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "TZImageRequestOperation.h"
#import "TZAuthLimitedFooterTipView.h"
#import "TZSelectedPhotoCell.h"
#import <PhotosUI/PhotosUI.h>
@interface TZPhotoPickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, PHPhotoLibraryChangeObserver, TZSelectedPhotoCellDelegate> {
    NSMutableArray *_models;
    
    // 新的选中照片展示控件
    UIView *_selectedPhotosContainer;
    UICollectionView *_selectedPhotosCollectionView;
    UIButton *_nextButton;
    
    BOOL _shouldScrollToBottom;
    BOOL _showTakePhotoBtn;
    BOOL _authorizationLimited;
    
    CGFloat _offsetItemCount;
}
@property CGRect previousPreheatRect;
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;
@property (nonatomic, strong) TZCollectionView *collectionView;
@property (nonatomic, strong) TZAuthLimitedFooterTipView *authFooterTipView;
@property (nonatomic, strong) UILabel *noDataLabel;
@property (strong, nonatomic) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UIImagePickerController *imagePickerVc;
@property (strong, nonatomic) CLLocation *location;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL isSavingMedia;
@property (nonatomic, assign) BOOL isFetchingMedia;
@property (nonatomic, strong) UIView *albumPickerView;
@property (nonatomic, strong) UITableView *albumPickerTableView;
@property (nonatomic, strong) UITapGestureRecognizer *dismissGesture;
@property (nonatomic, strong) NSMutableArray *albumArr;
@property (nonatomic, assign) BOOL isAlbumPickerVisible;
@property (nonatomic, strong) TZAlbumModel *selectedAlbumModel;

// Tab switcher properties
@property (nonatomic, strong) UIView *tabSwitcherView;
@property (nonatomic, strong) NSArray *tabButtons;
@property (nonatomic, assign) NSInteger currentTabIndex;
@property (nonatomic, strong) UIView *tabIndicatorView;
@property (nonatomic, strong) NSMutableArray *allModels;
@property (nonatomic, strong) NSMutableArray *photoModels;
@property (nonatomic, strong) NSMutableArray *videoModels;
@property (nonatomic, strong) UIImageView *titleArrowImageView;

@end

static CGSize AssetGridThumbnailSize;
static CGFloat itemMargin = 4;

@implementation TZPhotoPickerController

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
        // set appearance / 改变相册选择页的导航栏外观
        _imagePickerVc.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
        _imagePickerVc.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        UIBarButtonItem *tzBarItem, *BarItem;
        if (@available(iOS 9, *)) {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
            BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
        } else {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedIn:[TZImagePickerController class], nil];
            BarItem = [UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil];
        }
        NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
        [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
    return _imagePickerVc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([[TZImageManager manager] authorizationStatusAuthorized] || !SYSTEM_VERSION_GREATER_THAN_15) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    self.isFirstAppear = YES;
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    _isSelectOriginalPhoto = tzImagePickerVc.isSelectOriginalPhoto;
    _shouldScrollToBottom = YES;
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = UIColor.tertiarySystemBackgroundColor;
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    // Create close button with image
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(15, 0, 20, 20); // 20px size, 15px left margin
    [closeButton setImage:[UIImage tz_imageNamedFromMyBundle:@"close_img"] forState:UIControlStateNormal];
    closeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [closeButton addTarget:tzImagePickerVc action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
    self.navigationItem.leftBarButtonItem = closeItem;
    
    // Configure title with custom style and tap gesture
    // Create custom title view container with title and arrow
    UIView *titleContainerView = [[UIView alloc] init];
    
    // Create title label
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = _model.name;
    titleLabel.textColor = [UIColor colorWithRed:0x1A/255.0 green:0x1A/255.0 blue:0x1A/255.0 alpha:1.0]; // #1A1A1A
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:16]; // 16px, font-weight: 700
    [titleLabel sizeToFit];
    
    // Create arrow icon
    UIImageView *arrowImageView = [[UIImageView alloc] init];
    // Load image directly from bundle without @2x suffix
    NSBundle *imageBundle = [NSBundle tz_imagePickerBundle];
    NSString *imagePath = [imageBundle pathForResource:@"arrow_down" ofType:@"png"];
    UIImage *arrowImage = [UIImage imageWithContentsOfFile:imagePath];
    
    // Debug: Check if image was loaded successfully
    if (arrowImage) {
        arrowImageView.image = arrowImage;
        NSLog(@"TZImagePicker: Successfully loaded arrow_down image from path: %@", imagePath);
    } else {
        // Fallback: try to load with @2x suffix as backup
        NSString *imagePath2x = [imageBundle pathForResource:@"arrow_down@2x" ofType:@"png"];
        UIImage *arrowImage2x = [UIImage imageWithContentsOfFile:imagePath2x];
        if (arrowImage2x) {
            arrowImageView.image = arrowImage2x;
            NSLog(@"TZImagePicker: Successfully loaded arrow_down@2x image from path: %@", imagePath2x);
        } else {
            // Last resort: create a simple arrow using system image or draw one
            NSLog(@"TZImagePicker: Could not load arrow_down image from bundle. Bundle path: %@, Image path: %@, @2x path: %@", imageBundle.bundlePath, imagePath, imagePath2x);
            // Create a simple arrow using system symbols if available
            if (@available(iOS 13.0, *)) {
                arrowImageView.image = [UIImage systemImageNamed:@"chevron.down"];
                NSLog(@"TZImagePicker: Using system chevron.down as fallback");
            }
        }
    }
    
    arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    arrowImageView.frame = CGRectMake(0, 0, 14, 14);
    
    // Calculate container size
    CGFloat titleWidth = titleLabel.frame.size.width;
    CGFloat arrowWidth = 14;
    CGFloat spacing = 2; // 2px spacing between title and arrow
    CGFloat containerWidth = titleWidth + spacing + arrowWidth;
    CGFloat containerHeight = MAX(titleLabel.frame.size.height, 14);
    
    // Set container frame
    titleContainerView.frame = CGRectMake(0, 0, containerWidth, containerHeight);
    
    // Position title label (centered vertically)
    titleLabel.frame = CGRectMake(0, (containerHeight - titleLabel.frame.size.height) / 2, titleWidth, titleLabel.frame.size.height);
    
    // Position arrow (2px to the right of title)
    arrowImageView.frame = CGRectMake(titleWidth + spacing, (containerHeight - 14) / 2, 14, 14);
    
    // Add subviews to container
    [titleContainerView addSubview:titleLabel];
    [titleContainerView addSubview:arrowImageView];
    
    // Store arrow reference for rotation animation
    self.titleArrowImageView = arrowImageView;
    
    // Add tap gesture to entire container
    UITapGestureRecognizer *titleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleTapped)];
    titleContainerView.userInteractionEnabled = YES;
    [titleContainerView addGestureRecognizer:titleTapGesture];
    
    self.navigationItem.titleView = titleContainerView;
    _showTakePhotoBtn = _model.isCameraRoll && ((tzImagePickerVc.allowTakePicture && tzImagePickerVc.allowPickingImage) || (tzImagePickerVc.allowTakeVideo && tzImagePickerVc.allowPickingVideo));
    _authorizationLimited = _model.isCameraRoll && [[TZImageManager manager] isPHAuthorizationStatusLimited];
    // [self resetCachedAssets];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 3;
    
    // Initialize tab switcher
    [self setupTabSwitcher];
}

- (void)setupTabSwitcher {
    // Create tab switcher view
    self.tabSwitcherView = [[UIView alloc] init];
    self.tabSwitcherView.backgroundColor = [UIColor whiteColor];
    
    // Remove any default borders
    self.tabSwitcherView.layer.borderWidth = 0;
    self.tabSwitcherView.layer.borderColor = [UIColor clearColor].CGColor;
    
    // Add shadow
    self.tabSwitcherView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tabSwitcherView.layer.shadowOffset = CGSizeMake(0, 1);
    self.tabSwitcherView.layer.shadowOpacity = 0.1;
    self.tabSwitcherView.layer.shadowRadius = 2;
    
    // Create tab buttons
    NSArray *tabTitles = @[@"All", @"Video", @"Photos"];
    NSMutableArray *buttons = [NSMutableArray array];
    
    for (NSInteger i = 0; i < tabTitles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:tabTitles[i] forState:UIControlStateNormal];
        // Unselected style: #A3A3A3, 13px, font-weight: 500
        [button setTitleColor:[UIColor colorWithRed:0xA3/255.0 green:0xA3/255.0 blue:0xA3/255.0 alpha:1.0] forState:UIControlStateNormal];
        // Selected style: #1A1A1A, 13px, font-weight: 600
        [button setTitleColor:[UIColor colorWithRed:0x1A/255.0 green:0x1A/255.0 blue:0x1A/255.0 alpha:1.0] forState:UIControlStateSelected];
        button.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium]; // 13px, font-weight: 500
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.tag = i;
        [button addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabSwitcherView addSubview:button];
        [buttons addObject:button];
    }
    
    self.tabButtons = [buttons copy];
    
    // Get default tab index from parent TZImagePickerController
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    NSInteger defaultTabIndex = tzImagePickerVc.defaultTabIndex;
    
    // Validate defaultTabIndex and fallback to 0 if invalid
    if (defaultTabIndex < 0 || defaultTabIndex >= tabTitles.count) {
        defaultTabIndex = 0;
    }
    
    self.currentTabIndex = defaultTabIndex;
    
    // Create indicator view - bottom underline style
    self.tabIndicatorView = [[UIView alloc] init];
    self.tabIndicatorView.backgroundColor = [UIColor colorWithRed:0x1A/255.0 green:0x1A/255.0 blue:0x1A/255.0 alpha:1.0]; // #1A1A1A
    self.tabIndicatorView.layer.cornerRadius = 1.0; // 1px border radius for 2px height (5px border radius as per design)
    [self.tabSwitcherView addSubview:self.tabIndicatorView];
    
    // Ensure indicator is on top of buttons
    [self.tabSwitcherView bringSubviewToFront:self.tabIndicatorView];
    
    // Set initial selected state
    [self updateTabSelection];
    
    [self.view addSubview:self.tabSwitcherView];
}

- (void)tabButtonTapped:(UIButton *)sender {
    if (self.currentTabIndex == sender.tag) {
        return;
    }
    
    self.currentTabIndex = sender.tag;
    [self updateTabSelection];
    [self switchToTab:sender.tag];
}

- (void)updateTabSelection {
    for (NSInteger i = 0; i < self.tabButtons.count; i++) {
        UIButton *button = self.tabButtons[i];
        button.selected = (i == self.currentTabIndex);
        // Selected: 13px, font-weight: 600; Unselected: 13px, font-weight: 500
        button.titleLabel.font = (i == self.currentTabIndex) ? [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold] : [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    }
    
    // Animate indicator
    [UIView animateWithDuration:0.3 animations:^{
        [self updateTabIndicatorPosition];
    }];
}

- (void)updateTabIndicatorPosition {
    if (self.tabButtons.count > 0) {
        UIButton *selectedButton = self.tabButtons[self.currentTabIndex];
        // New underline style: 7px width, 2px height, 1px border radius
        CGFloat indicatorWidth = 7;
        CGFloat indicatorHeight = 2;
        CGFloat indicatorX = CGRectGetMidX(selectedButton.frame) - indicatorWidth / 2;
        // Position indicator 6px from the bottom of the selected button (not tabSwitcherView)
        CGFloat indicatorY = CGRectGetMaxY(selectedButton.frame) - indicatorHeight - 6;
        
        self.tabIndicatorView.frame = CGRectMake(indicatorX, indicatorY, indicatorWidth, indicatorHeight);
    }
}

- (void)switchToTab:(NSInteger)tabIndex {
    // Hide all collection views first
    self.allCollectionView.hidden = YES;
    self.videoCollectionView.hidden = YES;
    self.photoCollectionView.hidden = YES;
    
    // Show the selected collection view and update models
    switch (tabIndex) {
        case 0: // All
            self.allCollectionView.hidden = NO;
            _collectionView = self.allCollectionView;
            _models = [NSMutableArray arrayWithArray:self.allModels];
            break;
        case 1: // Video
            self.videoCollectionView.hidden = NO;
            _collectionView = self.videoCollectionView;
            _models = [NSMutableArray arrayWithArray:self.videoModels];
            break;
        case 2: // Photos
            self.photoCollectionView.hidden = NO;
            _collectionView = self.photoCollectionView;
            _models = [NSMutableArray arrayWithArray:self.photoModels];
            break;
        default:
            break;
    }
    
    // Update content size and no data label
    [self updateAllCollectionViews];
    
    // Reload the collection view
    [_collectionView reloadData];
    
    // Check selected models for the current collection view
    [self checkSelectedModels];
    
    // Refresh bottom tool bar status
    [self refreshBottomToolBarStatus];

    // Default each tab to bottom on switch
    [self scrollCollectionViewToBottom:_collectionView];
}

- (void)fetchAssetModels {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (_isFirstAppear && !_model.models.count) {
        [tzImagePickerVc showProgressHUD];
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CGFloat systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
        if (!tzImagePickerVc.sortAscendingByModificationDate && self->_isFirstAppear && self->_model.isCameraRoll) {
            [[TZImageManager manager] getCameraRollAlbumWithFetchAssets:YES completion:^(TZAlbumModel *model) {
                self->_model = model;
                [self categorizeModels:self->_model.models];
                [self initSubviews];
            }];
        } else if (self->_showTakePhotoBtn || self->_isFirstAppear || !self.model.models || systemVersion >= 14.0) {
            [[TZImageManager manager] getAssetsFromFetchResult:self->_model.result completion:^(NSArray<TZAssetModel *> *models) {
                [self categorizeModels:models];
                [self initSubviews];
            }];
        } else {
            [self categorizeModels:self->_model.models];
            [self initSubviews];
        }
    });
}

- (void)categorizeModels:(NSArray<TZAssetModel *> *)models {
    // Initialize arrays
    self.allModels = [NSMutableArray arrayWithArray:models];
    self.photoModels = [NSMutableArray array];
    self.videoModels = [NSMutableArray array];
    
    // Categorize models
    for (TZAssetModel *model in models) {
        if (model.type == TZAssetModelMediaTypeVideo) {
            [self.videoModels addObject:model];
        } else if (model.type == TZAssetModelMediaTypePhoto || model.type == TZAssetModelMediaTypePhotoGif) {
            [self.photoModels addObject:model];
        }
    }
    
    // Set initial models to all models for backward compatibility
    _models = [NSMutableArray arrayWithArray:self.allModels];
}

- (void)initSubviews {
    dispatch_async(dispatch_get_main_queue(), ^{
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        [tzImagePickerVc hideProgressHUD];
        
        [self checkSelectedModels];
        [self configCollectionViews];
        [self configBottomToolBar];
        [self prepareScrollCollectionViewToBottom];
        
        // Reload all collection views first
        [_allCollectionView reloadData];
        [_videoCollectionView reloadData];
        [_photoCollectionView reloadData];
        
        // Wait for collection views to finish layout before scrolling
        // This ensures all cells are properly sized and positioned
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Double-check that collection views have valid content size
            if (self->_allCollectionView.contentSize.height > 0) {
                [self scrollCollectionViewToBottom:self.allCollectionView];
            }
            if (self->_videoCollectionView.contentSize.height > 0) {
                [self scrollCollectionViewToBottom:self.videoCollectionView];
            }
            if (self->_photoCollectionView.contentSize.height > 0) {
                [self scrollCollectionViewToBottom:self.photoCollectionView];
            }
            
            // Apply the default tab selection after scrolling is complete
            [self switchToTab:self.currentTabIndex];
        });
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    tzImagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    TZImagePickerController *tzImagePicker = (TZImagePickerController *)self.navigationController;
    if (tzImagePicker && [tzImagePicker isKindOfClass:[TZImagePickerController class]]) {
        return tzImagePicker.statusBarStyle;
    }
    return [super preferredStatusBarStyle];
}

- (void)configCollectionViews {
    // Create layout if not exists
    if (!_layout) {
        _layout = [[UICollectionViewFlowLayout alloc] init];
    }
    
    // Create all collection views
    _allCollectionView = [self createCollectionViewWithModels:self.allModels];
    _videoCollectionView = [self createCollectionViewWithModels:self.videoModels];
    _photoCollectionView = [self createCollectionViewWithModels:self.photoModels];
    
    // Set initial collection view
    _collectionView = _allCollectionView;
    
    // Hide video and photo collection views initially
    _videoCollectionView.hidden = YES;
    _photoCollectionView.hidden = YES;
    
    // Create auth footer tip view if needed
    if (!_authFooterTipView && _authorizationLimited) {
        _authFooterTipView = [[TZAuthLimitedFooterTipView alloc] initWithFrame:CGRectMake(0, 0, self.view.tz_width, 80)];
        UITapGestureRecognizer *footTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openSettingsApplication)];
        [_authFooterTipView addGestureRecognizer:footTap];
        [self.view addSubview:_authFooterTipView];
    }
    
    // Update content size and no data label for all collection views
    [self updateAllCollectionViews];
}

// Note: Each collection view must own its own layout to avoid cross-tab content size glitches
- (TZCollectionView *)createCollectionViewWithModels:(NSArray *)models {
    UICollectionViewFlowLayout *independentLayout = [[UICollectionViewFlowLayout alloc] init];
    TZCollectionView *collectionView = [[TZCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:independentLayout];
    if (@available(iOS 13.0, *)) {
        collectionView.backgroundColor = UIColor.tertiarySystemBackgroundColor;
    } else {
        collectionView.backgroundColor = [UIColor whiteColor];
    }
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.alwaysBounceHorizontal = NO;
    collectionView.contentInset = UIEdgeInsetsMake(itemMargin, itemMargin, itemMargin, itemMargin);
    [self.view addSubview:collectionView];
    [collectionView registerClass:[TZAssetCell class] forCellWithReuseIdentifier:@"TZAssetCell"];
    [collectionView registerClass:[TZAssetCameraCell class] forCellWithReuseIdentifier:@"TZAssetCameraCell"];
    [collectionView registerClass:[TZAssetAddMoreCell class] forCellWithReuseIdentifier:@"TZAssetAddMoreCell"];
    return collectionView;
}

- (void)updateAllCollectionViews {
    // Update content size for all collection views based on actual grid item size and margins
    CGFloat itemMargin = 2;
    // 修复小数点问题：先计算总可用宽度，然后向下取整确保能放下正确的列数
    CGFloat totalAvailableWidth = self.view.tz_width - (self.columnNumber + 1) * itemMargin;
    CGFloat itemWH = floor(totalAvailableWidth / self.columnNumber);

    NSInteger allRows = ([self getAllCellCount] + self.columnNumber - 1) / self.columnNumber;
    NSInteger videoRows = ([self getVideoCellCount] + self.columnNumber - 1) / self.columnNumber;
    NSInteger photoRows = ([self getPhotoCellCount] + self.columnNumber - 1) / self.columnNumber;

    CGFloat allHeight = allRows > 0 ? (allRows * itemWH + (allRows + 1) * itemMargin) : 0;
    CGFloat videoHeight = videoRows > 0 ? (videoRows * itemWH + (videoRows + 1) * itemMargin) : 0;
    CGFloat photoHeight = photoRows > 0 ? (photoRows * itemWH + (photoRows + 1) * itemMargin) : 0;

    _allCollectionView.contentSize = CGSizeMake(self.view.tz_width, allHeight);
    _videoCollectionView.contentSize = CGSizeMake(self.view.tz_width, videoHeight);
    _photoCollectionView.contentSize = CGSizeMake(self.view.tz_width, photoHeight);
    
    // Handle no data label for current collection view
    if (_noDataLabel) {
        [_noDataLabel removeFromSuperview];
        _noDataLabel = nil;
    }
    
    // Add no data label to current collection view if needed
    NSArray *currentModels = [self getModelsForCollectionView:_collectionView];
    if (currentModels.count == 0) {
        [_collectionView addSubview:self.noDataLabel];
    }
}

- (UILabel *)noDataLabel {
    if (!_noDataLabel) {
        _noDataLabel = [[UILabel alloc] initWithFrame:_collectionView.bounds];
        _noDataLabel.textAlignment = NSTextAlignmentCenter;
        _noDataLabel.text = [NSBundle tz_localizedStringForKey:@"No Photos or Videos"];
        CGFloat rgb = 153 / 256.0;
        _noDataLabel.textColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
        _noDataLabel.font = [UIFont boldSystemFontOfSize:20];
    }
    _noDataLabel.frame = _collectionView.bounds;
    return _noDataLabel;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Determine the size of the thumbnails to request from the PHCachingImageManager
    CGFloat scale = 2.0;
    if ([UIScreen mainScreen].bounds.size.width > 600) {
        scale = 1.0;
    }
    CGSize cellSize = ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
    
    if (!_models) {
        [self fetchAssetModels];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.isFirstAppear = NO;
    // [self updateCachedAssets];
}

- (void)configBottomToolBar {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (!tzImagePickerVc.showSelectBtn) return;
    
    // 创建新的选中照片容器
    [self configSelectedPhotosContainer];
}

- (void)configSelectedPhotosContainer {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    // 创建选中照片容器
    _selectedPhotosContainer = [[UIView alloc] init];
    _selectedPhotosContainer.backgroundColor = [UIColor whiteColor];
    _selectedPhotosContainer.hidden = YES; // 初始隐藏
    _selectedPhotosContainer.alpha = 0; // 初始透明
    [self.view addSubview:_selectedPhotosContainer];
    
    // 创建CollectionView布局
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(60, 60);
    layout.minimumInteritemSpacing = 10;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(12, 15, 0, 15);
    
    // 创建CollectionView
    _selectedPhotosCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _selectedPhotosCollectionView.backgroundColor = [UIColor clearColor];
    _selectedPhotosCollectionView.showsHorizontalScrollIndicator = NO;
    _selectedPhotosCollectionView.dataSource = self;
    _selectedPhotosCollectionView.delegate = self;
    [_selectedPhotosCollectionView registerClass:[TZSelectedPhotoCell class] forCellWithReuseIdentifier:@"TZSelectedPhotoCell"];
    [_selectedPhotosContainer addSubview:_selectedPhotosCollectionView];
    
    // 创建Next按钮
    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _nextButton.backgroundColor = [UIColor colorWithRed:112/255.0 green:62/255.0 blue:255/255.0 alpha:1.0]; // #703EFF
    _nextButton.layer.cornerRadius = 22;
    _nextButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [_nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_nextButton addTarget:self action:@selector(nextButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_selectedPhotosContainer addSubview:_nextButton];
    
    // 更新Next按钮文字
    [self updateNextButtonTitle];
}


#pragma mark - TZSelectedPhotoCellDelegate

- (void)selectedPhotoCellDidTapDelete:(TZSelectedPhotoCell *)cell {
    NSIndexPath *indexPath = [_selectedPhotosCollectionView indexPathForCell:cell];
    if (indexPath) {
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        
        // 添加边界检查，防止数组越界崩溃
        if (indexPath.item < tzImagePickerVc.selectedModels.count) {
            TZAssetModel *assetModel = tzImagePickerVc.selectedModels[indexPath.item];
            
            // 从选中列表中移除
            [tzImagePickerVc.selectedModels removeObject:assetModel];
            [tzImagePickerVc.selectedAssetIds removeObject:assetModel.asset.localIdentifier];
            
            // 更新相册中对应照片的选中状态
            [self setAsset:assetModel.asset isSelect:NO];
            
            // 更新UI
            [self refreshBottomToolBarStatus];
            [self refreshSelectedPhotosContainer];
        }
    }
}

#pragma mark - Helper Methods

- (void)updateNextButtonTitle {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    NSString *title = [NSString stringWithFormat:@"Next(%zd)", tzImagePickerVc.selectedModels.count];
    [_nextButton setTitle:title forState:UIControlStateNormal];
}

- (void)refreshSelectedPhotosContainer {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    BOOL hasSelectedPhotos = tzImagePickerVc.selectedModels.count > 0;
    
    if (hasSelectedPhotos) {
        // 显示选中照片容器 - 从底部上滑动画
        if (_selectedPhotosContainer.hidden) {
            _selectedPhotosContainer.hidden = NO;
            _selectedPhotosContainer.alpha = 0;
            
            // 设置初始位置（在屏幕底部下方）
            CGFloat containerHeight = 139; // 修改为139px
            _selectedPhotosContainer.frame = CGRectMake(0, self.view.tz_height, self.view.tz_width, containerHeight);
            
            // 执行从底部上滑动画
            [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self->_selectedPhotosContainer.alpha = 1;
                self->_selectedPhotosContainer.frame = CGRectMake(0, self.view.tz_height - containerHeight, self.view.tz_width, containerHeight);
                
                // 调整collection view的frame和contentInset，避免遮挡最后一排
                [self adjustCollectionViewsForSelectedPhotosContainer:YES];
            } completion:nil];
        }
        
        // 无论是否刚显示，都需要更新内容
        [_selectedPhotosCollectionView reloadData];
        [self updateNextButtonTitle];
    } else {
        // 隐藏选中照片容器 - 下滑到底部动画
        if (!_selectedPhotosContainer.hidden) {
            [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self->_selectedPhotosContainer.alpha = 0;
                self->_selectedPhotosContainer.frame = CGRectMake(0, self.view.tz_height, self.view.tz_width, self->_selectedPhotosContainer.tz_height);
                
                // 恢复collection view的原始frame和contentInset
                [self adjustCollectionViewsForSelectedPhotosContainer:NO];
            } completion:^(BOOL finished) {
                self->_selectedPhotosContainer.hidden = YES;
            }];
        }
    }
}

- (void)adjustCollectionViewsForSelectedPhotosContainer:(BOOL)isShowing {
    CGFloat selectedPhotosHeight = 139 + [TZCommonTools tz_safeAreaInsets].bottom;
    
    if (isShowing) {
        // 当显示选中照片弹窗时，调整collection view的frame和contentInset
        CGRect currentFrame = _allCollectionView.frame;
        currentFrame.size.height -= selectedPhotosHeight;
        
        _allCollectionView.frame = currentFrame;
        _videoCollectionView.frame = currentFrame;
        _photoCollectionView.frame = currentFrame;
        
        // 添加底部contentInset，确保最后一行不被遮挡
        UIEdgeInsets currentInset = _allCollectionView.contentInset;
        currentInset.bottom += selectedPhotosHeight;
        _allCollectionView.contentInset = currentInset;
        _videoCollectionView.contentInset = currentInset;
        _photoCollectionView.contentInset = currentInset;
        
        // 调整scrollIndicatorInsets
        _allCollectionView.scrollIndicatorInsets = currentInset;
        _videoCollectionView.scrollIndicatorInsets = currentInset;
        _photoCollectionView.scrollIndicatorInsets = currentInset;
    } else {
        // 当隐藏选中照片弹窗时，恢复collection view的原始frame和contentInset
        [self viewDidLayoutSubviews];
        
        // 恢复原始的contentInset
        CGFloat itemMargin = 2;
        UIEdgeInsets originalInset = UIEdgeInsetsMake(itemMargin, itemMargin, itemMargin, itemMargin);
        _allCollectionView.contentInset = originalInset;
        _videoCollectionView.contentInset = originalInset;
        _photoCollectionView.contentInset = originalInset;
        
        // 恢复scrollIndicatorInsets
        _allCollectionView.scrollIndicatorInsets = originalInset;
        _videoCollectionView.scrollIndicatorInsets = originalInset;
        _photoCollectionView.scrollIndicatorInsets = originalInset;
    }
}

- (void)nextButtonClick {
    [self doneButtonClick];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    CGFloat top = 0;
    CGFloat collectionViewHeight = 0;
    CGFloat naviBarHeight = self.navigationController.navigationBar.tz_height;
    CGFloat footerTipViewH = _authorizationLimited ? 80 : 0;
    CGFloat tabSwitcherHeight = 44; // Height of tab switcher (adjusted for new styling)
    BOOL isStatusBarHidden = [UIApplication sharedApplication].isStatusBarHidden;
    BOOL isFullScreen = self.view.tz_height == [UIScreen mainScreen].bounds.size.height;
    CGFloat toolBarHeight = 50 + [TZCommonTools tz_safeAreaInsets].bottom;
    CGFloat selectedPhotosHeight = 139 + [TZCommonTools tz_safeAreaInsets].bottom; // 修改为139px，包含底部安全距离
    if (self.navigationController.navigationBar.isTranslucent) {
        top = naviBarHeight;
        if (!isStatusBarHidden && isFullScreen) top += [TZCommonTools tz_statusBarHeight];
        // Always extend to bottom; do not subtract toolBarHeight so the collection view covers under the toolbar
        collectionViewHeight = self.view.tz_height - top - tabSwitcherHeight;
    } else {
        // Always extend to bottom; do not subtract toolBarHeight so the collection view covers under the toolbar
        collectionViewHeight = self.view.tz_height - tabSwitcherHeight;
    }
    collectionViewHeight -= footerTipViewH;

    // Layout tab switcher
    CGFloat tabSwitcherTop = top;
    self.tabSwitcherView.frame = CGRectMake(0, tabSwitcherTop, self.view.tz_width, tabSwitcherHeight);
    
    // Layout tab buttons
    CGFloat buttonWidth = self.view.tz_width / self.tabButtons.count;
    for (NSInteger i = 0; i < self.tabButtons.count; i++) {
        UIButton *button = self.tabButtons[i];
        button.frame = CGRectMake(i * buttonWidth, 0, buttonWidth, tabSwitcherHeight);
    }
    
    // Update indicator position after buttons are laid out
    [self updateTabIndicatorPosition];
    
    // Adjust collection views position
    CGFloat collectionViewTop = tabSwitcherTop + tabSwitcherHeight;
    CGRect collectionViewFrame = CGRectMake(0, collectionViewTop, self.view.tz_width, collectionViewHeight);
    
    // Layout all collection views
    _allCollectionView.frame = collectionViewFrame;
    _videoCollectionView.frame = collectionViewFrame;
    _photoCollectionView.frame = collectionViewFrame;
    
    _noDataLabel.frame = _collectionView.bounds;
    // 修复小数点问题：先计算总可用宽度，然后向下取整确保能放下正确的列数
    CGFloat totalAvailableWidth = self.view.tz_width - (self.columnNumber + 1) * itemMargin;
    CGFloat itemWH = floor(totalAvailableWidth / self.columnNumber);
    
    // Update layout for all collection views to ensure consistent column count
    UICollectionViewFlowLayout *allLayout = (UICollectionViewFlowLayout *)self.allCollectionView.collectionViewLayout;
    allLayout.itemSize = CGSizeMake(itemWH, itemWH);
    allLayout.minimumInteritemSpacing = itemMargin;
    allLayout.minimumLineSpacing = itemMargin;
    [self.allCollectionView setCollectionViewLayout:allLayout];
    
    UICollectionViewFlowLayout *videoLayout = (UICollectionViewFlowLayout *)self.videoCollectionView.collectionViewLayout;
    videoLayout.itemSize = CGSizeMake(itemWH, itemWH);
    videoLayout.minimumInteritemSpacing = itemMargin;
    videoLayout.minimumLineSpacing = itemMargin;
    [self.videoCollectionView setCollectionViewLayout:videoLayout];
    
    UICollectionViewFlowLayout *photoLayout = (UICollectionViewFlowLayout *)self.photoCollectionView.collectionViewLayout;
    photoLayout.itemSize = CGSizeMake(itemWH, itemWH);
    photoLayout.minimumInteritemSpacing = itemMargin;
    photoLayout.minimumLineSpacing = itemMargin;
    [self.photoCollectionView setCollectionViewLayout:photoLayout];
    
    // Also update the current collection view layout
    UICollectionViewFlowLayout *currentLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    currentLayout.itemSize = CGSizeMake(itemWH, itemWH);
    currentLayout.minimumInteritemSpacing = itemMargin;
    currentLayout.minimumLineSpacing = itemMargin;
    [_collectionView setCollectionViewLayout:currentLayout];
    if (_offsetItemCount > 0) {
        CGFloat offsetY = _offsetItemCount * (_layout.itemSize.height + _layout.minimumLineSpacing);
        [_collectionView setContentOffset:CGPointMake(0, offsetY)];
    }
    
    CGFloat toolBarTop = 0;
    if (!self.navigationController.navigationBar.isHidden) {
        toolBarTop = self.view.tz_height - toolBarHeight;
    } else {
        CGFloat navigationHeight = naviBarHeight + [TZCommonTools tz_statusBarHeight];
        toolBarTop = self.view.tz_height - toolBarHeight - navigationHeight;
    }
    // Layout selected photos container
    CGFloat selectedPhotosTop = self.view.tz_height - selectedPhotosHeight;
    _selectedPhotosContainer.frame = CGRectMake(0, selectedPhotosTop, self.view.tz_width, selectedPhotosHeight);
    
    // Layout selected photos collection view
    _selectedPhotosCollectionView.frame = CGRectMake(0, 0, self.view.tz_width, 84); // 12 + 60 + 12 = 84 (调整高度以适应139px总高度)
    
    // Layout next button
    _nextButton.frame = CGRectMake((self.view.tz_width - 200) / 2, 98, 200, 44); // 84 + 14 = 98
    
    if (_authFooterTipView) {
        CGFloat footerTipViewY = self.view.tz_height - footerTipViewH;
        _authFooterTipView.frame = CGRectMake(0, footerTipViewY, self.view.tz_width, footerTipViewH);
    }
    
    [TZImageManager manager].columnNumber = [TZImageManager manager].columnNumber;
    [TZImageManager manager].photoWidth = tzImagePickerVc.photoWidth;
    [self.collectionView reloadData];
    
    if (tzImagePickerVc.photoPickerPageDidLayoutSubviewsBlock) {
        tzImagePickerVc.photoPickerPageDidLayoutSubviewsBlock(_collectionView, nil, nil, nil, nil, nil, nil, nil, nil);
    }
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    UICollectionViewFlowLayout *currentLayout = (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    _offsetItemCount = _collectionView.contentOffset.y / (currentLayout.itemSize.height + currentLayout.minimumLineSpacing);
}

#pragma mark - Click Event
- (void)navLeftBarButtonClick{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)titleTapped {
    // Toggle album picker visibility
    if (self.isAlbumPickerVisible) {
        [self dismissAlbumPicker];
    } else {
        [self showAlbumPickerWithSlideDownAnimation];
    }
    
    // Animate arrow rotation after state change
    [self animateArrowRotation];
}

- (void)animateArrowRotation {
    if (!self.titleArrowImageView) return;
    
    // Determine target rotation based on current state
    // When album picker is visible, arrow should point up (180 degrees)
    // When album picker is hidden, arrow should point down (0 degrees)
    CGFloat targetRotation = self.isAlbumPickerVisible ? M_PI : 0;
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.titleArrowImageView.transform = CGAffineTransformMakeRotation(targetRotation);
    } completion:nil];
}

- (void)showAlbumPickerWithSlideDownAnimation {
    // Create a custom album picker view that slides down from navigation bar
    UIView *albumPickerView = [[UIView alloc] init];
    albumPickerView.backgroundColor = [UIColor whiteColor];
    albumPickerView.layer.shadowColor = [UIColor blackColor].CGColor;
    albumPickerView.layer.shadowOffset = CGSizeMake(0, 2);
    albumPickerView.layer.shadowOpacity = 0.3;
    albumPickerView.layer.shadowRadius = 8;
    
    // Calculate the starting position (just below navigation bar)
    // Use the navigation bar's bottom position for accurate alignment
    CGFloat navBarBottom = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat startY = navBarBottom;
    
    // Set initial frame (hidden above screen)
    albumPickerView.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - startY);
    
    // Create table view for albums
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, albumPickerView.frame.size.width, albumPickerView.frame.size.height) style:UITableViewStylePlain];
    tableView.backgroundColor = [UIColor whiteColor];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 82; // 70px照片高度 + 12px间距
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // 移除默认分隔线
    tableView.tableFooterView = [[UIView alloc] init];
    // 去掉header上方的空隙
    if (@available(iOS 15.0, *)) {
        tableView.sectionHeaderTopPadding = 0;
    }
    [tableView registerClass:[TZAlbumCell class] forCellReuseIdentifier:@"TZAlbumCell"];
    
    [albumPickerView addSubview:tableView];
    [self.view addSubview:albumPickerView];
    
    // Add tap gesture to dismiss
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissAlbumPicker)];
//    tapGesture.cancelsTouchesInView = NO;
//    [self.view addGestureRecognizer:tapGesture];
    
    // Store reference for dismissal
    self.albumPickerView = albumPickerView;
    self.albumPickerTableView = tableView;
//    self.dismissGesture = tapGesture;
    
    // Load album data for the slide-down picker
    [self loadAlbumDataForSlideDownPicker];
    
    // Set state before animation
    self.isAlbumPickerVisible = YES;
    
    // Animate slide down
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        albumPickerView.frame = CGRectMake(0, startY, self.view.frame.size.width, self.view.frame.size.height - startY);
    } completion:^(BOOL finished) {
        // Animation completed
    }];
}

- (void)dismissAlbumPicker {
    if (self.albumPickerView) {
        // Set state before animation
        self.isAlbumPickerVisible = NO;
        
        // Remove tap gesture
        if (self.dismissGesture) {
            [self.view removeGestureRecognizer:self.dismissGesture];
            self.dismissGesture = nil;
        }
        
        // Animate slide up
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.albumPickerView.frame = CGRectMake(0, -self.view.frame.size.height, self.view.frame.size.width, self.albumPickerView.frame.size.height);
        } completion:^(BOOL finished) {
            [self.albumPickerView removeFromSuperview];
            self.albumPickerView = nil;
            self.albumPickerTableView = nil;
            
            // Switch to selected album if one was selected
            if (self.selectedAlbumModel) {
                [self switchToAlbum:self.selectedAlbumModel];
                self.selectedAlbumModel = nil;
            }
        }];
    }
}

- (void)switchToAlbum:(TZAlbumModel *)albumModel {
    // Update the current model
    self.model = albumModel;
    
    // Update the title
    [self updateTitleWithAlbumName:albumModel.name];
    
    // Clear current models
    _models = [NSMutableArray array];
    
    // Set flag to scroll to bottom after loading
    _shouldScrollToBottom = YES;
    
    // Show progress HUD
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    [tzImagePickerVc showProgressHUD];
    
    // Fetch new assets for the selected album
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[TZImageManager manager] getAssetsFromFetchResult:albumModel.result completion:^(NSArray<TZAssetModel *> *models) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Categorize new models
                [self categorizeModels:models];
                
                // Switch to current tab
                [self switchToTab:self.currentTabIndex];
                
                [tzImagePickerVc hideProgressHUD];
                
                // Send notification to update album picker
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TZ_ALBUM_SWITCHED_NOTIFICATION" object:nil];
            });
        }];
    });
}

- (void)updateTitleWithAlbumName:(NSString *)albumName {
    // Create custom title view container with title and arrow
    UIView *titleContainerView = [[UIView alloc] init];
    
    // Create title label
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = albumName;
    titleLabel.textColor = [UIColor colorWithRed:0x1A/255.0 green:0x1A/255.0 blue:0x1A/255.0 alpha:1.0]; // #1A1A1A
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:16]; // 16px, font-weight: 700
    [titleLabel sizeToFit];
    
    // Create arrow icon
    UIImageView *arrowImageView = [[UIImageView alloc] init];
    // Load image directly from bundle without @2x suffix
    NSBundle *imageBundle = [NSBundle tz_imagePickerBundle];
    NSString *imagePath = [imageBundle pathForResource:@"arrow_down" ofType:@"png"];
    UIImage *arrowImage = [UIImage imageWithContentsOfFile:imagePath];
    
    // Debug: Check if image was loaded successfully
    if (arrowImage) {
        arrowImageView.image = arrowImage;
        NSLog(@"TZImagePicker: Successfully loaded arrow_down image from path: %@", imagePath);
    } else {
        // Fallback: try to load with @2x suffix as backup
        NSString *imagePath2x = [imageBundle pathForResource:@"arrow_down@2x" ofType:@"png"];
        UIImage *arrowImage2x = [UIImage imageWithContentsOfFile:imagePath2x];
        if (arrowImage2x) {
            arrowImageView.image = arrowImage2x;
            NSLog(@"TZImagePicker: Successfully loaded arrow_down@2x image from path: %@", imagePath2x);
        } else {
            // Last resort: create a simple arrow using system image or draw one
            NSLog(@"TZImagePicker: Could not load arrow_down image from bundle. Bundle path: %@, Image path: %@, @2x path: %@", imageBundle.bundlePath, imagePath, imagePath2x);
            // Create a simple arrow using system symbols if available
            if (@available(iOS 13.0, *)) {
                arrowImageView.image = [UIImage systemImageNamed:@"chevron.down"];
                NSLog(@"TZImagePicker: Using system chevron.down as fallback");
            }
        }
    }
    
    arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    arrowImageView.frame = CGRectMake(0, 0, 14, 14);
    
    // Calculate container size
    CGFloat titleWidth = titleLabel.frame.size.width;
    CGFloat arrowWidth = 14;
    CGFloat spacing = 2; // 2px spacing between title and arrow
    CGFloat containerWidth = titleWidth + spacing + arrowWidth;
    CGFloat containerHeight = MAX(titleLabel.frame.size.height, 14);
    
    // Set container frame
    titleContainerView.frame = CGRectMake(0, 0, containerWidth, containerHeight);
    
    // Position title label (centered vertically)
    titleLabel.frame = CGRectMake(0, (containerHeight - titleLabel.frame.size.height) / 2, titleWidth, titleLabel.frame.size.height);
    
    // Position arrow (2px to the right of title)
    arrowImageView.frame = CGRectMake(titleWidth + spacing, (containerHeight - 14) / 2, 14, 14);
    
    // Add subviews to container
    [titleContainerView addSubview:titleLabel];
    [titleContainerView addSubview:arrowImageView];
    
    // Store arrow reference for rotation animation
    self.titleArrowImageView = arrowImageView;
    
    // Add tap gesture to entire container
    UITapGestureRecognizer *titleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleTapped)];
    titleContainerView.userInteractionEnabled = YES;
    [titleContainerView addGestureRecognizer:titleTapGesture];
    
    self.navigationItem.titleView = titleContainerView;
}

- (void)loadAlbumDataForSlideDownPicker {
    if (![[TZImageManager manager] authorizationStatusAuthorized]) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[TZImageManager manager] getAllAlbumsWithFetchAssets:YES completion:^(NSArray<TZAlbumModel *> *models) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.albumArr = [NSMutableArray arrayWithArray:models];
                
                // Set selected models for each album
                TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
                for (TZAlbumModel *albumModel in self.albumArr) {
                    albumModel.selectedModels = tzImagePickerVc.selectedModels;
                }
                
                [self.albumPickerTableView reloadData];
            });
        }];
    });
}

- (void)doneButtonClick {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    // 1.6.8 判断是否满足最小必选张数的限制
    if (tzImagePickerVc.minImagesCount && tzImagePickerVc.selectedModels.count < tzImagePickerVc.minImagesCount) {
        NSString *title = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Select a minimum of %zd photos"], tzImagePickerVc.minImagesCount];
        [tzImagePickerVc showAlertWithTitle:title];
        return;
    }
    
    // 创建selectedModels的副本，防止在异步操作过程中数组被修改
    NSArray *selectedModelsCopy = [NSArray arrayWithArray:tzImagePickerVc.selectedModels];
    
    [tzImagePickerVc showProgressHUD];
    self.isFetchingMedia = YES;
    NSMutableArray *assets = [NSMutableArray array];
    NSMutableArray *photos;
    NSMutableArray *infoArr;
    if (tzImagePickerVc.onlyReturnAsset) { // not fetch image
        for (NSInteger i = 0; i < selectedModelsCopy.count; i++) {
            TZAssetModel *model = selectedModelsCopy[i];
            [assets addObject:model.asset];
        }
    } else { // fetch image
        photos = [NSMutableArray array];
        infoArr = [NSMutableArray array];
        for (NSInteger i = 0; i < selectedModelsCopy.count; i++) { [photos addObject:@1];[assets addObject:@1];[infoArr addObject:@1]; }
        
        __block BOOL havenotShowAlert = YES;
        [TZImageManager manager].shouldFixOrientation = YES;
        __block UIAlertController *alertView;
        for (NSInteger i = 0; i < selectedModelsCopy.count; i++) {
            TZAssetModel *model = selectedModelsCopy[i];
            TZImageRequestOperation *operation = [[TZImageRequestOperation alloc] initWithAsset:model.asset completion:^(UIImage * _Nonnull photo, NSDictionary * _Nonnull info, BOOL isDegraded) {
                if (isDegraded) return;
                if (photo) {
                    if (![TZImagePickerConfig sharedInstance].notScaleImage) {
                        photo = [[TZImageManager manager] scaleImage:photo toSize:CGSizeMake(tzImagePickerVc.photoWidth, (int)(tzImagePickerVc.photoWidth * photo.size.height / photo.size.width))];
                    }
                    // 添加边界检查，防止数组越界
                    if (i < photos.count) {
                        [photos replaceObjectAtIndex:i withObject:photo];
                    }
                }
                if (info && i < infoArr.count) {
                    [infoArr replaceObjectAtIndex:i withObject:info];
                }
                if (i < assets.count) {
                    [assets replaceObjectAtIndex:i withObject:model.asset];
                }
                
                for (id item in photos) { if ([item isKindOfClass:[NSNumber class]]) return; }
                
                if (havenotShowAlert && alertView) {
                    [alertView dismissViewControllerAnimated:YES completion:^{
                        alertView = nil;
                        [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
                    }];
                } else {
                    [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
                }
            } progressHandler:^(double progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
                // 如果图片正在从iCloud同步中,提醒用户
                if (progress < 1 && havenotShowAlert && !alertView) {
                    alertView = [tzImagePickerVc showAlertWithTitle:[NSBundle tz_localizedStringForKey:@"Synchronizing photos from iCloud"]];
                    havenotShowAlert = NO;
                    return;
                }
                if (progress >= 1) {
                    havenotShowAlert = YES;
                }
            }];
            [self.operationQueue addOperation:operation];
        }
    }
    if (tzImagePickerVc.selectedModels.count <= 0 || tzImagePickerVc.onlyReturnAsset) {
        [self didGetAllPhotos:photos assets:assets infoArr:infoArr];
    }
}

- (void)didGetAllPhotos:(NSArray *)photos assets:(NSArray *)assets infoArr:(NSArray *)infoArr {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    [tzImagePickerVc hideProgressHUD];
    self.isFetchingMedia = NO;

    if (tzImagePickerVc.autoDismiss) {
        [self.navigationController dismissViewControllerAnimated:YES completion:^{
            [self callDelegateMethodWithPhotos:photos assets:assets infoArr:infoArr];
        }];
    } else {
        [self callDelegateMethodWithPhotos:photos assets:assets infoArr:infoArr];
    }
}

- (void)callDelegateMethodWithPhotos:(NSArray *)photos assets:(NSArray *)assets infoArr:(NSArray *)infoArr {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    // 移除单独的视频处理逻辑，让视频和照片使用相同的处理方式
    // 这样与点击图片的逻辑保持一致
    
    if ([tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:)]) {
        [tzImagePickerVc.pickerDelegate imagePickerController:tzImagePickerVc didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto];
    }
    if ([tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:infos:)]) {
        [tzImagePickerVc.pickerDelegate imagePickerController:tzImagePickerVc didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto infos:infoArr];
    }
    if (tzImagePickerVc.didFinishPickingPhotosHandle) {
        tzImagePickerVc.didFinishPickingPhotosHandle(photos,assets,_isSelectOriginalPhoto);
    }
    if (tzImagePickerVc.didFinishPickingPhotosWithInfosHandle) {
        tzImagePickerVc.didFinishPickingPhotosWithInfosHandle(photos,assets,_isSelectOriginalPhoto,infoArr);
    }
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == _allCollectionView) {
        return [self getAllCellCount];
    } else if (collectionView == _videoCollectionView) {
        return [self getVideoCellCount];
    } else if (collectionView == _photoCollectionView) {
        return [self getPhotoCellCount];
    } else if (collectionView == _selectedPhotosCollectionView) {
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        return tzImagePickerVc.selectedModels.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    // Handle selected photos collection view
    if (collectionView == _selectedPhotosCollectionView) {
        TZSelectedPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZSelectedPhotoCell" forIndexPath:indexPath];
        
        // 添加边界检查，防止数组越界崩溃
        if (indexPath.item < tzImagePickerVc.selectedModels.count) {
            TZAssetModel *assetModel = tzImagePickerVc.selectedModels[indexPath.item];
            cell.assetModel = assetModel;
        } else {
            cell.assetModel = nil;
        }
        cell.delegate = self;
        return cell;
    }
    
    // Get the appropriate models array based on collection view
    NSArray *models = [self getModelsForCollectionView:collectionView];
    NSInteger cellCount = [self getCellCountForCollectionView:collectionView];
    
    // the cell lead to add more photo / 去添加更多照片的cell
    if (indexPath.item == [self getAddMorePhotoCellIndexForCollectionView:collectionView]) {
        TZAssetAddMoreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetAddMoreCell" forIndexPath:indexPath];
        cell.imageView.image = tzImagePickerVc.addMorePhotoImage;
        cell.tipLabel.text = [NSBundle tz_localizedStringForKey:@"Add more accessible photos"];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        return cell;
    }
    // the cell lead to take a picture / 去拍照的cell
    if (indexPath.item == [self getTakePhotoCellIndexForCollectionView:collectionView]) {
        TZAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCameraCell" forIndexPath:indexPath];
        cell.imageView.image = tzImagePickerVc.takePictureImage;
        if ([tzImagePickerVc.takePictureImageName isEqualToString:@"takePicture80"]) {
            cell.imageView.contentMode = UIViewContentModeCenter;
            CGFloat rgb = 223 / 255.0;
            cell.imageView.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
        } else {
            cell.imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        }
        return cell;
    }
    // the cell dipaly photo or video / 展示照片或视频的cell
    TZAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCell" forIndexPath:indexPath];
    cell.allowPickingMultipleVideo = tzImagePickerVc.allowPickingMultipleVideo;
    cell.photoDefImage = tzImagePickerVc.photoDefImage;
    cell.photoSelImage = tzImagePickerVc.photoSelImage;
    cell.assetCellDidSetModelBlock = tzImagePickerVc.assetCellDidSetModelBlock;
    cell.assetCellDidLayoutSubviewsBlock = tzImagePickerVc.assetCellDidLayoutSubviewsBlock;
    TZAssetModel *model;
    
    // 添加边界检查，防止数组越界崩溃
    NSInteger modelIndex = -1;
    if (tzImagePickerVc.sortAscendingByModificationDate) {
        modelIndex = indexPath.item;
    } else {
        NSInteger diff = cellCount - models.count;
        modelIndex = indexPath.item - diff;
    }
    
    // 确保索引在有效范围内
    if (modelIndex >= 0 && modelIndex < models.count) {
        model = models[modelIndex];
    } else {
        // 如果索引无效，创建一个空的模型或返回默认cell
        NSLog(@"TZPhotoPickerController: Invalid model index %ld for models count %lu", (long)modelIndex, (unsigned long)models.count);
        // 返回一个空的cell或处理错误情况
        TZAssetCell *errorCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCell" forIndexPath:indexPath];
        errorCell.model = nil;
        return errorCell;
    }
    cell.allowPickingGif = tzImagePickerVc.allowPickingGif;
    cell.model = model;
    if (model.isSelected && tzImagePickerVc.showSelectedIndex) {
        cell.index = [tzImagePickerVc.selectedAssetIds indexOfObject:model.asset.localIdentifier] + 1;
    }
    cell.showSelectBtn = tzImagePickerVc.showSelectBtn;
    cell.allowPreview = tzImagePickerVc.allowPreview;
    
    BOOL notSelectable = [TZCommonTools isAssetNotSelectable:model tzImagePickerVc:tzImagePickerVc];
    if (notSelectable && tzImagePickerVc.showPhotoCannotSelectLayer && !model.isSelected) {
        cell.cannotSelectLayerButton.backgroundColor = tzImagePickerVc.cannotSelectLayerColor;
        cell.cannotSelectLayerButton.hidden = NO;
    } else {
        cell.cannotSelectLayerButton.hidden = YES;
    }

    // 移除视频遮罩层逻辑，允许视频被选中
    // When allowPickingImage is false, display images with 70% white overlay and disable selection
    if (!tzImagePickerVc.allowPickingImage && model.type != TZAssetModelMediaTypeVideo) {
        cell.cannotSelectLayerButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.7];
        cell.cannotSelectLayerButton.hidden = NO;
        cell.showSelectBtn = NO; // hide select button for image
    }
    
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        __strong typeof(weakCell) strongCell = weakCell;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)strongSelf.navigationController;
        // 1. cancel select / 取消选择
        if (isSelected) {
            strongCell.selectPhotoButton.selected = NO;
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:tzImagePickerVc.selectedModels];
            for (TZAssetModel *model_item in selectedModels) {
                if ([model.asset.localIdentifier isEqualToString:model_item.asset.localIdentifier]) {
                    [tzImagePickerVc removeSelectedModel:model_item];
                    [strongSelf setAsset:model_item.asset isSelect:NO];
                    break;
                }
            }
            [strongSelf refreshBottomToolBarStatus];
            if (tzImagePickerVc.showSelectedIndex || tzImagePickerVc.showPhotoCannotSelectLayer) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TZ_PHOTO_PICKER_RELOAD_NOTIFICATION" object:strongSelf.navigationController];
            }
            [UIView showOscillatoryAnimationWithLayer:strongCell.selectPhotoButton.layer type:TZOscillatoryAnimationToSmaller];
            if (strongCell.model.iCloudFailed) {
                NSString *title = [NSBundle tz_localizedStringForKey:@"iCloud sync failed"];
                [tzImagePickerVc showAlertWithTitle:title];
            }
        } else {
            // Block selecting image when allowPickingImage is false (images are displayed but not selectable)
            if (!tzImagePickerVc.allowPickingImage && strongCell.model.type != TZAssetModelMediaTypeVideo) {
                return;
            }
            
            // 单次选择模式：如果启用了单次选择模式，先清除所有已选择的照片
            if (tzImagePickerVc.singleSelectionMode && tzImagePickerVc.selectedModels.count > 0) {
                // 清除所有已选择的照片
                NSArray *selectedModels = [NSArray arrayWithArray:tzImagePickerVc.selectedModels];
                for (TZAssetModel *selectedModel in selectedModels) {
                    selectedModel.isSelected = NO;
                    [tzImagePickerVc removeSelectedModel:selectedModel];
                    [strongSelf setAsset:selectedModel.asset isSelect:NO];
                }
                // 刷新UI
                if (tzImagePickerVc.showSelectedIndex || tzImagePickerVc.showPhotoCannotSelectLayer) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TZ_PHOTO_PICKER_RELOAD_NOTIFICATION" object:strongSelf.navigationController];
                }
            }
            
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
                if ([[TZImageManager manager] isAssetCannotBeSelected:model.asset]) {
                    return;
                }
                if (!tzImagePickerVc.allowPreview) {
                    BOOL shouldDone = tzImagePickerVc.maxImagesCount == 1;
                    if (!tzImagePickerVc.allowPickingMultipleVideo && (model.type == TZAssetModelMediaTypeVideo || model.type == TZAssetModelMediaTypePhotoGif)) {
                        shouldDone = YES;
                    }
                    if (shouldDone) {
//                        model.isSelected = YES;
//                        [tzImagePickerVc addSelectedModel:model];
//                        [strongSelf doneButtonClick];
//                        return;
                    }
                }
                
                // 处理视频和照片选择的特殊逻辑
                if (model.type == TZAssetModelMediaTypeVideo && !tzImagePickerVc.allowPickingMultipleVideo) {
                    // 选择视频时的特殊处理
                    [strongSelf handleVideoSelection:model tzImagePickerVc:tzImagePickerVc];
                } else if (model.type == TZAssetModelMediaTypePhoto || model.type == TZAssetModelMediaTypePhotoGif) {
                    // 检查是否已选择视频
                    BOOL hasSelectedVideo = NO;
                    for (TZAssetModel *selectedModel in tzImagePickerVc.selectedModels) {
                        if (selectedModel.asset.mediaType == PHAssetMediaTypeVideo) {
                            hasSelectedVideo = YES;
                            break;
                        }
                    }
                    
                    if (hasSelectedVideo && !tzImagePickerVc.allowPickingMultipleVideo) {
                        // 已选择视频时选择照片的特殊处理
                        [strongSelf handlePhotoSelectionWhenVideoSelected:model tzImagePickerVc:tzImagePickerVc];
                    } else {
                        // 正常选择逻辑
                        model.isSelected = YES;
                        [tzImagePickerVc addSelectedModel:model];
                        [strongSelf setAsset:model.asset isSelect:YES];
                    }
                } else {
                    // 其他类型的正常选择逻辑
                    model.isSelected = YES;
                    [tzImagePickerVc addSelectedModel:model];
                    [strongSelf setAsset:model.asset isSelect:YES];
                }
                
                strongCell.selectPhotoButton.selected = YES;
                if (tzImagePickerVc.showSelectedIndex || tzImagePickerVc.showPhotoCannotSelectLayer) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TZ_PHOTO_PICKER_RELOAD_NOTIFICATION" object:strongSelf.navigationController];
                }
                [strongSelf refreshBottomToolBarStatus];
                [UIView showOscillatoryAnimationWithLayer:strongCell.selectPhotoButton.layer type:TZOscillatoryAnimationToSmaller];
            } else {
                NSString *title = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Select a maximum of %zd photos"], tzImagePickerVc.maxImagesCount];
                [tzImagePickerVc showAlertWithTitle:title];
            }
        }
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // take a photo / 去拍照
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    // Get the appropriate models array based on collection view
    NSArray *models = [self getModelsForCollectionView:collectionView];
    
    if (indexPath.item == [self getAddMorePhotoCellIndexForCollectionView:collectionView]) {
        [self addMorePhoto]; return;
    }
    if (indexPath.item == [self getTakePhotoCellIndexForCollectionView:collectionView]) {
        [self takePhoto]; return;
    }
    
    // 添加边界检查，防止数组越界崩溃
    if (models.count == 0) {
        return;
    }
    
    // preview phote or video / 预览照片或视频
    NSInteger index = indexPath.item;
    NSInteger cellCount = [self getCellCountForCollectionView:collectionView];
    if (!tzImagePickerVc.sortAscendingByModificationDate) {
        index -= cellCount - models.count;
    }
    
    // 再次检查计算后的index是否在有效范围内
    if (index < 0 || index >= models.count) {
        return;
    }
    
    TZAssetModel *model = models[index];
    if (model.type == TZAssetModelMediaTypeVideo && !tzImagePickerVc.allowPickingMultipleVideo) {
        // 将视频添加到底部栏而不是跳转到播放器
        if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
            if ([[TZImageManager manager] isAssetCannotBeSelected:model.asset]) {
                return;
            }
            // 使用视频选择的特殊处理逻辑
            [self handleVideoSelection:model tzImagePickerVc:tzImagePickerVc];
            [self refreshBottomToolBarStatus];
            
            // 显示选中动画
            TZAssetCell *cell = (TZAssetCell *)[collectionView cellForItemAtIndexPath:indexPath];
            if (cell && cell.selectPhotoButton) {
                cell.selectPhotoButton.selected = YES;
                [UIView showOscillatoryAnimationWithLayer:cell.selectPhotoButton.layer type:TZOscillatoryAnimationToSmaller];
            }
        } else {
            NSString *title = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Select a maximum of %zd photos"], tzImagePickerVc.maxImagesCount];
            [tzImagePickerVc showAlertWithTitle:title];
        }
    } else if (model.type == TZAssetModelMediaTypePhotoGif && tzImagePickerVc.allowPickingGif && !tzImagePickerVc.allowPickingMultipleVideo) {
        if (tzImagePickerVc.selectedModels.count > 0) {
            TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
            [imagePickerVc showAlertWithTitle:[NSBundle tz_localizedStringForKey:@"Can not choose both photo and GIF"]];
        } else {
            TZGifPhotoPreviewController *gifPreviewVc = [[TZGifPhotoPreviewController alloc] init];
            gifPreviewVc.model = model;
            [self.navigationController pushViewController:gifPreviewVc animated:YES];
        }
    } else {
        TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
        photoPreviewVc.currentIndex = index;
        photoPreviewVc.models = [NSMutableArray arrayWithArray:models];
        [self pushPhotoPrevireViewController:photoPreviewVc];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // [self updateCachedAssets];
}

#pragma mark - Private Method

- (NSInteger)getVideoCellCount {
    NSInteger count = self.videoModels.count;
    if (_showTakePhotoBtn) {
        count += 1;
    }
    if (_authorizationLimited) {
        count += 1;
    }
    return count;
}

- (NSInteger)getAllCellCount {
    NSInteger count = self.allModels.count;
    if (_showTakePhotoBtn) {
        count += 1;
    }
    if (_authorizationLimited) {
        count += 1;
    }
    return count;
}

- (NSInteger)getPhotoCellCount {
    NSInteger count = self.photoModels.count;
    if (_showTakePhotoBtn) {
        count += 1;
    }
    if (_authorizationLimited) {
        count += 1;
    }
    return count;
}

- (NSArray *)getModelsForCollectionView:(UICollectionView *)collectionView {
    if (collectionView == _allCollectionView) {
        return self.allModels ?: @[];
    } else if (collectionView == _videoCollectionView) {
        return self.videoModels ?: @[];
    } else if (collectionView == _photoCollectionView) {
        return self.photoModels ?: @[];
    }
    return @[];
}

- (NSInteger)getCellCountForCollectionView:(UICollectionView *)collectionView {
    if (collectionView == _allCollectionView) {
        return [self getAllCellCount];
    } else if (collectionView == _videoCollectionView) {
        return [self getVideoCellCount];
    } else if (collectionView == _photoCollectionView) {
        return [self getPhotoCellCount];
    }
    return 0;
}

- (NSInteger)getAddMorePhotoCellIndexForCollectionView:(UICollectionView *)collectionView {
    NSInteger count = [self getCellCountForCollectionView:collectionView];
    if (_authorizationLimited) {
        return count - 1;
    }
    return -1;
}

- (NSInteger)getTakePhotoCellIndexForCollectionView:(UICollectionView *)collectionView {
    NSInteger count = [self getCellCountForCollectionView:collectionView];
    if (_showTakePhotoBtn) {
        if (_authorizationLimited) {
            return count - 2;
        } else {
            return count - 1;
        }
    }
    return -1;
}

- (NSInteger)getTakePhotoCellIndex {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (!_showTakePhotoBtn) {
        return -1;
    }
    if (tzImagePickerVc.sortAscendingByModificationDate) {
        return [self getAllCellCount] - 1;
    } else {
        return 0;
    }
}

- (NSInteger)getAddMorePhotoCellIndex {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (!_authorizationLimited) {
        return -1;
    }
    if (tzImagePickerVc.sortAscendingByModificationDate) {
        if (_showTakePhotoBtn) {
            return [self getAllCellCount] - 2;
        }
        return [self getAllCellCount] - 1;
    } else {
        return _showTakePhotoBtn ? 1 : 0;
    }
}

/// 拍照按钮点击事件
- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)) {
        
        // 无权限 做一个友好的提示
        NSString *appName = [TZCommonTools tz_getAppName];

        NSString *title = [NSBundle tz_localizedStringForKey:@"Can not use camera"];
        NSString *message = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Please allow %@ to access your camera in \"Settings -> Privacy -> Camera\""],appName];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:[NSBundle tz_localizedStringForKey:@"Cancel"] style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:cancelAct];
        UIAlertAction *settingAct = [UIAlertAction actionWithTitle:[NSBundle tz_localizedStringForKey:@"Setting"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }];
        [alertController addAction:settingAct];
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pushImagePickerController];
                });
            }
        }];
    } else {
        [self pushImagePickerController];
    }
}

- (void)openSettingsApplication {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
}

- (void)addMorePhoto {
    if (@available(iOS 14, *)) {
        [[PHPhotoLibrary sharedPhotoLibrary] presentLimitedLibraryPickerFromViewController:self];
    }
}

// 调用相机
- (void)pushImagePickerController {
    // 提前定位
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
#ifdef TZ_HAVE_LOCATION_CODE
    if (tzImagePickerVc.allowCameraLocation) {
        __weak typeof(self) weakSelf = self;
        [[TZLocationManager manager] startLocationWithSuccessBlock:^(NSArray<CLLocation *> *locations) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.location = [locations firstObject];
        } failureBlock:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.location = nil;
        }];
    }
#endif
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: sourceType]) {
        self.imagePickerVc.sourceType = sourceType;
        NSMutableArray *mediaTypes = [NSMutableArray array];
        if (tzImagePickerVc.allowTakePicture) {
            [mediaTypes addObject:(NSString *)kUTTypeImage];
        }
        if (tzImagePickerVc.allowTakeVideo) {
            [mediaTypes addObject:(NSString *)kUTTypeMovie];
            self.imagePickerVc.videoMaximumDuration = tzImagePickerVc.videoMaximumDuration;
        }
        self.imagePickerVc.mediaTypes= mediaTypes;
        if (tzImagePickerVc.uiImagePickerControllerSettingBlock) {
            tzImagePickerVc.uiImagePickerControllerSettingBlock(_imagePickerVc);
        }
        [self presentViewController:_imagePickerVc animated:YES completion:nil];
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

- (void)refreshBottomToolBarStatus {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    // 刷新选中照片容器
    [self refreshSelectedPhotosContainer];
    
    // 刷新所有collection view以确保选中状态正确更新
    [_allCollectionView reloadData];
    [_videoCollectionView reloadData];
    [_photoCollectionView reloadData];
    
    if (tzImagePickerVc.photoPickerPageDidRefreshStateBlock) {
        tzImagePickerVc.photoPickerPageDidRefreshStateBlock(_collectionView, nil, nil, nil, nil, nil, nil, nil, nil);
    }
}

- (void)pushPhotoPrevireViewController:(TZPhotoPreviewController *)photoPreviewVc {
    [self pushPhotoPrevireViewController:photoPreviewVc needCheckSelectedModels:NO];
}

- (void)pushPhotoPrevireViewController:(TZPhotoPreviewController *)photoPreviewVc needCheckSelectedModels:(BOOL)needCheckSelectedModels {
    __weak typeof(self) weakSelf = self;
    photoPreviewVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    [photoPreviewVc setBackButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        if (needCheckSelectedModels) {
            [strongSelf checkSelectedModels];
        }
        [strongSelf.collectionView reloadData];
        [strongSelf refreshBottomToolBarStatus];
    }];
    [photoPreviewVc setDoneButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [strongSelf doneButtonClick];
    }];
    [photoPreviewVc setDoneButtonClickBlockCropMode:^(UIImage *cropedImage, id asset) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSArray *assets = @[];
        if (asset) {
            assets = @[asset];
        }
        NSArray *photos = @[];
        if (cropedImage) {
            photos = @[cropedImage];
        }
        [strongSelf didGetAllPhotos:photos assets:assets infoArr:nil];
    }];
    [self.navigationController pushViewController:photoPreviewVc animated:YES];
}

- (void)getSelectedPhotoBytes {
    // 越南语 && 5屏幕时会显示不下，暂时这样处理
    if ([[TZImagePickerConfig sharedInstance].preferredLanguage isEqualToString:@"vi"] && self.view.tz_width <= 320) {
        return;
    }
    // 原图功能已移除，此方法保留但不执行任何操作
}

- (void)prepareScrollCollectionViewToBottom {
    if (_shouldScrollToBottom && _models.count > 0) {
        // Wait for collection view to be properly laid out
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Check if collection view has valid content size before scrolling
            if (self->_collectionView && self->_collectionView.contentSize.height > 0) {
                [self scrollCollectionViewToBottom];
            } else {
                // If content size is not ready, try again after a longer delay
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self->_collectionView && self->_collectionView.contentSize.height > 0) {
                        [self scrollCollectionViewToBottom];
                    }
                });
            }
            
            // try fix #1562：https://github.com/banchichen/TZImagePickerController/issues/1562
            if (@available(iOS 15.0, *)) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (self->_collectionView && self->_collectionView.contentSize.height > 0) {
                        [self scrollCollectionViewToBottom];
                    }
                });
            }
        });
    } else {
        // Show current collection view
        _collectionView.hidden = NO;
    }
}

- (void)scrollCollectionViewToBottom {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    // Get the actual count from the current collection view's data source
    NSInteger actualCount = 0;
    if (self->_collectionView == _allCollectionView) {
        actualCount = [self getAllCellCount];
    } else if (self->_collectionView == _videoCollectionView) {
        actualCount = [self getVideoCellCount];
    } else if (self->_collectionView == _photoCollectionView) {
        actualCount = [self getPhotoCellCount];
    } else {
        // Fallback to getAllCellCount for backward compatibility
        actualCount = [self getAllCellCount];
    }
    
    // Safety check: ensure we have items to scroll to
    if (actualCount <= 0) {
        self->_shouldScrollToBottom = NO;
        self->_collectionView.hidden = NO;
        return;
    }
    
    NSInteger item = 0;
    if (tzImagePickerVc.sortAscendingByModificationDate) {
        item = actualCount - 1;
    }
    
    // Double check that the item index is valid
    if (item >= actualCount) {
        item = actualCount - 1;
    }
    if (item < 0) {
        item = 0;
    }
    
    // Additional safety check before scrolling
    if (self->_collectionView && !self->_collectionView.hidden && self->_collectionView.contentSize.height > 0) {
        @try {
            [self->_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        } @catch (NSException *exception) {
            // If scrolling fails, try scrolling to the last valid position
            if (actualCount > 0) {
                NSInteger safeItem = MIN(item, actualCount - 1);
                [self->_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:safeItem inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            }
        }
    }
    
    self->_shouldScrollToBottom = NO;
    self->_collectionView.hidden = NO;
}

// Scroll specified collection view to bottom (used to ensure every tab defaults to bottom)
- (void)scrollCollectionViewToBottom:(UICollectionView *)collectionView {
    if (!collectionView || collectionView.hidden) return;
    
    // Ensure collection view has been laid out and has valid content size
    if (collectionView.contentSize.height <= 0) {
        // If content size is not ready, try again after a short delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self scrollCollectionViewToBottom:collectionView];
        });
        return;
    }
    
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    // Get the actual count from the collection view's data source
    NSInteger count = [self getCellCountForCollectionView:collectionView];
    if (count <= 0) return;
    
    __block NSInteger item = 0;
    if (tzImagePickerVc.sortAscendingByModificationDate) {
        item = count - 1;
    }
    
    // Double check that the item index is valid before scrolling
    if (item >= count) {
        item = count - 1;
    }
    if (item < 0) {
        item = 0;
    }
    
    // Use a longer delay to ensure collection view layout is complete
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Final safety check before scrolling - get fresh count
        NSInteger currentCount = [self getCellCountForCollectionView:collectionView];
        if (currentCount <= 0) return;
        
        // Recalculate item index with fresh count
        NSInteger finalItem = 0;
        if (tzImagePickerVc.sortAscendingByModificationDate) {
            finalItem = currentCount - 1;
        }
        
        // Ensure final item index is valid
        if (finalItem >= currentCount) {
            finalItem = currentCount - 1;
        }
        if (finalItem < 0) {
            return; // No items to scroll to
        }
        
        // Additional check: ensure the collection view is still valid and visible
        if (collectionView && !collectionView.hidden && collectionView.contentSize.height > 0) {
            @try {
                [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:finalItem inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            } @catch (NSException *exception) {
                // If scrolling fails, try scrolling to the last valid position
                if (currentCount > 0) {
                    NSInteger safeItem = MIN(finalItem, currentCount - 1);
                    [collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:safeItem inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
                }
            }
        }
    });
}

- (void)checkSelectedModels {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    NSArray *selectedModels = tzImagePickerVc.selectedModels;
    NSMutableSet *selectedAssets = [NSMutableSet setWithCapacity:selectedModels.count];
    for (TZAssetModel *model in selectedModels) {
        [selectedAssets addObject:model.asset];
    }
    // 拿到了最新的models，在此刷新照片选中状态
    for (TZAssetModel *model in _models) {
        model.isSelected = NO;
        if ([selectedAssets containsObject:model.asset]) {
            model.isSelected = YES;
        }
    }
}

/// 选中/取消选中某张照片
- (void)setAsset:(PHAsset *)asset isSelect:(BOOL)isSelect {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    
    // 更新所有models数组中的对应model状态
    for (TZAssetModel *model in self.allModels) {
        if ([model.asset.localIdentifier isEqualToString:asset.localIdentifier]) {
            model.isSelected = isSelect;
            break;
        }
    }
    for (TZAssetModel *model in self.photoModels) {
        if ([model.asset.localIdentifier isEqualToString:asset.localIdentifier]) {
            model.isSelected = isSelect;
            break;
        }
    }
    for (TZAssetModel *model in self.videoModels) {
        if ([model.asset.localIdentifier isEqualToString:asset.localIdentifier]) {
            model.isSelected = isSelect;
            break;
        }
    }
    
    if (isSelect && [tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didSelectAsset:photo:isSelectOriginalPhoto:)]) {
        [self callDelegate:asset isSelect:YES];
    }
    if (!isSelect && [tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didDeselectAsset:photo:isSelectOriginalPhoto:)]) {
        [self callDelegate:asset isSelect:NO];
    }
}

/// 处理视频选择时的特殊逻辑
- (void)handleVideoSelection:(TZAssetModel *)model tzImagePickerVc:(TZImagePickerController *)tzImagePickerVc {
    // 只有在允许选择图片时才检查是否已选择图片
    if (tzImagePickerVc.allowPickingImage) {
        // 检查是否已选择图片，如果已选择图片则不允许选择视频
        for (TZAssetModel *selectedModel in tzImagePickerVc.selectedModels) {
            if (selectedModel.asset.mediaType == PHAssetMediaTypeImage) {
                // 已选择图片，不允许选择视频，直接返回
                return;
            }
        }
    }
    
    // 检查是否已选择视频
    TZAssetModel *selectedVideo = nil;
    for (TZAssetModel *selectedModel in tzImagePickerVc.selectedModels) {
        if (selectedModel.asset.mediaType == PHAssetMediaTypeVideo) {
            selectedVideo = selectedModel;
            break;
        }
    }
    
    if (selectedVideo) {
        // 如果已选择视频，移除之前的视频选择
        [tzImagePickerVc removeSelectedModel:selectedVideo];
        [self setAsset:selectedVideo.asset isSelect:NO];
    }
    
    // 添加新的视频选择
    model.isSelected = YES;
    [tzImagePickerVc addSelectedModel:model];
    [self setAsset:model.asset isSelect:YES];
}

/// 处理照片选择时的特殊逻辑（当已选择视频时）
- (void)handlePhotoSelectionWhenVideoSelected:(TZAssetModel *)model tzImagePickerVc:(TZImagePickerController *)tzImagePickerVc {
    // 检查是否已选择视频
    TZAssetModel *selectedVideo = nil;
    for (TZAssetModel *selectedModel in tzImagePickerVc.selectedModels) {
        if (selectedModel.asset.mediaType == PHAssetMediaTypeVideo) {
            selectedVideo = selectedModel;
            break;
        }
    }
    
    if (selectedVideo) {
        // 如果已选择视频，移除视频选择
        [tzImagePickerVc removeSelectedModel:selectedVideo];
        [self setAsset:selectedVideo.asset isSelect:NO];
    }
    
    // 添加照片选择
    model.isSelected = YES;
    [tzImagePickerVc addSelectedModel:model];
    [self setAsset:model.asset isSelect:YES];
}

/// 调用选中/取消选中某张照片的代理方法
- (void)callDelegate:(PHAsset *)asset isSelect:(BOOL)isSelect {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    __weak typeof(self) weakSelf = self;
    __weak typeof(tzImagePickerVc) weakImagePickerVc= tzImagePickerVc;
    [[TZImageManager manager] getPhotoWithAsset:asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (isDegraded) return;
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakImagePickerVc) strongImagePickerVc = weakImagePickerVc;
        if (isSelect) {
            [strongImagePickerVc.pickerDelegate imagePickerController:strongImagePickerVc didSelectAsset:asset photo:photo isSelectOriginalPhoto:strongSelf.isSelectOriginalPhoto];
        } else {
            [strongImagePickerVc.pickerDelegate imagePickerController:strongImagePickerVc didDeselectAsset:asset photo:photo isSelectOriginalPhoto:strongSelf.isSelectOriginalPhoto];
        }
    }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
        [imagePickerVc showProgressHUD];
        UIImage *photo = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSDictionary *meta = [info objectForKey:UIImagePickerControllerMediaMetadata];
        if (photo) {
            self.isSavingMedia = YES;
            [[TZImageManager manager] savePhotoWithImage:photo meta:meta location:self.location completion:^(PHAsset *asset, NSError *error){
                self.isSavingMedia = NO;
                if (!error && asset) {
                    [self addPHAsset:asset];
                } else {
                    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
                    [tzImagePickerVc hideProgressHUD];
                }
            }];
            self.location = nil;
        }
    } else if ([type isEqualToString:@"public.movie"]) {
        TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
        [imagePickerVc showProgressHUD];
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        if (videoUrl) {
            self.isSavingMedia = YES;
            [[TZImageManager manager] saveVideoWithUrl:videoUrl location:self.location completion:^(PHAsset *asset, NSError *error) {
                self.isSavingMedia = NO;
                if (!error && asset) {
                    [self addPHAsset:asset];
                } else {
                    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
                    [tzImagePickerVc hideProgressHUD];
                }
            }];
            self.location = nil;
        }
    }
}

- (void)addPHAsset:(PHAsset *)asset {
    TZAssetModel *assetModel = [[TZImageManager manager] createModelWithAsset:asset];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    [tzImagePickerVc hideProgressHUD];
    if (tzImagePickerVc.sortAscendingByModificationDate) {
        [_models addObject:assetModel];
    } else {
        [_models insertObject:assetModel atIndex:0];
    }
    
    if (tzImagePickerVc.maxImagesCount <= 1) {
        if (tzImagePickerVc.allowCrop && asset.mediaType == PHAssetMediaTypeImage) {
            TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
            if (tzImagePickerVc.sortAscendingByModificationDate) {
                photoPreviewVc.currentIndex = _models.count - 1;
            } else {
                photoPreviewVc.currentIndex = 0;
            }
            photoPreviewVc.models = _models;
            [self pushPhotoPrevireViewController:photoPreviewVc];
        } else if (tzImagePickerVc.selectedModels.count < 1) {
            [tzImagePickerVc addSelectedModel:assetModel];
            [self doneButtonClick];
        }
        return;
    }
    
    if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
        if (assetModel.type == TZAssetModelMediaTypeVideo && !tzImagePickerVc.allowPickingMultipleVideo) {
            // 不能多选视频的情况下，不选中拍摄的视频
        } else {
            if ([[TZImageManager manager] isAssetCannotBeSelected:assetModel.asset]) {
                return;
            }
            assetModel.isSelected = YES;
            [tzImagePickerVc addSelectedModel:assetModel];
            [self refreshBottomToolBarStatus];
        }
    }
    // Hide all collection views temporarily
    _allCollectionView.hidden = YES;
    _videoCollectionView.hidden = YES;
    _photoCollectionView.hidden = YES;
    
    // Reload all collection views
    [_allCollectionView reloadData];
    [_videoCollectionView reloadData];
    [_photoCollectionView reloadData];
    
    _shouldScrollToBottom = YES;
    [self prepareScrollCollectionViewToBottom];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if (self.isSavingMedia || self.isFetchingMedia) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        PHFetchResultChangeDetails *changeDetail = [changeInstance changeDetailsForFetchResult:self.model.result];
        if (changeDetail == nil) return;
        if ([[TZImageManager manager] isPHAuthorizationStatusLimited]) {
            NSArray *changedObjects = [changeDetail changedObjects];
            changeDetail = [PHFetchResultChangeDetails changeDetailsFromFetchResult:self.model.result toFetchResult:changeDetail.fetchResultAfterChanges changedObjects:changedObjects];
            if (changeDetail && changeDetail.removedObjects.count) {
                [self handleRemovedAssets:changeDetail.removedObjects];
            }
        }

        if (changeDetail.hasIncrementalChanges == NO) {
            [self.model refreshFetchResult];
            [self fetchAssetModels];
        } else {
            NSInteger insertedCount = changeDetail.insertedObjects.count;
            NSInteger removedCount = changeDetail.removedObjects.count;
            NSInteger changedCount = changeDetail.changedObjects.count;
            if (insertedCount > 0 || removedCount > 0 || changedCount > 0) {
                self.model.result = changeDetail.fetchResultAfterChanges;
                self.model.count = changeDetail.fetchResultAfterChanges.count;
                [self fetchAssetModels];
            }
        }
    });
}

- (void)handleRemovedAssets:(NSArray<PHAsset *> *)removedObjects {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    for (PHAsset *asset in removedObjects) {
        Boolean isSelected = [tzImagePickerVc.selectedAssetIds containsObject:asset.localIdentifier];
        if (!isSelected) continue;
        NSArray *selectedModels = [NSArray arrayWithArray:tzImagePickerVc.selectedModels];
        for (TZAssetModel *model_item in selectedModels) {
            if ([asset.localIdentifier isEqualToString:model_item.asset.localIdentifier]) {
                [tzImagePickerVc removeSelectedModel:model_item];
            }
        }
        [self refreshBottomToolBarStatus];
    }
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [[TZImageManager manager].cachingImageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = _collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(_collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [[TZImageManager manager].cachingImageManager startCachingImagesForAssets:assetsToStartCaching
                                                                       targetSize:AssetGridThumbnailSize
                                                                      contentMode:PHImageContentModeAspectFill
                                                                          options:nil];
        [[TZImageManager manager].cachingImageManager stopCachingImagesForAssets:assetsToStopCaching
                                                                      targetSize:AssetGridThumbnailSize
                                                                     contentMode:PHImageContentModeAspectFill
                                                                         options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.item < _models.count) {
            TZAssetModel *model = _models[indexPath.item];
            [assets addObject:model.asset];
        }
    }
    
    return assets;
}

- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [_collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}
#pragma clang diagnostic pop

#pragma mark - UITableViewDataSource && Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.albumArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TZAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TZAlbumCell"];
    if (@available(iOS 13.0, *)) {
        cell.backgroundColor = UIColor.tertiarySystemBackgroundColor;
    }
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    cell.albumCellDidLayoutSubviewsBlock = imagePickerVc.albumCellDidLayoutSubviewsBlock;
    cell.albumCellDidSetModelBlock = imagePickerVc.albumCellDidSetModelBlock;
    cell.selectedCountButton.backgroundColor = imagePickerVc.iconThemeColor;
    cell.model = self.albumArr[indexPath.row];
    // 移除右侧箭头，已在TZAlbumCell初始化中设置
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TZAlbumModel *selectedModel = self.albumArr[indexPath.row];
    
    // Store the selected model before dismissing
    self.selectedAlbumModel = selectedModel;
    
    // Dismiss the slide-down album picker first
    [self dismissAlbumPicker];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 82; // 所有cell统一高度: 70px照片高度 + 12px间距
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    // 为第一个cell添加顶部间距
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 15)];
    headerView.backgroundColor = [UIColor clearColor];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 15; // 第一个cell的顶部间距
}

@end



@implementation TZCollectionView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    if ([view isKindOfClass:[UIControl class]]) {
        return YES;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end
