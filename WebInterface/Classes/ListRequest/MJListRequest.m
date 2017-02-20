//
//  MJListRequest.m
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "MJListRequest.h"

@implementation MJListRequest


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
