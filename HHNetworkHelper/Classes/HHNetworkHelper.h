//
//  HHNetworkHelper.h
//  Henry
//
//  Created by Henry on 2020/5/13.
//  Copyright © 2020 Henry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "HHNetworkCache.h"


NS_ASSUME_NONNULL_BEGIN

#ifndef kIsNetwork
#define kIsNetwork     [HHNetworkHelper isNetwork]  // 一次性判断是否有网的宏
#endif

#ifndef kIsWWANNetwork
#define kIsWWANNetwork [HHNetworkHelper isWWANNetwork]  // 一次性判断是否为手机网络的宏
#endif

#ifndef kIsWiFiNetwork
#define kIsWiFiNetwork [HHNetworkHelper isWiFiNetwork]  // 一次性判断是否为WiFi网络的宏
#endif

typedef NS_ENUM(NSUInteger, HHNetworkStatusType) {
    /// 未知网络
    HHNetworkStatusUnknown,
    /// 无网络
    HHNetworkStatusNotReachable,
    /// 手机网络
    HHNetworkStatusReachableViaWWAN,
    /// WIFI网络
    HHNetworkStatusReachableViaWiFi
};

typedef NS_ENUM(NSUInteger, HHRequestSerializer) {
    /// 设置请求数据为JSON格式
    HHRequestSerializerJSON,
    /// 设置请求数据为二进制格式
    HHRequestSerializerHTTP,
};

typedef NS_ENUM(NSUInteger, HHResponseSerializer) {
    /// 设置响应数据为JSON格式
    HHResponseSerializerJSON,
    /// 设置响应数据为二进制格式
    HHResponseSerializerHTTP,
};

/// 响应成功
typedef void(^HHResponseSuccess)(id response);

/// 响应失败
typedef void(^HHResponseFailure)(NSError *error);

/// 缓存数据
typedef void(^HHResponseCache)(id response);

/// 上传或者下载的进度, Progress.completedUnitCount:当前大小 - Progress.totalUnitCount:总大小
typedef void (^HTHttpProgress)(int64_t completedCount, int64_t totalCount);

/// 网络状态的Block
typedef void(^HHNetworkStatus)(HHNetworkStatusType status);

@interface HHNetworkHelper : NSObject

/// 实时获取网络状态,通过Block回调实时获取(此方法可多次调用)
+ (void)networkStatusWithBlock:(nullable HHNetworkStatus)networkStatus;

/// 有网YES, 无网:NO
+ (BOOL)isNetwork;

/// 手机网络:YES, 反之:NO
+ (BOOL)isWWANNetwork;

/// WiFi网络:YES, 反之:NO
+ (BOOL)isWiFiNetwork;

/// 取消所有HTTP请求
+ (void)cancelAllRequest;

/// 取消指定URL的HTTP请求
+ (void)cancelRequestWithURL:(NSString *)URL;

/// 开启日志打印 (Debug级别)
+ (void)openLog;

/// 关闭日志打印,默认关闭
+ (void)closeLog;

/**
 @param URL             请求地址
 @param parameters      请求参数
 @param responseCache   缓存数据的回调
 @param success         请求成功的回调
 @param failure         请求失败的回调
 @return 返回的对象可取消请求，调用cancel方法
 */

/// GET请求 无缓存
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(nullable id)parameters
                           success:(nullable HHResponseSuccess)success
                           failure:(nullable HHResponseFailure)failure;

/// GET请求 自动缓存
+ (__kindof NSURLSessionTask *)GET:(NSString *)URL
                        parameters:(nullable id)parameters
                     responseCache:(nullable HHResponseCache)responseCache
                           success:(nullable HHResponseSuccess)success
                           failure:(nullable HHResponseFailure)failure;

/// POST请求 无缓存
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(nullable id)parameters
                            success:(nullable HHResponseSuccess)success
                            failure:(nullable HHResponseFailure)failure;

