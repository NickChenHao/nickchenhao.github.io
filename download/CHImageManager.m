//
//  CHImageManager.m
//  错题斩
//
//  Created by nick on 2019/6/18.
//  Copyright © 2019 Nick. All rights reserved.
//

#import "CHImageManager.h"


@interface CHImageManager ()
@property (nonatomic, strong) NSOperationQueue *queue; // 队列
@property (nonatomic, strong) NSCache *imagesCache; // 图片缓存
@property (nonatomic, strong) NSCache *operationsCache; // 操作缓存
@end
@implementation CHImageManager

#pragma mark - 单例
static CHImageManager *_sharedInstance;
+ (CHImageManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_sharedInstance) {
            _sharedInstance = [[CHImageManager alloc] init];
        }
    });
    return _sharedInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [super allocWithZone:zone];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark - URL过滤器
//返回指定URL的缓存键值，就是URL字符串
- (NSString *)cacheKeyForURL:(NSURL *)url {
    //如果URL不存在，那么就返回空
    if (!url) {
        return @"";
    }

    //先判断是否设置了缓存过滤器，如果设置了则走cacheKeyFilterBlock,否则直接把URL转换为字符串之后返回
    if (self.cacheKeyFilter) {
        return self.cacheKeyFilter(url);
    } else {
        return [url absoluteString];
    }
}


#pragma mark - 自定义多图下载

- (void)customImageView:(UIImageView *)imageView UrlStr:(NSURL *)urlStr{

    //容错处理
    if ([urlStr isKindOfClass:NSString.class]) {
        urlStr = [NSURL URLWithString:(NSString *)urlStr];
    }

    if (![urlStr isKindOfClass:NSURL.class]) {
        urlStr = nil;
    }

    if (!urlStr) {
        return;
    }

    // 缓存key
    NSString *cacheKey = [self cacheKeyForURL:urlStr];

/* 从内存缓存中取 */
    UIImage *image = [self.imagesCache objectForKey:cacheKey];
    if (image) {
        // 直接设置
        imageView.image = image;
    }else{
/* 检查磁盘缓存 */
        // 获取文件路径
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        // 获取图片名称 获取节点
        NSString *fileName = [cacheKey lastPathComponent];
        // 拼接文件全路径
        NSString *fullPath = [cachePath stringByAppendingPathComponent:fileName];
        // 从磁盘缓存中取
        NSData *data = [NSData dataWithContentsOfFile:fullPath];

        if (data) {
            // 将二进制数据转成图片
            UIImage *image = [UIImage imageWithData:data];
            // 设置图片
            imageView.image = image;
            // 把图片存到内存缓存中
            [self.imagesCache setObject:image forKey:cacheKey];
        }else{
/* 检查操作缓存 */
            // 清空图片或者占位图片
            imageView.image = nil;
            // 检查操作缓存
            NSBlockOperation *downloadOperation = [self.operationsCache objectForKey:cacheKey];
            if (downloadOperation) {
                // 不处理

            }else{
                downloadOperation = [NSBlockOperation blockOperationWithBlock:^{
                    // 下载图片三部曲
                    NSData *tempData = [NSData dataWithContentsOfURL:urlStr];
                    UIImage *tempImage = [UIImage imageWithData:tempData];
                    if (tempImage == nil) {
                        // 移除操作缓存中的操作
                        [self.operationsCache removeObjectForKey:cacheKey];
                        return ;
                    }
                    // 把图片存到内存缓存
                    [self.imagesCache setObject:tempImage forKey:cacheKey];

                    // 把图片保存到磁盘缓存
                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
                        [data writeToFile:fullPath atomically:YES];
                    });

                    // 回到主线程
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        // 设置图片
                        imageView.image = tempImage;
                    }];
                }];
                // 添加操作缓存
                [self.operationsCache setObject:downloadOperation forKey:cacheKey];
                // 将操作加入队列
                [self.queue addOperation:downloadOperation];
            }
        }
    }
}

#pragma mark - lazy
- (NSOperationQueue *)queue{
    if (_queue) return _queue;
    _queue = [NSOperationQueue new];
    _queue.maxConcurrentOperationCount = 5;

    return _queue;
}

- (NSCache *)imagesCache{
    if (_imagesCache) return _imagesCache;
    _imagesCache = [NSCache new];

    return _imagesCache;
}

- (NSCache *)operationsCache{
    if (_operationsCache) return _operationsCache;
    _operationsCache = [NSCache new];

    return _operationsCache;
}

#pragma mark - 清除缓存
- (void)cleanCache{
    // 内存缓存
    [self.imagesCache removeAllObjects];
    // 操作缓存
    [self.operationsCache removeAllObjects];
    // 取消队列中的操作
    [self.queue cancelAllOperations];
}
@end
