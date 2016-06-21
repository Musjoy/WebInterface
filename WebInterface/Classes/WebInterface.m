//
//  WebInterface.m
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "WebInterface.h"
#import "MJWebService.h"
#import "DBRespond.h"
#import "ResultModel.h"
#ifdef MODULE_DEVICE_HELPER
#import "MJDeviceHelper.h"
#else
#include <sys/sysctl.h>
#endif

static NSMutableDictionary *s_dicRequests = nil;
static NSString *s_serverActionUrl = nil;
static long s_requestCount = 0;
static DBRequest *s_requestModel = nil;

#define kAppSys @1          // 客户端类型 (1-iOS, 2-Andorid)
#ifdef DEBUG
#define kAppState @0        // app状态 0-开发状态 1-发布状态
#else
#define kAppState @1
#endif



@implementation WebInterface

#pragma mark -

+ (void)cancelRequestWith:(NSString *)requestId
{
    if (s_dicRequests) {
        if ([s_dicRequests objectForKey:requestId]) {
            [s_dicRequests removeObjectForKey:requestId];
        }
    }
}

+ (void)cancelAllRequest
{
    if (s_dicRequests) {
        [s_dicRequests removeAllObjects];
    }
}

#pragma mark - 统一接口

/** 统一接口请求 */
+ (NSString *)startRequest:(NSString *)action
                  describe:(NSString *)describe
                      body:(NSDictionary *)body
               returnClass:(Class)returnClass
                completion:(ActionCompleteBlock)completion
{
    if (s_dicRequests == nil) {
        s_dicRequests = [[NSMutableDictionary alloc] init];
#ifdef kServerAction
        s_serverActionUrl = kServerAction;
#else
#warning @"kServerAction is not define!"
#endif
    }
    
    s_requestCount++;
    NSString *uuid = [NSString stringWithFormat:@"%ld", s_requestCount];
    [s_dicRequests setObject:[NSNumber numberWithBool:YES] forKey:uuid];
    
    // 拼接请求url
    NSString *pathUrl = [NSString stringWithFormat:@"%@%@", s_serverActionUrl, action];

    // 拼接发送数据
    NSDictionary *aSendDic = [self getWholeRequestData:body andMethod:action];
    
    BOOL isRequestStart = [MJWebService startPost:pathUrl
                                             body:aSendDic
                                          success:^(id respond)
                           {
                               
                               NSError *err = nil;
                               DBRespond *aRespond = nil;
                               @try {
                                   // 解析json
                                   if ([respond isKindOfClass:[NSDictionary class]]) {
                                       aRespond = [[DBRespond alloc] initWithDictionary:respond error:&err];
                                   } else {
                                       aRespond = [[DBRespond alloc] initWithString:respond error:&err];
                                   }
                               }
                               @catch (NSException *exception) {
                                   err = [self errorWithCode:-500 message:@"JSON Parse Error"];
                               }
                               @finally {
                                   if (err) {
                                       // 数据解析错误，出现该错误说明与服务器接口对应出了问题
                                       LogDebug(@"...>>>...JSON Parse Error: %@\n", err);
                                       [self failedWithError:err describe:describe callback:completion];
                                   } else {
                                       [self succeedWithResult:aRespond describe:describe returnClass:returnClass callback:completion];
                                   }
                               }
                           } failure:^(NSError *error)
                           {
                               LogError(@"%@", error);
                               [self failedWithError:error describe:describe callback:completion];
                           }];
    if (isRequestStart) {
        return uuid;
    }
    return nil;
}


#pragma mark - Private

// 拼装 request data
+ (NSDictionary *)getWholeRequestData:(NSDictionary *)requestBody andMethod:(NSString *)theMethod
{
    // 拼接发送数据
    DBRequest *aRequestModel = [self getRequestModel];
    NSDictionary *aSendDic = nil;
    @synchronized(aRequestModel) {
        aRequestModel.mac = [[NSUUID UUID] UUIDString];
        aRequestModel.head.method = theMethod;
        aRequestModel.body = requestBody;
        aSendDic = [NSDictionary dictionaryWithObject:[aRequestModel toJSONString] forKey:@"jsonData"];
    }
    return aSendDic;
}

