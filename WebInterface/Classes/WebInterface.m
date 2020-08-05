//
//  WebInterface.m
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "WebInterface.h"
#import <MJWebService/MJWebService.h>
#import HEADER_LOCALIZE
#import HEADER_SERVER_URL
#import HEADER_JSON_GENERATE
#ifdef  MODULE_DEVICE
#import <MJDevice/MJDevice.h>
#else
#include <sys/sysctl.h>
#endif
#import HEADER_FILE_SOURCE
#ifdef  MODULE_DB_MODEL
#import <DBModel/DBModel.h>
#endif
#if __has_include(<AdSupport/AdSupport.h>)
#import <AdSupport/AdSupport.h>
#define MODULE_AD_SUPPORT
#endif

#ifdef  MODULE_SECURITY
#import <MJSecurity/MJSecurity.h>
#endif

static NSMutableDictionary *s_dicRequests = nil;
static NSString *s_serverActionUrl = nil;
static long s_requestCount = 0;
static NSMutableDictionary *s_requestModel = nil;
static MJRequestHeader *s_requestHeaderModel = nil;

static NSMutableDictionary *s_dicServerAPIs = nil;
static NSCache *s_cacheServerAPIs = nil;

/// 成功提示key
static NSString *const kAPITipSucceedKey            = @"API_succeed";
/// 失败提示key
static NSString *const kAPITipFailedKey             = @"API_failed";

#define kAppSys @1          // 客户端类型 (1-iOS, 2-Andorid)
#ifdef DEBUG
#define kAppState @0        // app状态 0-开发状态 1-发布状态
#else
#define kAppState @1
#endif



@implementation WebInterface

+ (void)dataInit
{
    if (s_dicRequests == nil) {
        s_dicRequests = [[NSMutableDictionary alloc] init];
#ifdef kServerAction
        s_serverActionUrl = kServerAction;
#else
#warning @"kServerAction is not defined!"
#endif
#if defined(MODULE_LOCALIZE) && !defined(FUN_WEB_INTERFACE_BLOCK_LOCALIZE)
        // 导入国际化
        NSString *testMessage = locString(kAPITipFailedKey);
        if ([testMessage isEqualToString:kAPITipFailedKey]) {
            [[MJLocalize sharedInstance] addLocalizedStringWith:
             @{
               @"Base" : @{
                       @"API_succeed" : @"%@ succeed!",
                       @"API_failed" : @"%@ failed!"
                       },
               @"zh" : @{
                       @"API_succeed" : @"%@成功!",
                       @"API_failed" : @"%@失败!"
                       }
               }];
        }
#endif
    }
}

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
                    header:(NSDictionary *)header
                      body:(NSDictionary *)body
                completion:(ActionCompleteBlock)completion
{
    return [self startRequest:action describe:describe header:header body:body returnClass:nil completion:completion];
}

+ (NSString *)startRequest:(NSString *)action
                  describe:(NSString *)describe
                      body:(NSDictionary *)body
                completion:(ActionCompleteBlock)completion
{
    return [self startRequest:action describe:describe header:nil body:body returnClass:nil completion:completion];
}

+ (NSString *)startUpload:(NSString *)action
                 describe:(NSString *)describe
                   header:(NSDictionary *)header
                     body:(NSDictionary *)body
                    files:(NSArray *)files
               completion:(ActionCompleteBlock)completion
{
    return [self startUpload:action describe:describe header:header body:body files:files returnClass:nil completion:completion];
}

+ (NSString *)startUpload:(NSString *)action
                 describe:(NSString *)describe
                     body:(NSDictionary *)body
                    files:(NSArray *)files
               completion:(ActionCompleteBlock)completion
{
    return [self startUpload:action describe:describe header:nil body:body files:files returnClass:nil completion:completion];
}

+ (NSString *)startRequest:(NSString *)action
                  describe:(NSString *)describe
                      body:(NSDictionary *)body
               returnClass:(Class)returnClass
                completion:(ActionCompleteBlock)completion
{
    return [self startRequest:action describe:describe header:nil body:body returnClass:returnClass completion:completion];
}

