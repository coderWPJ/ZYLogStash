//
//  ZYLogStashTask.h
//  Pods
//
//  Created by 吴鹏举 on 2020/12/15.
//

#import <Foundation/Foundation.h>


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

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, assign) ZYLogStashStoreLevel storeLevel;

/// record
- (BOOL)record:(nonnull NSString *)content;
- (BOOL(^)(NSString *content))record;

/// synchronize to file
- (BOOL)synchronizeIfNeeded;

- (void)finish;

+ (instancetype)logTask:(NSString *)filePath storeLevel:(ZYLogStashStoreLevel)storeLevel;

+ (NSString *)cacheFilePathInSandbox;
+ (NSString *)defaultLogDirectoryPath;
+ (NSString *)randomFilePath;

@end

NS_ASSUME_NONNULL_END