+ (DBRequest *)getRequestModel
{
    if (s_requestModel == nil) {
        s_requestModel = [[DBRequest alloc] init];
        DBRequestHeader *head = [[DBRequestHeader alloc] init];
#ifdef MODULE_DEVICE_HELPER
        head.deviceUUID = [MJDeviceHelper getDeviceID];
        head.deviceVersion = [MJDeviceHelper getDeviceVersion];
        head.sysVersion = [MJDeviceHelper getCurrentSysVersion];
#else
        head.deviceUUID = [[UIDevice currentDevice].identifierForVendor UUIDString];
        head.sysVersion = [@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]];
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
        free(machine);
        head.deviceVersion = platform;
#endif
        
        head.sysType = (NSNumber<DBInt> *)kAppSys;
        head.appVersion = kClientVersion;
        head.appState = (NSNumber<DBInt> *)kAppState;
        s_requestModel.head = head;
    }
    return s_requestModel;
}

// 从DBRespond转换成ResultModel
+ (ResultModel *)getResultWithRespond:(DBRespond *)aRespond
                          returnClass:(Class)returnClass
                             andError:(NSError**)err
{
    
    @try {
        NSDictionary *body = [aRespond.body copy];
        NSString *code = body[@"code"];
        if (code == nil) {
            LogError(@"...>>> body格式错误 : %@", body.description);
            *err = [[NSError alloc] initWithDomain:@"Body格式错误" code:-501 userInfo:nil];
            return nil;
        }
        ResultModel *result = [[ResultModel alloc] init];
        result.code = code;
        result.message = body[@"message"];
        // 如果状态码不为0,则直接返回,不再解析后面的数据
        if (![result.code isEqualToString:@"000000"]) {
            result.result = nil;
            return result;
        }
        
        id bodyResult = body[@"result"];
        if (returnClass == nil || bodyResult == nil) {
            result.result = body[@"result"];
            return result;
        }
        
        if ([bodyResult isKindOfClass:[NSDictionary class]]) {
            // result返回字典类型数据
            LogInfo(@"[NSDictionary class]");
            if (bodyResult) {
                result.result = [[returnClass alloc] initWithDictionary:bodyResult error:err];
            }
        } else if ([bodyResult isKindOfClass:[NSString class]]) {
            // result返回字串类型数据
            LogInfo(@"[NSString class]");
            if ([bodyResult isEqualToString:@""]) {
                result.result = nil;
            } else {
                result.result = [body objectForKey:@"result"];
            }
        } else if ([bodyResult isKindOfClass:[NSNumber class]]) {
            LogInfo(@"[NSNumber class]");
            result.result = [body objectForKey:@"result"];
        } else if ([bodyResult isKindOfClass:[NSArray class]]) {
            // result返回数组类型数据
            LogInfo(@"[NSArray class]");
            NSArray *array = bodyResult;
            if (array != nil && array.count > 0) {
                NSMutableArray *resultArr = [[NSMutableArray alloc] init];
                for (int i = 0; i < array.count; i++) {
                    NSDictionary *dic = [array objectAtIndex:i];
                    [resultArr addObject:[[returnClass alloc] initWithDictionary:dic error:err]];
                }
                result.result = resultArr;
            } else {
                result.result = nil;
            }
        }
        return result;
    } @catch (NSException *exception) {
        LogDebug(@"%@", exception);
        *err = [[NSError alloc] initWithDomain:exception.reason code:-500 userInfo:exception.userInfo];
        return nil;
    } @finally {
        //
    }
}

#pragma mark -

/**
 *	@brief	请求成功数据处理
 *
 *	@param 	result      请求成功后返回的结构
 *	@param 	describe 	请求描述
 *	@param 	completion 	请求完成回调
 *
 *	@return	void
 */
+ (void)succeedWithResult:(DBRespond *)respond
                 describe:(NSString *)describe
              returnClass:(Class)returnClass
                 callback:(ActionCompleteBlock)completion

{
    if (completion == NULL) {
        completion = ^(BOOL isSucceed, NSString *message, id data) {};
    }
    NSNumber *code = respond.head[@"code"];
    if (code.intValue > 0) {
        NSString *errMessage = respond.head[@"message"];
        LogError(@"...>>> 网络请求错误: method = %@, %@\n", respond.head[@"method"], respond.head[@"message"]);
        if (errMessage.length == 0) {
            errMessage = sNetworkErrorMsg;
        }
        NSError *err = [self errorWithCode:[code integerValue] message:errMessage];
        [self failedWithError:err describe:describe callback:completion];
        return;
    }
    NSError *err = nil;
    ResultModel *result = [self getResultWithRespond:respond returnClass:returnClass andError:&err];
    if (err) {
        LogError(@"...>>> JSON Parse Error: %@\n", err);
        NSString *errMessage = @"Receive unsupported data!";
        NSError *err = [self errorWithCode:[code integerValue] message:errMessage];
        [self failedWithError:err describe:describe callback:completion];
        return;
    }
    if (![result.code isEqualToString:@"000000"]) {
        NSError *err = [self errorWithCode:[code integerValue] message:result.message];
        [self failedWithError:err describe:describe callback:completion];
    } else {
        completion(YES, [describe stringByAppendingString:@" succeed"], result.result);
    }
}

