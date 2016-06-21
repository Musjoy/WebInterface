//
//  ResultModel.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//  网络请求返回数据的body部分

#import <Foundation/Foundation.h>

@interface ResultModel : NSObject

//@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) id result;

@end
