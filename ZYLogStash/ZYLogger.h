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

+ (NSString *)registLogTask:(nullable NSString *)filePath
                 storeLevel:(ZYLogStashStoreLevel)storeLevel;


+ (BOOL)store:(nonnull NSString *)logRecord inTask:(nonnull NSString *)taskId;

+ (BOOL)finishLogTask:(nonnull NSString *)taskId;

+ (instancetype)logger;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