/**
 *	@brief	请求失败数据处理
 *
 *	@param 	error 	请求失败的错误
 *	@param 	describe 	请求描述
 *	@param 	completion 	请求完成回调
 *
 *	@return	void
 */
+ (void)failedWithError:(NSError *)error
               describe:(NSString *)describe
               callback:(ActionCompleteBlock)completion

{
    if (completion == nil) {
        completion = ^(BOOL isSucceed, NSString *message, id data) {};
    }
    if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork]) {
        NSString *errMessage = @"";
        switch (error.code) {
            case kCFURLErrorUnknown:
                errMessage = @"网络错误";
                break;
            case kCFURLErrorCancelled:
                errMessage = @"网络连接被取消";
                break;
            case kCFURLErrorBadURL:
                errMessage = @"错误的连接地址";
                break;
            case kCFURLErrorTimedOut:
                errMessage = @"网络超时";
                break;
            case kCFURLErrorUnsupportedURL:
                errMessage = @"网络地址不被支持";
                break;
            case kCFURLErrorCannotFindHost:
            case kCFURLErrorCannotConnectToHost:
            case kCFURLErrorNetworkConnectionLost:
            case kCFURLErrorDNSLookupFailed:
            case kCFURLErrorNotConnectedToInternet:
            case kCFURLErrorRedirectToNonExistentLocation:
                errMessage = @"无法连接到服务器";
                break;
            case kCFURLErrorBadServerResponse:
            case kCFURLErrorHTTPTooManyRedirects:
                errMessage = @"网络错误";
                break;
            case kCFURLErrorResourceUnavailable:
                errMessage = @"无效的资源";
                break;
            case kCFURLErrorUserCancelledAuthentication:
                errMessage = @"网络错误";
                break;
            case kCFURLErrorUserAuthenticationRequired:
                errMessage = @"网络错误";
                break;
            case kCFURLErrorZeroByteResource:
                errMessage = @"网络错误";
                break;
            case kCFURLErrorCannotDecodeRawData:
                errMessage = @"网络错误";
                break;
            case kCFURLErrorCannotDecodeContentData:
                errMessage = @"网络错误";
                break;
            case kCFURLErrorCannotParseResponse:
                errMessage = @"无法解析响应";
                break;
            case kCFURLErrorInternationalRoamingOff:
                errMessage = @"网络漫游关闭";
                break;
            case kCFURLErrorCallIsActive:
                errMessage = @"正在打电话中";
                break;
            case kCFURLErrorDataNotAllowed:
                errMessage = @"数据不被允许";
                break;
            case kCFURLErrorRequestBodyStreamExhausted:
                errMessage = @"网络错误";
                break;
            case kCFURLErrorFileDoesNotExist:
                errMessage = @"文件不存在";
                break;
            case kCFURLErrorFileIsDirectory:
                errMessage = @"请求文件是文件夹";
                break;
            case kCFURLErrorNoPermissionsToReadFile:
                errMessage = @"无权读取文件";
                break;
            case kCFURLErrorDataLengthExceedsMaximum:
                errMessage = @"数据长度超过最大值";
                break;
            default:
                break;
        }
        error = [NSError errorWithDomain:kErrorDomain code:error.code userInfo:@{
                                                                                 NSLocalizedDescriptionKey:sNetworkErrorMsg,
                                                                                 NSLocalizedFailureReasonErrorKey:errMessage
                                                                                 }];
        LogError(@"...>>> 网络错误 : %@", errMessage);
    }

    NSString *message = [describe stringByAppendingString:@" failed!"];
    
    completion(NO, message, error);
}

+ (NSError *)errorWithCode:(NSInteger)errCode message:(NSString *)message
{
    return [NSError errorWithDomain:kErrorDomain code:errCode userInfo:@{
                                                                         NSLocalizedDescriptionKey:message,
                                                                         NSLocalizedFailureReasonErrorKey:message
                                                                         }];
}


@end
