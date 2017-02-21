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
                          _deviceUUID, @"deviceUUID",
                          _deviceName, @"deviceName",
                          _deviceVersion, @"deviceVersion",
                          _sysVersion, @"sysVersion",
                          _sysType, @"sysType",
                          _appVersion, @"appVersion",
                          _appState, @"appState", nil];
    return aDic;
#endif
}

@end
