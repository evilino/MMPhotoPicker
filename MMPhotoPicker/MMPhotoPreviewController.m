//
//  MMPhotoPreviewController.m
//  MMPhotoPicker
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "MMPhotoPreviewController.h"
#import "MMPhotoPickerConst.h"

@interface MMPhotoPreviewController ()<UIScrollViewDelegate>

@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIView *titleView;
@property(nonatomic, strong) UILabel *titleLab;

@property(nonatomic, assign) BOOL isHidden;
@property(nonatomic, assign) NSInteger index;

@end

@implementation MMPhotoPreviewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    _isHidden = NO;
    [self setUpUI];
    [self loadImage];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

#pragma mark - 设置UI
- (void)setUpUI
{
    // 滚动视图
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.delegate = self;
    _scrollView.scrollEnabled = YES;
    _scrollView.userInteractionEnabled = YES;
    _scrollView.backgroundColor = [UIColor clearColor];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) {
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:_scrollView];
    
    CGFloat top = 20;
    CGFloat topH = 64;
    if (kDeviceIsIphoneX) {
        top = kStatusHeight;
        topH = kTopBarHeight;
    }
    _titleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.width, topH)];
    _titleView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    [self.view addSubview:_titleView];
    // 返回按钮
    UIImage *image = [UIImage imageNamed:MMPhotoPickerSrcName(@"mmphoto_back")];
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, top, kNavHeight, kNavHeight)];
    [backBtn setImage:image forState:UIControlStateNormal];
    [backBtn setImageEdgeInsets:UIEdgeInsetsMake((kNavHeight-image.size.height)/2, 0, (kNavHeight-image.size.height)/2, 0)];
    [backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [_titleView addSubview:backBtn];
    // 顺序Label
    _titleLab = [[UILabel alloc] initWithFrame:CGRectMake((_titleView.width-200)/2, top, 200, kNavHeight)];
    _titleLab.font = [UIFont boldSystemFontOfSize:19.0];
    _titleLab.textAlignment = NSTextAlignmentCenter;
    _titleLab.textColor = [UIColor whiteColor];
    _titleLab.text = [NSString stringWithFormat:@"1/%d",(int)[self.assetArray count]];
    [_titleView addSubview:_titleLab];
    // 删除按钮
    image = [UIImage imageNamed:MMPhotoPickerSrcName(@"mmphoto_delete")];
    UIButton *delBtn = [[UIButton alloc]initWithFrame:CGRectMake(_titleView.width-kNavHeight, top, kNavHeight, kNavHeight)];
    [delBtn setImage:image forState:UIControlStateNormal];
    [delBtn setImageEdgeInsets:UIEdgeInsetsMake((kNavHeight-image.size.height)/2, 0, (kNavHeight-image.size.height)/2, 0)];
    [delBtn addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];
    [_titleView addSubview:delBtn];
    // 双击
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapGestureCallback:)];
    doubleTap.numberOfTapsRequired = 2;
    [_scrollView addGestureRecognizer:doubleTap];
    // 单击
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCallback:)];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [_scrollView addGestureRecognizer:singleTap];
}

#pragma mark - 手势处理
- (void)doubleTapGestureCallback:(UITapGestureRecognizer *)gesture
{
    CGFloat pageWidth = _scrollView.frame.size.width;
    _index = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    
    UIScrollView *scrollView = [_scrollView viewWithTag:100+_index];
    CGFloat zoomScale = scrollView.zoomScale;
    if (zoomScale == scrollView.maximumZoomScale) {
        zoomScale = 0;
    } else {
        zoomScale = scrollView.maximumZoomScale;
    }
    [UIView animateWithDuration:0.35
                     animations:^{
                         scrollView.zoomScale = zoomScale;
                     }];
}

- (void)singleTapGestureCallback:(UITapGestureRecognizer *)gesture
{
    _isHidden = !_isHidden;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5
                     animations:^{
                         weakSelf.titleView.hidden = weakSelf.isHidden;
                     }];
}

#pragma mark - 时间处理
- (void)backAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)deleteAction
{
    // 移除重新加载
    PHAsset *asset = [self.assetArray objectAtIndex:_index];
    [self.assetArray removeObjectAtIndex:_index];
    [self loadImage];
    // 更新索引
    CGFloat pageWidth = _scrollView.frame.size.width;
    _index = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _titleLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)_index+1,(long)[self.assetArray count]];
    // block
    if (self.photoDeleteBlock) {
        self.photoDeleteBlock(asset);
    }
    // 返回
    if (![self.assetArray count]) {
        [self backAction];
    }
}

- (void)loadImage
{
    // 移除
    [_scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 重新添加
    NSInteger count = [self.assetArray count];
    for (int i = 0; i < count; i ++)
    {
        PHAsset *asset = [self.assetArray objectAtIndex:i];
        [MMPhotoUtil getImageWithAsset:asset completion:^(UIImage *image) {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
            imageView.image = image;
            imageView.clipsToBounds  = YES;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.contentScaleFactor = [[UIScreen mainScreen] scale];
            imageView.backgroundColor = [UIColor clearColor];
            
            UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(_scrollView.width * i, 0, _scrollView.width, _scrollView.height)];
            scrollView.contentSize = CGSizeMake(scrollView.width, scrollView.height);
            scrollView.minimumZoomScale = 1.0;
            scrollView.delegate = self;
            scrollView.showsHorizontalScrollIndicator = NO;
            scrollView.showsVerticalScrollIndicator = NO;
            scrollView.backgroundColor = [UIColor clearColor];
            scrollView.tag = 100+i;
            [scrollView addSubview:imageView];
            
            CGSize imgSize = [imageView.image size];
            CGFloat scaleX = self.view.width/imgSize.width;
            CGFloat scaleY = self.view.height/imgSize.height;
            if (scaleX > scaleY) {
                CGFloat imgViewWidth = imgSize.width*scaleY;
                scrollView.maximumZoomScale = self.view.width/imgViewWidth;
            } else {
                CGFloat imgViewHeight = imgSize.height*scaleX;
                scrollView.maximumZoomScale = self.view.height/imgViewHeight;
            }
            
            [_scrollView addSubview:scrollView];
        }];
    }
    [_scrollView setPagingEnabled:YES];
    [_scrollView setContentSize:CGSizeMake(_scrollView.width * count, _scrollView.height)];
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return [scrollView.subviews objectAtIndex:0];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = _scrollView.frame.size.width;
    _index = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _titleLab.text = [NSString stringWithFormat:@"%ld/%ld",(long)_index+1,(long)[self.assetArray count]];
}

#pragma mark - 隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark -
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
