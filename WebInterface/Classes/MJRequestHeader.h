//
//  MJRequestHeader.h
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "DBModel.h"

@interface MJRequestHeader : DBModel

@property (nonatomic, strong) NSString *method;                     /**< 调用的方法 */

@property (nonatomic, strong) NSNumber<DBInt> *deviceId;            /**< 设备ID，当这个值存在时，下面四个可选 */
@property (nonatomic, strong) NSString *deviceUUID;                 /**< 设备唯一标示 */
@property (nonatomic, strong) NSString *deviceName;                 /**< 设备名称 */
@property (nonatomic, strong) NSString *deviceVersion;              /**< 设备版本 */
@property (nonatomic, strong) NSString *sysVersion;                 /**< 系统版本号 */
@property (nonatomic, strong) NSNumber<DBInt> *sysType;             /**< 系统类型 0-未知设备 1-iOS 2-Android */
@property (nonatomic, strong) NSString *appVersion;                 /**< app版本号 */
@property (nonatomic, strong) NSNumber<DBInt> *appState;            /**< app状态 0-开发状态 1-发布状态 */



//@property (nonatomic, strong) NSString *version;                      // 接口版本号

@end
