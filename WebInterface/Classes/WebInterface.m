//
//  WebInterface.m
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "WebInterface.h"
#import "MJWebService.h"
#ifdef MODULE_DEVICE_HELPER
#import "MJDeviceHelper.h"
#else
#include <sys/sysctl.h>
#endif
#ifdef MODULE_FILE_SOURCE
#import "FileSource.h"
#endif


static NSMutableDictionary *s_dicRequests = nil;
static NSString *s_serverActionUrl = nil;
static long s_requestCount = 0;
static NSMutableDictionary *s_requestModel = nil;
static MJRequestHeader *s_requestHeaderModel = nil;

static NSMutableDictionary *s_dicServerAPIs = nil;
static NSCache *s_cacheServerAPIs = nil;


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

+ (NSString *)startRequest:(NSString *)action
                  describe:(NSString *)describe
                      body:(NSDictionary *)body
                completion:(ActionCompleteBlock)completion
{
    return [self startRequest:action describe:describe body:body returnClass:nil completion:completion];
}

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
#warning @"kServerAction is not defined!"
#endif
    }
    
    s_requestCount++;
    NSString *uuid = [NSString stringWithFormat:@"%ld", s_requestCount];
    [s_dicRequests setObject:[NSNumber numberWithBool:YES] forKey:uuid];
    
    // 拼接请求url
    NSString *pathUrl = [NSString stringWithFormat:@"%@%@", s_serverActionUrl, action];

    // 拼接发送数据
    NSDictionary *aSendDic = [self getWholeRequestData:body];
    
    LogInfo(@"Server request : \n\n%@\n", pathUrl);
    LogDebug(@"Server request Data : %@\n", aSendDic);
    
    BOOL isRequestStart = [MJWebService startPost:pathUrl
                                             body:aSendDic
                                          success:^(id respond)
                           {
                               LogInfo(@"===>>>  Respond for %@ = \n%@", action, respond);
                               NSError *err = nil;
                               NSDictionary *aRespond = nil;
                               @try {
                                   // 解析json
                                   if ([respond isKindOfClass:[NSDictionary class]]) {
                                       aRespond = respond;
                                   } else if ([respond isKindOfClass:[NSString class]]){
                                       // 解析字符串
                                       aRespond = objectFromString(respond, &err);
                                   } else {
                                       // 受到不支持的数据
                                       err =  [self errorWithCode:-400 message:@"Receive unsupport data!"];
                                   }
                                   if (err) {
                                       [self failedWithError:err describe:describe callback:completion];
                                       return;
                                   }
                                   // 判断网络请求状态
                                   NSNumber *code = respond[@"code"];
                                   // 存在code，判断code值，不存在，默认成功
                                   if (code) {
                                       if (code.intValue != 0) {
                                           NSString *errMessage = respond[@"message"];
                                           LogError(@"...>>>...\n\n 网络请求错误: \n{\n\tmethod = %@, %@\n}\n.", respond[@"method"], respond[@"message"]);
                                           if (errMessage.length == 0) {
                                               errMessage = sNetworkErrorMsg;
                                           }
                                           err = [self errorWithCode:[code integerValue] message:errMessage];
                                           [self failedWithError:err describe:describe callback:completion];
                                           return;
                                       }
                                   } else {
                                       // 这里不存在code暂时默认为成功
                                   }

                                   // 解析网络数据
                                   id result = aRespond[@"result"];
                                   if (result == nil) {
                                       result = aRespond;
                                   }
#ifdef MODULE_DB_MODEL
                                   if (returnClass != nil) {
                                       result = [[returnClass alloc] initWithDictionary:result error:&err];
                                       if (err) {
                                           [self failedWithError:err describe:describe callback:completion];
                                           return;
                                       }
                                   }
#endif
                                   completion(YES, [describe stringByAppendingString:@" succeed"], result);
                               }
                               @catch (NSException *exception) {
                                   err = [self errorWithCode:-500 message:@"JSON Parse Error"];
                               }
                               @finally {
                                   if (err) {
                                       // 数据解析错误，出现该错误说明与服务器接口对应出了问题
                                       LogDebug(@"...>>>...JSON Parse Error: %@\n", err);
                                       [self failedWithError:err describe:describe callback:completion];
                                   }
                               }
                           } failure:^(NSError *error)
                           {
                               LogDebug(@"%@", error.userInfo[[error.domain stringByAppendingString:@".error.data"]]);
                               [self failedWithError:error describe:describe callback:completion];
                           }];
    if (isRequestStart) {
        return uuid;
    }
    return nil;
}


