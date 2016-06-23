//
//  WebInterface.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ActionProtocol.h"
#import "DBRequest.h"

/// 服务器API列表
#ifndef PLIST_SERVER_APIS
#define PLIST_SERVER_APIS  @"server_apis"
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


+ (DBRequest *)getRequestModel;

#pragma mark - ServerAPI

+ (NSString *)latestActionFor:(NSString *)aAction;

+ (void)serverGet:(NSString *)action
       completion:(ActionCompleteBlock)completion;

@end
