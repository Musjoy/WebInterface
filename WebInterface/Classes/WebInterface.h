//
//  WebInterface.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ActionProtocol/ActionProtocol.h>
#import <WebInterface/MJRequestHeader.h>
#if __has_include(<WebInterface/MJListRequest.h>)
#define MODULE_WEB_INTERFACE_LIST_REQUEST
#import <WebInterface/MJListRequest.h>
#import <WebInterface/MJDataList.h.h>
#endif

/// 服务器API列表
#ifndef FILE_NAME_SERVER_APIS
#define FILE_NAME_SERVER_APIS  @"server_apis"
#endif


@interface WebInterface : NSObject

#pragma mark -

+ (void)cancelRequestWith:(NSString *)requestId;


+ (void)cancelAllRequest;


/**
 *	@brief	统一接口请求
 *
 *	@param 	action          接口名称
 *	@param 	describe        接口描述
 *	@param 	body            请求body
 *	@param 	completion      请求完成回调
 *
 *	@return	requestId       请求唯一标识
 */
+ (NSString *)startRequest:(NSString *)action
                  describe:(NSString *)describe
                      body:(NSDictionary *)body
                completion:(ActionCompleteBlock)completion;

+ (NSString *)startUpload:(NSString *)action
                describe:(NSString *)describe
                     body:(NSDictionary *)body
                    files:(NSArray *)files
               completion:(ActionCompleteBlock)completion;

#ifdef MODULE_DB_MODEL
+ (NSString *)startRequest:(NSString *)action
                  describe:(NSString *)describe
                      body:(NSDictionary *)body
               returnClass:(Class)returnClass
                completion:(ActionCompleteBlock)completion;

+ (NSString *)startUpload:(NSString *)action
                 describe:(NSString *)describe
                     body:(NSDictionary *)body
                    files:(NSArray *)files
              returnClass:(Class)returnClass
               completion:(ActionCompleteBlock)completion;
#endif

#ifdef MODULE_WEB_INTERFACE_LIST_REQUEST
/** 通用列表请求 */ 
+ (NSString *)fetchDataListWithModel:(MJListRequest *)requestModel
                          completion:(ActionCompleteBlock)completion;
#endif

/// 获取请求头部信息
+ (MJRequestHeader *)getRequestHeaderModel;

/// 重置请求model，一般是在请求头部信息修改是重置
+ (void)resetRequestMode;

#pragma mark - ServerAPI

+ (NSString *)latestActionFor:(NSString *)aAction;

+ (void)serverGet:(NSString *)action
       completion:(ActionCompleteBlock)completion;

@end
