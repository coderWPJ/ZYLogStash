//
//  ZYLogger.h
//  ZYRemote
//
//  Created by 吴鹏举 on 2020/12/14.
//  Copyright © 2020 ZHIYUN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZYLogStashTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZYLogger : NSObject

/// 获取对应服务下的 log 任务id
+ (NSArray <NSString *>*)logTaskIdsInService:(NSString *)service;

/// 注册log任务，service不传会用默认服务，filePath不传会在默认log文件夹内生成随机名称的log文件
+ (NSString *)registLogTask:(nullable NSString *)service
                   filePath:(nullable NSString *)filePath
                 storeLevel:(ZYLogStashStoreLevel)storeLevel;



/// 记录log
+ (BOOL)store:(nonnull NSString *)logRecord inTask:(nonnull NSString *)taskId;
/// 结束log任务
+ (BOOL)finishLogTask:(nonnull NSString *)taskId;



+ (instancetype)logger;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
