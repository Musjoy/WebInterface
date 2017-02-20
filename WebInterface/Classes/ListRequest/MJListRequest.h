//
//  MJListRequest.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MJListRequest : NSObject

@property (nonatomic, strong) NSString *serverAction;           ///< 服务器接口名称
@property (nonatomic, strong) NSDictionary *requestParam;       ///< 服务器接口请求参数
@property (nonatomic, strong) NSString *listDecs;               ///< 列表数据描述
@property (nonatomic, assign) NSInteger pageNo;                 ///< 请求第几页
@property (nonatomic, assign) NSInteger pageSize;               ///< 一页请求多少数据
@property (nonatomic, assign) Class receiveClass;               ///< 请求回来的model，可以是MJDataList子类，也可以是DBModel子类

- (id)initWithServerAction:(NSString *)serverAction
                  listDecs:(NSString *)listDecs
              requestParam:(NSDictionary *)requestParam
              receiveClass:(Class)receiveClass;

// 检查必要参数是否都有
- (NSString *)chechContent;

@end
