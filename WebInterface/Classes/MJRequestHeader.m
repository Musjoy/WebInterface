//
//  MJRequestHeader.m
//  Common
//
//  Created by 黄磊 on 16/4/20.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "MJRequestHeader.h"

@implementation MJRequestHeader

- (NSDictionary *)toDictionary
{
#ifdef MODULE_DB_MODEL1
    return [super toDictionary];
#else
    NSDictionary *aDic = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"deviceUUID", _deviceUUID,
                          @"deviceName", _deviceName,
                          @"deviceVersion", _deviceVersion,
                          @"sysVersion", _sysVersion,
                          @"sysType", _sysType,
                          @"appVersion", _appVersion,
                          @"appState", _appState, nil];
    return aDic;
#endif
}

@end
