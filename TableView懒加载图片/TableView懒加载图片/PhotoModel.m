//
//  PhotoModel.m
//  TableView懒加载图片
//
//  Created by Apple on 17/4/26.
//  Copyright © 2017年 silence. All rights reserved.
//

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
