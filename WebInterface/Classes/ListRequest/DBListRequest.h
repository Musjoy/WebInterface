//
//  DBListRequest.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "DBModel.h"
#if __has_include("DBDataListHandle.h")
#define MODULE_DATA_LIST_HADNDLE
#import "DBDataListHandle.h"
#endif

@interface DBListRequest : DBModel

@property (nonatomic, strong) NSString *serverAction;           ///< 服务器接口名称
@property (nonatomic, strong) NSDictionary *requestParam;       ///< 服务器接口请求参数
@property (nonatomic, strong) NSString *listDecs;               ///< 列表数据描述
@property (nonatomic, assign) NSInteger pageNo;                 ///< 请求第几页
@property (nonatomic, assign) NSInteger pageSize;               ///< 一页请求多少数据
@property (nonatomic, assign) Class receiveClass;               ///< 请求回来的model

#ifdef MODULE_DATA_LIST_HADNDLE
- (id)initWithHandleModel:(DBDataListHandle *)aHandleModel requestParam:(NSDictionary *)requestParam;
#endif

- (id)initWithServerAction:(NSString *)serverAction
                  listDecs:(NSString *)listDecs
              requestParam:(NSDictionary *)requestParam
              receiveClass:(Class)receiveClass;

// 检查必要参数是否都有
- (NSString *)chechContent;

@end
