//
//  ViewController.m
//  TableView懒加载图片
//
//  Created by Apple on 17/4/26.
//  Copyright © 2017年 silence. All rights reserved.
//

#import "ViewController.h"
#import "PhotoModel.h"
#import "UIImageView+WebCache.h"
#import "PhotoTableViewCell.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(strong,nonatomic)UITableView  *tableView;

@property(strong,nonatomic)NSMutableArray  *dataArray;

@property(strong,nonatomic)UIButton *btn;

@property(assign,nonatomic)BOOL isClean;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.dataArray = [NSMutableArray array];
    
    NSArray *photoUrlArray = @[@"http://img04.tooopen.com/images/20130701/tooopen_10055061.jpg",@"http://img07.tooopen.com/images/20170412/tooopen_sy_205630266491.jpg",@"http://img07.tooopen.com/images/20170320/tooopen_sy_202527818519.jpg",@"http://img07.tooopen.com/images/20170215/tooopen_sy_198728087187.jpg",@"http://img06.tooopen.com/images/20170321/tooopen_sy_202706818574.jpg",@"http://img06.tooopen.com/images/20170321/tooopen_sy_202673188311.jpg",@"http://img06.tooopen.com/images/20170316/tooopen_sy_202006455884.jpg",@"http://img05.tooopen.com/images/20150202/sy_80219211654.jpg",@"http://img07.tooopen.com/images/20170408/tooopen_sy_204617584847.jpg",@"http://img07.tooopen.com/images/20170425/tooopen_sy_206826439616.jpg"];
    
    for (int i = 0; i < photoUrlArray.count; i++) {
        
        PhotoModel *model = [[PhotoModel alloc]init];
        model.photoPath = photoUrlArray[i];
        [self.dataArray addObject:model];
    }
    
    [self.view addSubview:self.tableView];
    
    // 清除缓存
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(self.view.bounds.size.width*.5 - 40 ,60, 80, 50);
    btn.layer.cornerRadius = 10;
    btn.clipsToBounds = YES;
    [btn addTarget:self action:@selector(clearCache) forControlEvents:UIControlEventTouchUpInside];
    btn.layer.borderWidth = 1;
    btn.layer.borderColor = [UIColor blueColor].CGColor;
    [btn setTitle:@"清除缓存" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    self.btn = btn;
    [self.view addSubview:btn];
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
}

- (UITableView *)tableView
{
    if (_tableView == nil)
    {
        CGRect frame = self.view.bounds;
        _tableView = [[UITableView alloc]initWithFrame:frame style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.showsVerticalScrollIndicator = NO;

        UIView *view = [[UIView alloc] init];
        _tableView.tableFooterView = view;
    }
    
    return _tableView;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 300;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"PhotoTableViewCell";
    PhotoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        
        cell = [[PhotoTableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    PhotoModel *model = [self.dataArray objectAtIndex:indexPath.row];
    
    if (model.photoImg == nil) {
        
        // 缓存中没有，去下载吧
        cell.photoImgView.image = nil;
        
        NSLog(@"dragging = %d,decelerating = %d",self.tableView.dragging,self.tableView.decelerating);
        // 停止拖拽或者滑动结束时，加载当前cell对应的图片
        if (self.tableView.dragging == NO && self.tableView.decelerating == NO) {
            
            [self startPicDownload:model forIndexPath:indexPath];
        }
        
    }else{
        
        // 缓存中直接显示出来
        cell.photoImgView.image = model.photoImg;
    }
    
    return cell;
}

- (void)startPicDownload:(PhotoModel *)model forIndexPath:(NSIndexPath *)indexPath{
    
    UIImageView *tappedImageView = [[UIImageView alloc]init];
    
    NSURL  *pathUrl = [NSURL URLWithString:model.photoPath];

    [tappedImageView sd_setImageWithURL:pathUrl placeholderImage:nil options:SDWebImageProgressiveDownload completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        tappedImageView.image = image;
        
        // 根据indexPath获取cell对象，并加载图像
        PhotoTableViewCell * cell = (PhotoTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        cell.photoImgView.image = image;
    }];
}

#pragma mark - 延迟加载关键
//tableView停止拖拽，停止滚动
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    //如果tableview停止滚动，开始加载图像
    if (!decelerate) {
        
        [self loadImagesForOnscreenRows];
    }
    NSLog(@"%s__%d__|%d",__FUNCTION__,__LINE__,decelerate);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //如果tableview停止滚动，开始加载图像
    [self loadImagesForOnscreenRows];
}

- (void)loadImagesForOnscreenRows
{
    //获取tableview正在window上显示的cell，加载这些cell上图像。通过indexPath可以获取该行上需要展示的cell对象
    NSArray * visibleCells = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath * indexPath in visibleCells) {
        
        PhotoModel *model = [self.dataArray objectAtIndex:indexPath.row];
        if (model.photoImg == nil) {
            
            //如果还没有下载图像，开始下载
            [self startPicDownload:model forIndexPath:indexPath];
        }
    }
}

- (void)clearCache{
    
    self.isClean = !self.isClean;
    
    if (self.isClean) {
        
        self.tableView.userInteractionEnabled = NO;
        self.tableView.dataSource = nil;
        self.tableView.delegate = nil;
        
        __weak typeof(self) weakSelf = self;
        // 清空SDImageCache 的文件缓存
        [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
            
            [weakSelf.tableView reloadData];
            weakSelf.tableView.userInteractionEnabled = YES;
            [weakSelf.btn setTitle:@"更新" forState:UIControlStateNormal];
        }];
        
    }else{
        
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
        [self.btn setTitle:@"清理缓存" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