+ (NSString *)startUpload:(NSString *)action
                 describe:(NSString *)describe
                     body:(NSDictionary *)body
                    files:(NSArray *)files
              returnClass:(Class)returnClass
               completion:(ActionCompleteBlock)completion
{
    return [self startUpload:action describe:describe header:nil body:body files:files returnClass:returnClass completion:completion];
}
/** 统一接口请求 */
+ (NSString *)startRequest:(NSString *)action
                  describe:(NSString *)describe
                    header:(NSDictionary *)header
                      body:(NSDictionary *)body
               returnClass:(Class)returnClass
                completion:(ActionCompleteBlock)completion
{
    [self dataInit];
    
    s_requestCount++;
    NSString *uuid = [NSString stringWithFormat:@"%ld", s_requestCount];
    [s_dicRequests setObject:[NSNumber numberWithBool:YES] forKey:uuid];
    
    // 拼接请求url
    NSString *pathUrl = [NSString stringWithFormat:@"%@%@", s_serverActionUrl, action];
    
    // 拼接发送数据
    NSDictionary *aSendDic = [self getWholeRequestData:body];
    
    LogInfo(@"Server request : \n\n%@\n.", pathUrl);
    LogDebug(@"Server request Data : %@\n", aSendDic);
    
#ifdef  MODULE_SECURITY
    // 安全请求
    aSendDic = [self securityRequestBody:body];
#endif
    
    [MJWebService startPost:pathUrl
                     header:header
                       body:aSendDic
                 completion:^(NSURLResponse *response, id responseData, NSError *error)
     {
         if (![s_dicRequests objectForKey:uuid]) {
             return;
         }
         if (!error) {
//             LogInfo(@"===>>>  Respond for %@ = \n%@", action, responseData);
             NSError *err = nil;
             id result = [self getResultFromRespond:responseData returnClass:returnClass error:&err];
             if (err) {
                 [self failedWithError:err describe:describe callback:completion];
             } else {
                 completion(YES, [self succeedWithDescribe:describe], result);
             }
         } else {
             LogDebug(@"%@", error.userInfo[[error.domain stringByAppendingString:@".error.data"]]);
             [self failedWithError:error describe:describe callback:completion];
         }
     }];
    return uuid;
}

+ (NSString *)startUpload:(NSString *)action
                 describe:(NSString *)describe
                   header:(NSDictionary *)header
                     body:(NSDictionary *)body
                    files:(NSArray *)files
              returnClass:(Class)returnClass
               completion:(ActionCompleteBlock)completion
{
    [self dataInit];
    
    s_requestCount++;
    NSString *uuid = [NSString stringWithFormat:@"%ld", s_requestCount];
    [s_dicRequests setObject:[NSNumber numberWithBool:YES] forKey:uuid];
    
    // 拼接请求url
    NSString *pathUrl = [NSString stringWithFormat:@"%@%@", s_serverActionUrl, action];
    
    // 拼接发送数据
    NSDictionary *aSendDic = [self getWholeRequestData:body];
    
    LogInfo(@"Server request : \n\n%@\n.", pathUrl);
    LogDebug(@"Server request Data : %@\n", aSendDic);
    
#ifdef  MODULE_SECURITY
    // 安全请求
    aSendDic = [self securityRequestBody:body];
#endif
    
    [MJWebService startUploadFiles:pathUrl
                            header:header
                              body:aSendDic
                             files:files
                        completion:^(NSURLResponse *response, id responseData, NSError *error)
     {
         if (!error) {
//             LogInfo(@"===>>>  Respond for %@ = \n%@", action, responseData);
             NSError *err = nil;
             id result = [self getResultFromRespond:responseData returnClass:returnClass error:&err];
             if (err) {
                 [self failedWithError:err describe:describe callback:completion];
             } else {
                 completion(YES, [self succeedWithDescribe:describe], result);
             }
         } else {
             LogDebug(@"%@", error.userInfo[[error.domain stringByAppendingString:@".error.data"]]);
             [self failedWithError:error describe:describe callback:completion];
         }
     }];
    return uuid;
}

