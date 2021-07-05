//
//  HHNetworkHelper.m
//  Henry
//
//  Created by Henry on 2020/5/13.
//  Copyright © 2020 Henry. All rights reserved.
//

#import "HHNetworkHelper.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>


#ifdef DEBUG
#define HHLog(...) printf("[%s] %s [第%d行]: %s\n", __TIME__, __PRETTY_FUNCTION__, __LINE__, [[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define HHLog(...)
#endif

static BOOL _isOpenLog;   // 是否已开启日志打印
static NSMutableArray *_allSessionTask;
static AFHTTPSessionManager *_sessionManager;
static NSString *_cacheAdditional;

@implementation HHNetworkHelper

+ (void)networkStatusWithBlock:(HHNetworkStatus)networkStatus {
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                if (networkStatus) networkStatus(HHNetworkStatusUnknown);
                if (_isOpenLog) HHLog(@"未知网络");
                break;
            case AFNetworkReachabilityStatusNotReachable:
                if (networkStatus) networkStatus(HHNetworkStatusNotReachable);
                if (_isOpenLog) HHLog(@"无网络");
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                if (networkStatus) networkStatus(HHNetworkStatusNotReachable);
                if (_isOpenLog) HHLog(@"手机自带网络");
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                if (networkStatus) networkStatus(HHNetworkStatusReachableViaWiFi);
                if (_isOpenLog) HHLog(@"WIFI");
                break;
        }
        
    }];
}

+ (BOOL)isNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

+ (BOOL)isWWANNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWWAN;
}

+ (BOOL)isWiFiNetwork {
    return [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
}

+ (void)cancelAllRequest {
    // 锁操作
    @synchronized(self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allSessionTask] removeAllObjects];
    }
}

+ (void)cancelRequestWithURL:(NSString *)URL {
    if (!URL) { return; }
    @synchronized (self) {
        [[self allSessionTask] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([task.currentRequest.URL.absoluteString hasPrefix:URL]) {
                [task cancel];
                [[self allSessionTask] removeObject:task];
                *stop = YES;
            }
        }];
    }
}

+ (void)openLog {
    _isOpenLog = YES;
}

+ (void)closeLog {
    _isOpenLog = NO;
}

/// 设置缓存额外的参数
/// @param additional 缓存参数
+ (void)setCacheAdditional:(NSString *)additional {
    if (additional && additional.length > 0) {
        _cacheAdditional = additional;
    }
}

#pragma mark - GET请求无缓存

+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(id)parameters success:(HHResponseSuccess)success failure:(HHResponseFailure)failure {
    return [self GET:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - POST请求无缓存

+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(id)parameters success:(HHResponseSuccess)success failure:(HHResponseFailure)failure {
    return [self POST:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - GET请求自动缓存

+ (NSURLSessionTask *)GET:(NSString *)URL parameters:(id)parameters responseCache:(HHResponseCache)responseCache success:(HHResponseSuccess)success failure:(HHResponseFailure)failure {
    
    if (responseCache) {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
        if (_cacheAdditional) [params setValue:_cacheAdditional forKey:@"cacheAdditional"];
        id response = [HHNetworkCache httpCacheForURL:URL parameters:params];
        responseCache(response);
        
        if (_isOpenLog) {
            [self logWithSuccessResponse:response url:URL params:parameters];
        }
    }
    
    NSURLSessionTask *sessionTask = [_sessionManager GET:URL parameters:parameters headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) {
            [self logWithSuccessResponse:responseObject url:URL params:parameters];
        }
        
        [[self allSessionTask] removeObject:task];
        
        id data = [self tryToParseData:responseObject];

        if (success) {
            success(data);
        }
        
        // 对数据进行异步缓存
        if (responseCache) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
            if (_cacheAdditional) [params setValue:_cacheAdditional forKey:@"cacheAdditional"];
            [HHNetworkCache setHttpCache:data URL:URL parameters:params];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) {
            [self logWithFailureError:error url:URL params:parameters];
        }
        
        [[self allSessionTask] removeObject:task];
        
        if (failure) { failure(error); }
        
    }];
    
    if (sessionTask) {
        [[self allSessionTask] addObject:sessionTask];
    }
    
    return sessionTask;
}

#pragma mark - POST请求自动缓存

+ (NSURLSessionTask *)POST:(NSString *)URL parameters:(id)parameters responseCache:(HHResponseCache)responseCache success:(HHResponseSuccess)success failure:(HHResponseFailure)failure {
    
    if (responseCache) {
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
        if (_cacheAdditional) [params setValue:_cacheAdditional forKey:@"cacheAdditional"];
        id response = [HHNetworkCache httpCacheForURL:URL parameters:params];

        responseCache(response);
        
        if (_isOpenLog) {
           [self logWithSuccessResponse:response url:URL params:parameters];
        }
    }
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) {
            [self logWithSuccessResponse:responseObject url:URL params:parameters];
        }
        
        [[self allSessionTask] removeObject:task];
        
        id data = [self tryToParseData:responseObject];

        if (success) {
            success(data);
        }
        
        // 对数据进行异步缓存
        if (responseCache) {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
            if (_cacheAdditional) [params setValue:_cacheAdditional forKey:@"cacheAdditional"];
            [HHNetworkCache setHttpCache:data URL:URL parameters:params];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) {
            [self logWithFailureError:error url:URL params:parameters];
        }
        
        [[self allSessionTask] removeObject:task];
        
        if (failure) { failure(error); }
        
    }];
        
    if (sessionTask) {
        [[self allSessionTask] addObject:sessionTask];
    }
    
    return sessionTask;
}

