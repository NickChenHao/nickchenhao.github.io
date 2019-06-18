//
//  CHImageManager.h
//  Nick
//
//  Created by nick on 2019/6/18.
//  Copyright © 2019 Nick. All rights reserved.
//  自定义图片下载

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//定义缓存过滤器的block块
typedef NSString *(^CHImageCacheKeyFilterBlock)(NSURL *url);

@interface CHImageManager : NSObject

@property (nonatomic, copy) CHImageCacheKeyFilterBlock cacheKeyFilter; //缓存过滤器

// 单例
+ (CHImageManager *)sharedManager;

// 下载图片
- (void)customImageView:(UIImageView *)imageView UrlStr:(NSString *)urlStr;

// 清除缓存
- (void)cleanCache;
@end

NS_ASSUME_NONNULL_END
