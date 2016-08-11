//
//  DBListRequest.m
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "DBListRequest.h"

@implementation DBListRequest

#ifdef MODULE_DATA_LIST_HADNDLE
- (id)initWithHandleModel:(DBDataListHandle *)aHandleModel requestParam:(NSDictionary *)requestParam
{
    self = [super init];
    if (self) {
        self.serverAction = aHandleModel.serverAction;
        self.requestParam = requestParam;
        if (aHandleModel.listDecs.length > 0) {
            self.listDecs = aHandleModel.listDecs;
        } else {
            self.listDecs = @"获取列表数据";
        }
        if (aHandleModel.receiveModel.length > 0) {
            self.receiveClass = NSClassFromString(aHandleModel.receiveModel);
        }
    }
    return self;
}
#endif

- (id)initWithServerAction:(NSString *)serverAction listDecs:(NSString *)listDecs requestParam:(NSDictionary *)requestParam receiveClass:(Class)receiveClass
{
    self = [super init];
    if (self) {
        self.serverAction = serverAction;
        self.listDecs = listDecs;
        self.requestParam = requestParam;
        self.receiveClass = receiveClass;
    }
    return self;
}

- (NSString *)chechContent
{
    if (self.serverAction.length == 0) {
        return @"Server interface is nil";
    }
    return nil;
}

@end
