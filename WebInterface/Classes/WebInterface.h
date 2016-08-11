//
//  WebInterface.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActionProtocol.h"
#import "MJRequest.h"
#if __has_include("DBListRequest.h")
#define MODULE_WEB_INTERFACE_LIST_REQUEST
#import "DBListRequest.h"
#import "DBDataList.h"
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
 *	@param 	returnClass 	接收的model
 *	@param 	completion      请求完成回调
 *
 *	@return	void
 */
+ (NSString *)startRequest:(NSString *)action
                  describe:(NSString *)describe
                      body:(NSDictionary *)body
               returnClass:(Class)returnClass
                completion:(ActionCompleteBlock)completion;

#ifdef MODULE_WEB_INTERFACE_LIST_REQUEST
/** 通用列表请求 */
+ (NSString *)fetchDataListWithModel:(DBListRequest *)requestModel
                          completion:(ActionCompleteBlock)completion;
#endif


+ (MJRequest *)getRequestModel;

#pragma mark - ServerAPI

+ (NSString *)latestActionFor:(NSString *)aAction;

+ (void)serverGet:(NSString *)action
       completion:(ActionCompleteBlock)completion;

@end
