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
#ifdef MODULE_DB_MODEL
    return [super toDictionary];
#else
    NSDictionary *aDic = [NSDictionary dictionaryWithObjectsAndKeys:
                          _deviceUUID, @"deviceUUID",
                          _deviceIDFA, @"deviceIDFA",
                          _deviceName, @"deviceName",
                          _deviceVersion, @"deviceVersion",
                          _deviceVersionName, @"deviceVersionName",
                          _sysVersion, @"sysVersion",
                          _sysType, @"sysType",
                          _appVersion, @"appVersion",
                          _appState, @"appState",
                          _deviceRegionCode, @"deviceRegionCode",
                          _firstLanguage, @"firstLanguage", nil];
    return aDic;
#endif
}

@end