/// POST请求 自动缓存
+ (__kindof NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(nullable id)parameters
                      responseCache:(nullable HHResponseCache)responseCache
                            success:(nullable HHResponseSuccess)success
                            failure:(nullable HHResponseFailure)failure;


/// 上传文件
/// @param URL 请求地址
/// @param parameters 请求参数
/// @param name 文件对应服务器上的字段
/// @param filePath 文件本地的沙盒路径
/// @param mimeType mimeType
/// @param progress 上传进度信息
/// @param success 请求成功的回调
/// @param failure 请求失败的回调
/// @return 返回的对象可取消请求,调用cancel方法
+ (__kindof NSURLSessionTask *)uploadFileWithURL:(NSString *)URL
                                      parameters:(nullable id)parameters
                                            name:(nullable NSString *)name
                                        filePath:(nullable NSString *)filePath
                                        mimeType:(nullable NSString *)mimeType
                                        progress:(nullable HTHttpProgress)progress
                                         success:(nullable HHResponseSuccess)success
                                         failure:(nullable HHResponseFailure)failure;


/// 上传单/多张图片
/// @param URL 请求地址
/// @param parameters 请求参数
/// @param name 图片对应服务器上的字段
/// @param images  图片数组
/// @param fileNames 图片文件名数组, 可以为nil，数组内的文件名默认为当前日期时间"yyyyMMddHHmmss"
/// @param imageScale 图片文件压缩比 范围 (0.f ~ 1.f)
/// @param imageType 图片文件的类型,例:png、jpg(默认类型)....
/// @param progress 上传进度信息
/// @param success 请求成功的回调
/// @param failure 请求失败的回调
/// @return 返回的对象可取消请求,调用cancel方法
+ (__kindof NSURLSessionTask *)uploadImagesWithURL:(NSString *)URL
                                        parameters:(nullable id)parameters
                                              name:(nullable NSString *)name
                                            images:(NSArray<UIImage *> *)images
                                         fileNames:(nullable NSArray<NSString *> *)fileNames
                                        imageScale:(CGFloat)imageScale
                                         imageType:(nullable NSString *)imageType
                                          progress:(nullable HTHttpProgress)progress
                                           success:(nullable HHResponseSuccess)success
                                           failure:(nullable HHResponseFailure)failure;


/// 下载文件
/// @param URL 请求地址
/// @param filePath 文件存储路径(默认存储目录为Download)
/// @param progress  文件下载的进度信息
/// @param success 下载成功的回调(回调参数filePath:文件的路径)
/// @param failure 下载失败的回调
/// @return 返回NSURLSessionDownloadTask实例，可用于暂停继续，暂停调用suspend方法，开始下载调用resume方法
+ (__kindof NSURLSessionTask *)downloadWithURL:(NSString *)URL
                                      filePath:(nullable NSString *)filePath
                                      progress:(nullable HTHttpProgress)progress
                                       success:(nullable void(^)(NSString *filePath))success
                                       failure:(nullable HHResponseFailure)failure;


#pragma mark - 设置AFHTTPSessionManager相关属性
#pragma mark 注意: 因为全局只有一个AFHTTPSessionManager实例,所以以下设置方式全局生效

/**
 (注意：调用此方法时在要导入AFNetworking.h头文件,否则可能会报找不到AFHTTPSessionManager的❌)
 */

/// 在开发中,如果以下的设置方式不满足项目的需求,就调用此方法获取AFHTTPSessionManager实例进行自定义设置
/// @param sessionManager  AFHTTPSessionManager的实例
+ (void)setAFHTTPSessionManagerProperty:(void(^)(AFHTTPSessionManager *sessionManager))sessionManager;


/// 设置网络请求参数的格式:默认为二进制格式
/// @param requestSerializer HHRequestSerializerJSON(JSON格式), HHRequestSerializerHTTP(二进制格式)
+ (void)setRequestSerializer:(HHRequestSerializer)requestSerializer;


/// 设置服务器响应数据格式:默认为JSON格式
/// @param responseSerializer HHResponseSerializerJSON(JSON格式), HHResponseSerializerHTTP(二进制格式)
+ (void)setResponseSerializer:(HHResponseSerializer)responseSerializer;


/// 设置请求超时时间:默认为30S
/// @param time 时长
+ (void)setRequestTimeoutInterval:(NSTimeInterval)time;


/// 设置请求头
/// @param value value
/// @param field HeaderField
+ (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;


/// 是否打开网络状态转圈菊花:默认打开
/// @param open YES(打开), NO(关闭)
+ (void)openNetworkActivityIndicator:(BOOL)open;


/**
 如果证书的域名与请求的域名不一致，需设置为NO; 即服务器使用其他可信任机构颁发
 的证书，也可以建立连接，这个非常危险, 建议打开.validatesDomainName=NO, 主要用于这种情况:客户端请求的是子域名, 而证书上的是另外
 一个域名。因为SSL证书上的域名是独立的,假如证书上注册的域名是www.google.com, 那么mail.google.com是无法验证通过的.
 */

/// 配置自建证书的Https请求, 参考链接: http://blog.csdn.net/syg90178aw/article/details/52839103
/// @param cerPath 自建Https证书的路径
/// @param validatesDomainName 是否需要验证域名，默认为YES.
+ (void)setSecurityPolicyWithCerPath:(nullable NSString *)cerPath validatesDomainName:(BOOL)validatesDomainName;


/// 设置缓存额外的参数
/// @param additional 缓存参数
+ (void)setCacheAdditional:(NSString *)additional;

@end

NS_ASSUME_NONNULL_END
