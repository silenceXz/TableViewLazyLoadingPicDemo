//
//  PhotoModel.h
//  TableView懒加载图片
//
//  Created by Apple on 17/4/26.
//  Copyright © 2017年 silence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PhotoModel : NSObject

@property(copy,nonatomic)NSString *photoPath;


@property(strong,nonatomic)UIImage  *photoImg;


@end