/// 安全请求
+ (NSDictionary *)securityRequestBody:(NSDictionary *)body
{
    // 取出控制参数
    BOOL useEncrypt = [body[USE_ENCRYPT] boolValue];
    BOOL useSignature = [body[USE_SIGNATURE] boolValue];
    NSMutableDictionary *muBody = [body mutableCopy];
    [muBody removeObjectForKey:USE_ENCRYPT];
    [muBody removeObjectForKey:USE_SIGNATURE];
    
    // 拼接发送数据
    NSDictionary *aSendDic = [self getWholeRequestData:muBody];
    
    // 安全请求
    NSString *jsonData = aSendDic[@"jsonData"];
    NSMutableDictionary *dicBody = [[NSMutableDictionary alloc] initWithDictionary:aSendDic];
    
    // 使用加密
    NSData *encryptData = nil;
    if (useEncrypt) {
        encryptData = [MJSecurity AESEncryptData:[jsonData dataUsingEncoding:NSUTF8StringEncoding] key:AES_KEY iv:AES_IV];
        if (encryptData) {
            [dicBody removeObjectForKey:@"jsonData"];
            [dicBody setObject:[MJSecurity Base64Data:encryptData] forKey:@"encryptData"];
        } else {
            LogError(@"AES加密失败，请检查AES_KEY、AES_IV是否正确");
        }
    }
    
//    // 解密（测试）
//    if (useEncrypt) {
//        NSData *data = [MJSecurity dataFromDecodeBase64String:dicBody[@"encryptData"]];
//        NSString *deStr = [[NSString alloc] initWithData:[MJSecurity AESDecryptData:data key:AESkey iv:AESiv] encoding:NSUTF8StringEncoding];
//        NSLog(@"解密：%@", deStr);
//    }
    
    // 使用签名
    if (useSignature) {
        if (encryptData == nil) {
            encryptData = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
        }
        NSString *strSignature = [MJSecurity RSASignatureData:encryptData privateKey:RSA_PRIVATE_KEY];
        if (strSignature.length) {
            [dicBody setObject:[MJSecurity Base64Data:strSignature] forKey:@"signature"];
        } else {
            LogError(@"RSA签名失败，请检查RSA_PRIVATE_KEY是否正确");
        }
    }
    
//    // 验签（测试）
//    if (useSignature) {
//        NSData *sign = [MJSecurity dataFromDecodeBase64String:dicBody[@"signature"]];
//        NSData *da = nil;
//        if (useEncrypt) {
//            da = [MJSecurity dataFromDecodeBase64String:dicBody[@"encryptData"]];
//        } else {
//            da = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
//        }
//        BOOL pass = [MJSecurity RSAVerifySignature:sign withData:da publicKey:ServerPublickey];
//        NSLog(@"验签： %ld", pass);
//    }
    
    return dicBody;
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
#ifdef MODULE_DEVICE
        s_requestHeaderModel.deviceUUID = [MJDevice deviceUUID];
        s_requestHeaderModel.deviceVersion = [MJDevice deviceVersion];
        s_requestHeaderModel.deviceVersionName = [MJDevice deviceVersionName];
        s_requestHeaderModel.sysVersion = [MJDevice sysVersion];
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
        
#ifdef MODULE_AD_SUPPORT
        s_requestHeaderModel.deviceIDFA = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
#else
        s_requestHeaderModel.deviceIDFA = @"00000000-0000-0000-0000-000000000000";
#endif
        
        s_requestHeaderModel.sysType = kAppSys;
#ifdef DEBUG
        s_requestHeaderModel.appVersion = kClientVersion;
#else
        s_requestHeaderModel.appVersion = kClientVersionShort;
#endif
        s_requestHeaderModel.appState = kAppState;

#ifdef FUN_WEB_INTERFACE_DEVICE_NEED_APP
        s_requestHeaderModel.appBundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
#endif
        
        // 获取地区和语言
        NSArray *arrLanguages = [NSLocale preferredLanguages];
        NSString *aLanguage = arrLanguages.firstObject;
        NSRange aRange = [aLanguage rangeOfString:@"-" options:NSBackwardsSearch];
        if (aRange.length > 0) {
            s_requestHeaderModel.deviceRegionCode = [aLanguage substringFromIndex:aRange.location+1];
            s_requestHeaderModel.firstLanguage = [aLanguage substringToIndex:aRange.location];
        } else {
            // 这里可能是模拟器
            s_requestHeaderModel.deviceRegionCode = @"US";
            s_requestHeaderModel.firstLanguage = aLanguage;
        }
        // 时区
        NSString *timeZoneStr = [[[[NSTimeZone localTimeZone] abbreviation] substringFromIndex:3] stringByReplacingOccurrencesOfString:@":" withString:@""];
        s_requestHeaderModel.timeZone = [NSNumber numberWithInteger:[timeZoneStr integerValue]];
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
        NSString *jsonStr = jsonStringFromDic(aRequestModel);
        if (jsonStr == nil) {
            jsonStr = @"";
        }
        aSendDic = @{@"jsonData":jsonStr};
    }
    return aSendDic;
}