#pragma mark - 上传文件

+ (NSURLSessionTask *)uploadFileWithURL:(NSString *)URL parameters:(id)parameters name:(NSString *)name filePath:(NSString *)filePath mimeType:(NSString *)mimeType progress:(HTHttpProgress)progress success:(HHResponseSuccess)success failure:(HHResponseFailure)failure {
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSError *error = nil;
//        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        [formData appendPartWithFileData:data name:name fileName:[filePath lastPathComponent] mimeType:mimeType];

        if (failure && error) {
            failure(error);
            
            if (_isOpenLog) {
                [self logWithFailureError:error url:URL params:parameters];
            }
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        // 上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progress) {
                progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
            }
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) {
            [self logWithSuccessResponse:responseObject url:URL params:parameters];
        }
        
        [[self allSessionTask] removeObject:task];
        
        if (success) {
            success([self tryToParseData:responseObject]);
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) {
            [self logWithFailureError:error url:URL params:parameters];
        }
        
        [[self allSessionTask] removeObject:task];
        
        if (failure) { failure(error); }
        
    }];
    
    if (sessionTask) {
        [[self allSessionTask] addObject:sessionTask];
    }
    
    return sessionTask;
}

#pragma mark - 上传多张图片

+ (NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL parameters:(id)parameters name:(NSString *)name images:(NSArray<UIImage *> *)images fileNames:(NSArray<NSString *> *)fileNames imageScale:(CGFloat)imageScale imageType:(NSString *)imageType progress:(HTHttpProgress)progress success:(HHResponseSuccess)success failure:(HHResponseFailure)failure {
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:URL parameters:parameters headers:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (NSUInteger i = 0; i < images.count; i++) {
            // 图片经过等比压缩后得到的二进制文件
            NSData *imageData = UIImageJPEGRepresentation(images[i], imageScale ?: 1.f);
            // 默认图片的文件名, 若fileNames为nil就使用
            NSString *fileName = (fileNames && fileNames[i]) ? [NSString stringWithFormat:@"%@.%@", fileNames[i], imageType?:@"jpg"] : @"";
            
            if (!fileName || fileName.length == 0) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"yyyyMMddHHmmss";
                NSString *str = [formatter stringFromDate:[NSDate date]];
                NSString *imageFileName = [NSString stringWithFormat:@"%@%ld.%@", str, i, imageType?:@"jpg"];
                fileName = imageFileName;
            }
            
            [formData appendPartWithFileData:imageData
                                        name:name
                                    fileName:fileName
                                    mimeType:[NSString stringWithFormat:@"image/%@", imageType?:@"jpg"]];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        // 上传进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progress) {
                progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
            }
        });
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_isOpenLog) {
            [self logWithSuccessResponse:responseObject url:URL params:parameters];
        }
        
        [[self allSessionTask] removeObject:task];
        
        if (success) {
            success([self tryToParseData:responseObject]);
        }
    
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_isOpenLog) {
            [self logWithFailureError:error url:URL params:parameters];
        }
        
        [[self allSessionTask] removeObject:task];
        
        if (failure) { failure(error); }
        
    }];
    
    if (sessionTask) {
        [[self allSessionTask] addObject:sessionTask];
    }
    
    return sessionTask;
}

#pragma mark - 下载文件

+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL filePath:(NSString *)filePath progress:(HTHttpProgress)progress success:(void (^)(NSString * _Nonnull))success failure:(HHResponseFailure)failure {
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        // 下载进度
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (progress) {
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            }
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        if (filePath && filePath.length > 0) {
            return [NSURL fileURLWithPath:filePath];
        }
        // 拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Download"];
        // 打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 创建Download目录
        BOOL isExist = [fileManager fileExistsAtPath:downloadDir];
        if (!isExist) {
            [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        // 拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        // 返回文件位置的URL路径
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        [[self allSessionTask] removeObject:downloadTask];
        if (failure && error) {
            failure(error);
            
            if (_isOpenLog) {
                [self logWithFailureError:error url:URL params:nil];
            }
            return;
        }

        if (success) {
            success([filePath path]);  /** NSURL->NSString*/
            
            if (_isOpenLog) {
                [self logWithSuccessResponse:nil url:URL params:nil];
            }
        }
        
    }];
    
    // 开始下载
    [downloadTask resume];
    // 添加sessionTask到数组
    if (downloadTask) {
        [[self allSessionTask] addObject:downloadTask];
    }
    
    return downloadTask;
}


