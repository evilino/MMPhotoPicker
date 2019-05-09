//
//  ViewController.m
//  MMPhotoPickerDemo
//
//  Created by LEA on 2017/11/10.
//  Copyright © 2017年 LEA. All rights reserved.
//

#import "ViewController.h"
#import "MMPhotoPickerController.h"

static NSString * const CellIdentifier = @"PhotoCell";
@interface ViewController () <MMPhotoPickerDelegate,UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView * collectionView;
@property (nonatomic, strong) NSMutableArray * infoArray;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"示例";
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat margin = (self.view.width - 2 * 100) / 3.0;
    // 选择图片
    UIButton * btn = [[UIButton alloc] initWithFrame:CGRectMake(margin, 50, 100, 44)];
    btn.backgroundColor = [UIColor lightGrayColor];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"选择图片" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(pickerClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    // 保存图片
    btn = [[UIButton alloc] initWithFrame:CGRectMake(btn.right+margin, 50, 100, 44)];
    btn.backgroundColor = [UIColor lightGrayColor];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn setTitle:@"保存图片" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(saveClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    // 图片显示
    self.infoArray = [[NSMutableArray alloc] init];
    [self.view addSubview:self.collectionView];
}

#pragma mark - click
- (void)pickerClicked
{
    // 优先级 cropOption > singleOption > maxNumber
    // cropOption = YES 时，不显示视频
    MMPhotoPickerController * controller = [[MMPhotoPickerController alloc] init];
    controller.delegate = self;
    controller.showEmptyAlbum = YES;
    controller.showVideo = YES;
    controller.cropOption = NO;
    controller.singleOption = NO;
    controller.maxNumber = 6; 

    UINavigationController * navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    [navigation.navigationBar setBackgroundImage:[UIImage imageNamed:@"default_bar"] forBarMetrics:UIBarMetricsDefault];
    navigation.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor],NSFontAttributeName:[UIFont boldSystemFontOfSize:19.0]};
    navigation.navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigation.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController presentViewController:navigation animated:YES completion:nil];
}

- (void)saveClicked
{
    UIImage * image = [UIImage imageNamed:@"default_save"];
    [MMPhotoUtil saveImage:image completion:^(BOOL success) {
        NSString * message = nil;
        if (success) {
            message = @"图片保存成功";
        } else {
            message = @"图片保存出错";
        }
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:message
                                                         message:nil
                                                        delegate:nil
                                               cancelButtonTitle:@"知道了"
                                               otherButtonTitles:nil, nil];
        [alert show];
    }];
}

#pragma mark - lazy load
- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        NSInteger numInLine = (kIPhone6p || kIPhoneXM) ? 5 : 4;
        CGFloat itemWidth = (self.view.width - (numInLine + 1) * kMargin) / numInLine;
        
        UICollectionViewFlowLayout * flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
        flowLayout.sectionInset = UIEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin);
        flowLayout.minimumLineSpacing = kMargin;
        flowLayout.minimumInteritemSpacing = 0.f;
        
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 150, self.view.width, self.view.height-kTopHeight-150) collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.scrollEnabled = YES;
        [_collectionView registerClass:[PhotoCell class] forCellWithReuseIdentifier:CellIdentifier];
    }
    return _collectionView;
}

#pragma mark - MMPhotoPickerDelegate
- (void)mmPhotoPickerController:(MMPhotoPickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    [self.infoArray removeAllObjects];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        // 图片压缩一下，不然大图显示太慢
        for (int i = 0; i < [info count]; i ++)
        {
            NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithDictionary:[info objectAtIndex:i]];
            UIImage * image = [dict objectForKey:MMPhotoOriginalImage];
            if (!picker.isOrigin) { // 原图
                NSData * imageData = UIImageJPEGRepresentation(image,1.0);
                int size = (int)[imageData length]/1024;
                if (size < 100) {
                    imageData = UIImageJPEGRepresentation(image, 0.5);
                } else {
                    imageData = UIImageJPEGRepresentation(image, 0.1);
                }
                image = [UIImage imageWithData:imageData];
            }
            [dict setObject:image forKey:MMPhotoOriginalImage];
            [self.infoArray addObject:dict];
        }
        
        GCD_MAIN(^{ // 主线程
            [self.collectionView reloadData];
            [picker dismissViewControllerAnimated:YES completion:nil];
        });
    });
}

- (void)mmPhotoPickerControllerDidCancel:(MMPhotoPickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.infoArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 赋值
    PhotoCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.info = [self.infoArray objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark -
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end

#pragma mark - ####################  PhotoCell

@interface PhotoCell ()

@property (nonatomic, strong) UIImageView * imageView;
@property (nonatomic, strong) UIImageView * videoOverLay;

@end

@implementation PhotoCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor lightGrayColor];
        
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.layer.masksToBounds = YES;
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.contentScaleFactor = [[UIScreen mainScreen] scale];
        [self addSubview:_imageView];
        
        _videoOverLay = [[UIImageView alloc] init];
        _videoOverLay.size = CGSizeMake(_imageView.width * 0.4, _imageView.height * 0.4);
        _videoOverLay.center = _imageView.center;
        _videoOverLay.image = [UIImage imageNamed:@"mmphoto_video"];
        [self addSubview:_videoOverLay];
        _videoOverLay.hidden = YES;
    }
    return self;
}

#pragma mark - setter
- (void)setInfo:(NSDictionary *)info
{
    PHAssetMediaType mediaType = [[info objectForKey:MMPhotoMediaType] integerValue];
    if (mediaType == PHAssetMediaTypeVideo) {
        self.videoOverLay.hidden = NO;
    } else {
        self.videoOverLay.hidden = YES;
    }
    self.imageView.image = [info objectForKey:MMPhotoOriginalImage];
}

@end
