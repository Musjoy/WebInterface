//
//  DBDataList.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "DBModel.h"

@interface DBDataList : DBModel

@property (nonatomic, strong) NSNumber<DBInt> *total;
@property (nonatomic, strong) NSArray *theDataList;             ///< 转换成对应model的数据，请使用该数组

@end
