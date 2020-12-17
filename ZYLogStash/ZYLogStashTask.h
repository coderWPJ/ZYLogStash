//
//  ZYLogStashTask.h
//  Pods
//
//  Created by 吴鹏举 on 2020/12/15.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const ZYLogStashTaskService_Common;

typedef NS_ENUM(NSInteger, ZYLogStashStoreLevel) {
    ZYLogStashStoreLevel_Manual = 0,
    ZYLogStashStoreLevel_Auto_Immediately,
    ZYLogStashStoreLevel_Auto_Sec_1,
    ZYLogStashStoreLevel_Auto_Sec_5,
    ZYLogStashStoreLevel_Auto_Sec_10,
    ZYLogStashStoreLevel_Auto_Sec_15,
    ZYLogStashStoreLevel_Auto_Sec_30,
    ZYLogStashStoreLevel_Auto_Sec_45,
    ZYLogStashStoreLevel_Auto_min_1,   
};

NS_ASSUME_NONNULL_BEGIN

@interface ZYLogStashTask : NSObject

@property (nonatomic, copy, readonly) NSString *taskId;

@property (nonatomic, copy, readonly) NSString *service;

@property (nonatomic, copy, readonly) NSString *filePath;

@property (nonatomic, assign, readonly) ZYLogStashStoreLevel storeLevel;

/// record
- (BOOL)record:(nonnull NSString *)content;
- (BOOL(^)(NSString *content))record;

/// synchronize to file
- (BOOL)synchronizeIfNeeded;

- (void)finish;

+ (instancetype)logTask:(nullable NSString *)service
               filePath:(nullable NSString *)filePath
             storeLevel:(ZYLogStashStoreLevel)storeLevel;

+ (NSString *)cacheFilePathInSandbox;
+ (NSString *)defaultLogDirectoryPath;
+ (NSString *)randomFilePath;

- (BOOL)isValuable;

@end

NS_ASSUME_NONNULL_END