#pragma mark - 存储着所有的请求task数组

+ (NSMutableArray *)allSessionTask {
    if (!_allSessionTask) {
        _allSessionTask = [[NSMutableArray alloc] init];
    }
    return _allSessionTask;
}

#pragma mark - 初始化AFHTTPSessionManager相关属性

/// 开始监测网络状态
+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/// 所有的HTTP请求共享一个AFHTTPSessionManager
+ (void)initialize {
    _sessionManager = [AFHTTPSessionManager manager];
    _sessionManager.requestSerializer.timeoutInterval = 30.f;
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    AFJSONResponseSerializer *response = [AFJSONResponseSerializer serializer];
    response.removesKeysWithNullValues = YES;
    _sessionManager.responseSerializer = response;
}

#pragma mark - 重置AFHTTPSessionManager相关属性

+ (void)setAFHTTPSessionManagerProperty:(void (^)(AFHTTPSessionManager *))sessionManager {
    if (sessionManager) { sessionManager(_sessionManager); };
}

+ (void)setRequestSerializer:(HHRequestSerializer)requestSerializer {
    _sessionManager.requestSerializer = (requestSerializer == HHRequestSerializerHTTP) ? [AFHTTPRequestSerializer serializer] : [AFJSONRequestSerializer serializer];
}

+ (void)setResponseSerializer:(HHResponseSerializer)responseSerializer {
    _sessionManager.responseSerializer = (responseSerializer == HHResponseSerializerHTTP) ? [AFHTTPResponseSerializer serializer] : [AFJSONResponseSerializer serializer];
}

+ (void)setRequestTimeoutInterval:(NSTimeInterval)time {
    _sessionManager.requestSerializer.timeoutInterval = time;
}

+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:field];
}

+ (void)openNetworkActivityIndicator:(BOOL)open {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:open];
}

+ (void)setSecurityPolicyWithCerPath:(NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName {
    
    if (!cerPath) {
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = validatesDomainName;
        _sessionManager.securityPolicy = securityPolicy;
        
        return;
    }
    
    NSData *cerData = [NSData dataWithContentsOfFile:cerPath];
    // 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // 如果需要验证自建证书(无效证书)，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    // 是否需要验证域名，默认为YES;
    securityPolicy.validatesDomainName = validatesDomainName;
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    
    [_sessionManager setSecurityPolicy:securityPolicy];
    

}

#pragma mark - log

+ (void)logWithSuccessResponse:(id)response url:(NSString *)url params:(id)params {
    HHLog(@"\nRequest success, URL:\n%@\n params:\n%@\n response:\n%@\n\n", [self generateGETAbsoluteURL:url params:params], params, [self tryToParseData:response]);
}

+ (void)logWithFailureError:(NSError *)error url:(NSString *)url params:(id)params {
    NSString *format = @" params: ";
    if (params == nil || ![params isKindOfClass:[NSDictionary class]]) {
        format = @"";
        params = @"";
    }
    
    if ([error code] == NSURLErrorCancelled) {
        HHLog(@"\nRequest was canceled mannully, URL: \n%@ %@%@\n\n",
                  [self generateGETAbsoluteURL:url params:params],
                  format,
                  params);
    } else {
        HHLog(@"\nRequest error, URL: \n%@ %@%@\n errorInfos:%@\n\n",
                  [self generateGETAbsoluteURL:url params:params],
                  format,
                  params,
                  [error localizedDescription]);
    }
}

#pragma mark - 解析responseData
/// 尝试解析成JSON
+ (id)tryToParseData:(id)responseData {
    if ([responseData isKindOfClass:[NSData class]]) {
        
        NSError *error = nil;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
        
        if (error) {
            // 解析字典错误时，解析成字符串
            NSString *string = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            return string;
        }
        
        return response;
    }
    
    return responseData;
}

#pragma makr - 生成GET绝对的URL地址 仅对一级字典结构起作用
+ (NSString *)generateGETAbsoluteURL:(NSString *)url params:(id)params {
    if (params == nil || ![params isKindOfClass:[NSDictionary class]] || [params count] == 0) {
        return url;
    }
    
    NSString *queries = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            continue;
        } else if ([value isKindOfClass:[NSArray class]]) {
            continue;
        } else if ([value isKindOfClass:[NSSet class]]) {
            continue;
        } else {
            queries = [NSString stringWithFormat:@"%@%@=%@&",
                       (queries.length == 0 ? @"&" : queries),
                       key,
                       value];
        }
    }
    
    if (queries.length > 1) {
        queries = [queries substringToIndex:queries.length - 1];
    }
    
    if (([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) && queries.length > 1) {
        if ([url rangeOfString:@"?"].location != NSNotFound
            || [url rangeOfString:@"#"].location != NSNotFound) {
            url = [NSString stringWithFormat:@"%@%@", url, queries];
        } else {
            queries = [queries substringFromIndex:1];
            url = [NSString stringWithFormat:@"%@?%@", url, queries];
        }
    }
    
    return url.length == 0 ? queries : url;
}

@end
