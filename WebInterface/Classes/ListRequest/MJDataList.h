//
//  MJDataList.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import <ModuleCapability/ModuleCapability.h>
#import HEADER_MODEL

@interface MJDataList : MODEL_BASE_CLASS

@property (nonatomic, strong) NSNumber *total;
@property (nonatomic, strong) NSArray *theDataList;             ///< 转换成对应model的数据，请使用该数组

- (id)initWithDictionary:(NSDictionary *)aDic;

@end