+ (NSMutableDictionary *)getRequestModel
{
    if (s_requestModel == nil) {
        s_requestModel = [[NSMutableDictionary alloc] init];
        MJRequestHeader *requstHeader = [self getRequestHeaderModel];
        NSDictionary *aDicHeader = nil;
#ifdef FUN_WEB_INTERFACE_DEVICE_NEED_APP
        if (requstHeader.deviceAppId) {
            aDicHeader = @{@"deviceAppId":requstHeader.deviceAppId,
                           @"appState":requstHeader.appState,
                           @"appVersion":requstHeader.appVersion};
        } else
#endif
        if (requstHeader.deviceId) {
            aDicHeader = @{@"deviceId":requstHeader.deviceId,
                           @"appState":requstHeader.appState,
                           @"appVersion":requstHeader.appVersion};
        } else {
            aDicHeader = [requstHeader toDictionary];
        }
        s_requestModel[@"head"] = aDicHeader;
    }
    return s_requestModel;
}

+ (id)getResultFromRespond:(id)respond returnClass:(Class)returnClass error:(NSError **)err
{
    id result = nil;
    @try {
        
#ifdef  MODULE_SECURITY
    // 安全请求的回调
        if ([respond isKindOfClass:[NSDictionary class]]) {
            NSString *encryptData = respond[@"encryptData"];
            if (encryptData) {
                NSData *data = [MJSecurity dataFromDecodeBase64String:encryptData];
                NSData *decryptData = [MJSecurity RSADecryptData:data privateKey:RSA_PRIVATE_KEY];
                if (decryptData) {
                    NSString *decryptStr = [[NSString alloc] initWithData:decryptData encoding:NSUTF8StringEncoding];
                    respond = objectFromString(decryptStr, nil);
                    LogInfo(@"解密成功：%@", respond);
                } else {
                    LogError(@"RSA解密失败，请检查RSA_PRIVATE_KEY是否正确");
                }
            }
        }
#endif
        
        NSDictionary *aRespond = nil;
        NSError *aErr = nil;
        // 解析json
        if ([respond isKindOfClass:[NSDictionary class]]) {
            aRespond = respond;
        } else if ([respond isKindOfClass:[NSString class]]){
            // 解析字符串
            aRespond = objectFromString(respond, &aErr);
        } else {
            // 受到不支持的数据
            if (err) *err = [self errorWithCode:-400 message:@"Receive unsupport data!" result:nil];
            return nil;
        }
        if (aErr) {
            if (err) *err = aErr;
            return nil;
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
                if (err) *err = [self errorWithCode:[code integerValue] message:errMessage result:respond[@"result"]];
                return nil;
            }
        } else {
            // 这里不存在code暂时默认为成功
        }
        
        // 解析网络数据
        result = aRespond[@"result"];
        if (result == nil) {
            result = aRespond;
        }
#ifdef MODULE_DB_MODEL
        if (returnClass != nil) {
            NSError *aErr = nil;
            result = [[returnClass alloc] initWithDictionary:result error:&aErr];
            if (aErr) {
                *err = aErr;
                return nil;
            }
        }
#endif
    }
    @catch (NSException *exception) {
        // 数据解析错误，出现该错误说明与服务器接口对应出了问题
        LogDebug(@"...>>>...JSON Parse Error: %@\n", exception);
        if (err) *err = [self errorWithCode:-500 message:@"JSON Parse Error" result:nil];
        return nil;
    }
    return result;
}

#pragma mark -


+ (NSString *)succeedWithDescribe:(NSString *)describe
{
    NSString *message = locStringWithFormat(kAPITipSucceedKey, describe);
    if ([message isEqualToString:kAPITipSucceedKey]) {
        message = [describe stringByAppendingString:@" succeed!"];
    }
    return message;
}

/**
 *	@brief	请求失败数据处理
 *
 *	@param 	error 	请求失败的错误
 *	@param 	describe 	请求描述
 *	@param 	completion 	请求完成回调
 */
+ (void)failedWithError:(NSError *)error
               describe:(NSString *)describe
               callback:(ActionCompleteBlock)completion

{
    if (completion) {
        NSString *message = locStringWithFormat(kAPITipFailedKey, describe);
        if ([message isEqualToString:kAPITipFailedKey]) {
            message = [describe stringByAppendingString:@" failed!"];
        }
        completion(NO, message, error);
    }
}

+ (NSError *)errorWithCode:(NSInteger)errCode message:(NSString *)message result:(id)result
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              message, NSLocalizedDescriptionKey,
                              message, NSLocalizedFailureReasonErrorKey,
                              result, @"result", nil];
    return [NSError errorWithDomain:kErrorDomainWebInterface code:errCode userInfo:userInfo];
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
    [MJWebService startGet:serverUrl body:nil completion:^(NSURLResponse *response, id responseData, NSError *error) {
        if (!error) {
            completion(YES, @"", responseData);
        } else {
            completion(NO, @"", error);
        }
    }];
#else
    completion(NO, @"Server url not set", nil);
#endif
}


@end