#ifdef MODULE_WEB_INTERFACE_LIST_REQUEST
+ (NSString *)fetchDataListWithModel:(MJListRequest *)requestModel completion:(ActionCompleteBlock)completion
{
    if (completion == NULL) {
        completion = ^(BOOL isSucceed, NSString *message, id data) {};
    }
    NSString *describe = requestModel.listDecs ?: @"Get data list";
    
    NSString *chechResult = [requestModel chechContent];
    if (chechResult.length > 0) {
        LogError(@"%@", chechResult);
        completion(NO, @"Get data list failed", nil);
        return nil;
    }
    Class returnClass = requestModel.receiveClass;
    Class theReturnClass = [MJDataList class];
    if (requestModel.receiveClass && [requestModel.receiveClass isSubclassOfClass:[MJDataList class]]) {
        theReturnClass = returnClass;
    }
    NSMutableDictionary *sendDic = [NSMutableDictionary dictionaryWithDictionary:requestModel.requestParam];
    [sendDic setObject:[NSNumber numberWithInteger:requestModel.pageNo] forKey:@"pageNo"];
    [sendDic setObject:[NSNumber numberWithInteger:requestModel.pageSize] forKey:@"pageSize"];
    
    return [self startRequest:requestModel.serverAction
                     describe:describe
                         body:sendDic
#ifdef MODULE_DB_MODEL
                  returnClass:theReturnClass
#endif
                   completion:^(BOOL isSucceed, NSString *message, id data)
            {
                if (isSucceed) {
                    // 处理result
                    NSError *err = nil;
                    NSMutableArray *arr = [[NSMutableArray alloc] init];
#ifdef MODULE_DB_MODEL
                    MJDataList *theDataList = data;
#else
                    MJDataList *theDataList = [[theReturnClass alloc] initWithDictionary:data];
#endif
                    @try {
                        if (isSucceed) {
                            // 将dataList数据转到theDataList中
                            NSArray *aDataList = [theDataList valueForKey:@"dataList"];
#ifdef MODULE_DB_MODEL
                            if (aDataList && [aDataList isKindOfClass:[NSArray class]]) {
                                if (returnClass && ![returnClass isSubclassOfClass:[MJDataList class]]) {
                                    for (NSDictionary *dic in aDataList) {
                                        DBModel *model = [[returnClass alloc] initWithDictionary:dic error:&err];
                                        [arr addObject:model];
                                    }
                                } else {
                                    [arr addObjectsFromArray:aDataList];
                                }
                            }
#else
                            arr = aDataList;
#endif
                        }
                    }
                    @catch (NSException *exception) {
                        LogError(@"exception: %@ ==== Error: %@", exception, err);
                    }
                    @finally {
                        theDataList.theDataList = arr;
                        completion(isSucceed, message, theDataList);
                    }
                }
                else {
                    completion(isSucceed, message, data);
                }
            }];
    
}
#endif


