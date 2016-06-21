//
//  DBRequest.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "DBRequestHeader.h"

@interface DBRequest : DBModel

@property (nonatomic, strong) NSString *mac;                /**< 请求唯一标示 */
@property (nonatomic, strong) DBRequestHeader *head;        /**< 请求head */
@property (nonatomic, strong) NSDictionary *body;           /**< 请求body */

@end
