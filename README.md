# TableViewLazyLoadingPicDemo
当我们使用手机刷微博和看新闻的时候，经常滑过不太关注的内容，也许你也发现了，跳过的内容中的图片很多显示的是默认图，并没有网络加载图片，这个是一个比较好的体验，一方面不需要加载太多的内容，可以减少用户的流量，体验也更加流畅；另一方面也减轻了服务器的压力。一举两得，何乐而不为。

所以想实现这个效果，经过一番的检索[站在巨人的肩膀上]，找到了一个不错的博客 [lazy懒加载(延迟加载)UITableView ](http://blog.csdn.net/hmt20130412/article/details/32173215)，因为是自己实现的下载图片和缓存，而我应用中使用的是基于SDWebImage方式的，所以我做了些改动，希望能帮到你。

原理博客中介绍的很清楚了，在停止滑动的时候，再进行加载当前窗口中cell的图片，而不是全部cell中的图片，加载结束时进行图片缓存，下次刷新的时候直接从缓存中取得图片。

首先在对应的model中多增加了一个UIImage类型的属性，用于获取缓存图片。
```
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PhotoModel : NSObject

@property(copy,nonatomic)NSString *photoPath;


@property(strong,nonatomic)UIImage  *photoImg;



@end

#import "PhotoModel.h"
#import "UIImageView+WebCache.h"

@implementation PhotoModel

- (UIImage *)photoImg
{
    
    if (self.photoPath) { // 如果缓存中有，就从缓存中获取
        
        NSURL  *pathUrl = [NSURL URLWithString:self.photoPath];

        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager diskImageExistsForURL:pathUrl];
        
        _photoImg = [[manager imageCache] imageFromDiskCacheForKey:pathUrl.absoluteString];
    }
    
    return _photoImg;
}

@end


```

然后，在滑动结束时，进行加载图片就可以了
```
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

```