+ (MJRequestHeader *)getRequestHeaderModel
{
    
    if (s_requestHeaderModel == nil) {
        s_requestHeaderModel = [[MJRequestHeader alloc] init];
        s_requestHeaderModel.deviceName = [UIDevice currentDevice].name;
#ifdef MODULE_DEVICE_HELPER
        s_requestHeaderModel.deviceUUID = [MJDeviceHelper getDeviceID];
        s_requestHeaderModel.deviceVersion = [MJDeviceHelper getDeviceVersion];
        s_requestHeaderModel.sysVersion = [MJDeviceHelper getCurrentSysVersion];
#else
        s_requestHeaderModel.deviceUUID = [[UIDevice currentDevice].identifierForVendor UUIDString];
        s_requestHeaderModel.sysVersion = [@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]];
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
        free(machine);
        s_requestHeaderModel.deviceVersion = platform;
#endif
        
        s_requestHeaderModel.sysType = kAppSys;
#ifdef DEBUG
        s_requestHeaderModel.appVersion = kClientVersion;
#else
        s_requestHeaderModel.appVersion = kClientVersionShort;
#endif
        s_requestHeaderModel.appState = kAppState;
    }
    return s_requestHeaderModel;
}

+ (void)resetRequestMode
{
    s_requestModel = nil;
}

#pragma mark - Private

// 拼装 request data
+ (NSDictionary *)getWholeRequestData:(NSDictionary *)requestBody
{
    // 拼接发送数据
    NSMutableDictionary *aRequestModel = [self getRequestModel];
    NSDictionary *aSendDic = nil;
    @synchronized(aRequestModel) {
        aRequestModel[@"mac"] = [[NSUUID UUID] UUIDString];
        aRequestModel[@"body"] = requestBody;
        aSendDic = aRequestModel;
    }
    return aSendDic;
}

+ (NSMutableDictionary *)getRequestModel
{
    if (s_requestModel == nil) {
        s_requestModel = [[NSMutableDictionary alloc] init];
        MJRequestHeader *requstHeader = [self getRequestHeaderModel];
        NSDictionary *aDicHeader = nil;
        if (requstHeader.deviceId) {
            aDicHeader = @{@"deviceId":requstHeader.deviceId};
        } else {
            aDicHeader = [requstHeader toDictionary];
        }
        s_requestModel[@"head"] = aDicHeader;
    }
    return s_requestModel;
}

#pragma mark -


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


#pragma mark - ServerAPI

+ (NSString *)latestActionFor:(NSString *)aAction
{
    if (s_dicServerAPIs == nil) {
        s_dicServerAPIs = [getFileData(FILE_NAME_SERVER_APIS) mutableCopy];
        if (s_dicServerAPIs == nil) {
            s_dicServerAPIs = [[NSMutableDictionary alloc] init];
        }
        s_cacheServerAPIs = [[NSCache alloc] init];
    }
    
    NSString *newAction = [s_cacheServerAPIs objectForKey:aAction];
    if (newAction.length > 0) {
        return newAction;
    }
    
    newAction = [s_dicServerAPIs objectForKey:aAction];;
    if (newAction.length > 0) {
        NSNumber *deviceId = [[self getRequestModel] valueForKeyPath:@"head.deviceId"];
        if ([deviceId longLongValue] > 0) {
            if ([newAction rangeOfString:@"?"].length == 0) {
                newAction = [newAction stringByAppendingFormat:@"?deviceId=%lld", deviceId.longLongValue];
            } else {
                newAction = [newAction stringByAppendingFormat:@"&deviceId=%lld", deviceId.longLongValue];
            }
            [s_cacheServerAPIs setObject:newAction forKey:aAction];
        }
    } else {
        newAction = aAction;
    }
    return newAction;
}

+ (void)serverGet:(NSString *)action completion:(ActionCompleteBlock)completion
{
    if (completion == NULL) {
        completion = ^(BOOL isSucceed, NSString *message, id data) {};
    }
#ifdef kServerUrl
    NSString *newAction = [self latestActionFor:action];
    NSString *serverUrl = [NSString stringWithFormat:@"%@/%@", kServerUrl, newAction];
    [MJWebService startGet:serverUrl body:nil success:^(id respond) {
        completion(YES, @"", respond);
    } failure:^(NSError *error) {
        completion(NO, @"", error);
    }];
#else
    completion(NO, @"Server url not set", nil);
#endif
}


@end
