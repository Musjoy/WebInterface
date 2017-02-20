//
//  MJDataList.m
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "MJDataList.h"

@interface MJDataList ()

@property (nonatomic, strong) NSArray *dataList;                ///< 服务器获取的数据，请勿使用

@end

@implementation MJDataList

- (id)initWithDictionary:(NSDictionary *)aDic
{
    self = [super init];
    if (self) {
        self.total = [aDic valueForKey:@"total"];
        self.dataList = [aDic valueForKey:@"dataList"];
    }
    return self;
}

@end
