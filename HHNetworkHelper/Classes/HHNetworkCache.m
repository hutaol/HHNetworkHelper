//
//  HHNetworkCache.m
//  Henry
//
//  Created by Henry on 2020/5/13.
//  Copyright © 2020 Henry. All rights reserved.
//

#import "HHNetworkCache.h"
#import <YYCache/YYCache.h>

static NSString *const kHTNetworkResponseCache = @"kHTNetworkResponseCache";
static YYCache *_dataCache;

@implementation HHNetworkCache

+ (void)initialize {
    _dataCache = [YYCache cacheWithName:kHTNetworkResponseCache];
}

+ (void)setHttpCache:(id)httpData URL:(NSString *)URL parameters:(id)parameters {
    NSString *cacheKey = [self cacheKeyWithURL:URL parameters:parameters];
    // 异步缓存，不会阻塞主线程
    [_dataCache setObject:httpData forKey:cacheKey withBlock:nil];
}

+ (id)httpCacheForURL:(NSString *)URL parameters:(NSDictionary *)parameters {
    NSString *cacheKey = [self cacheKeyWithURL:URL parameters:parameters];
    return [_dataCache objectForKey:cacheKey];
}

+ (NSInteger)getAllHttpCacheSize {
    return [_dataCache.diskCache totalCost];
}

+ (void)removeAllHttpCache {
    [_dataCache.diskCache removeAllObjects];
}

+ (NSString *)cacheKeyWithURL:(NSString *)URL parameters:(NSDictionary *)parameters {
    if(!parameters || parameters.count == 0) { return URL; };
    // 将参数字典转换成字符串
    NSData *stringData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString *paramsString = [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"%@%@", URL, paramsString];
}

@end
