//
//  MJRespond.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "DBModel.h"

@interface MJRespond : DBModel

@property (nonatomic, strong) NSString *mac;                /**< 请求返回的唯一标识 */
@property (nonatomic, strong) NSDictionary *head;           /**< 请求返回head */
@property (nonatomic, strong) NSDictionary *body;           /**< 请求返回body */  

@end
