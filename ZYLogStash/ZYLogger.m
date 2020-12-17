//
//  ZYLogger.m
//  ZYRemote
//
//  Created by 吴鹏举 on 2020/12/14.
//  Copyright © 2020 ZHIYUN. All rights reserved.
//

#import "ZYLogger.h"

#import <pthread/pthread.h>

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@interface ZYLogger ()
{
    pthread_mutex_t _lock;
    
    dispatch_source_t restore_timer;
    dispatch_queue_t store_queue;
}
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSArray <ZYLogStashTask *>*>*taskDict;

@end

@implementation ZYLogger

+ (instancetype)logger{
    static id __logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __logger = [[self alloc] init];
    });
    return __logger;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        store_queue = dispatch_queue_create("com.ZYLogger.store_queue", NULL);
        
        NSString *logDirPath = [ZYLogStashTask defaultLogDirectoryPath];
        BOOL isDirectory = NO;
        BOOL isExist = [NSFileManager.defaultManager fileExistsAtPath:logDirPath isDirectory:&isDirectory];
        if (!isExist || !isDirectory) {
            [NSFileManager.defaultManager createDirectoryAtPath:logDirPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return self;
}

- (void)startRestoreTimerIfNeeded {
    if (restore_timer != NULL) {
        return;
    }
    double interval = 1.0f;
    NSAssert(restore_timer == NULL, @"SendTimer not null");
    NSAssert(interval >= 0.0, @"Timeout interval is zero");
    
    restore_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, store_queue);
    dispatch_source_set_timer(restore_timer, DISPATCH_TIME_NOW, (uint64_t)(interval * NSEC_PER_SEC), 0);
    dispatch_source_set_event_handler(restore_timer, ^{
        [self restoreTask];
    });
    dispatch_resume(restore_timer);
}

- (void)stopRestoreTimerIfNeeded {
    if (restore_timer != NULL) {
        dispatch_source_cancel(restore_timer);
    }
    restore_timer = NULL;
}

- (void)changeRestoreTimerStatus{
    if (!self.taskDict || (self.taskDict.count == 0)) {
        [self stopRestoreTimerIfNeeded];
    } else {
        [self startRestoreTimerIfNeeded];
    }
}

- (void)restoreTask{
    if (self.taskDict && (self.taskDict.count > 0)) {
        for (NSArray *serviceArr in self.taskDict.allValues) {
            for (ZYLogStashTask *logTask in serviceArr) {
                [logTask synchronizeIfNeeded];
            }
        }
    }
}

- (NSString *)registLogTask:(nullable NSString *)service
                   filePath:(nullable NSString *)filePath
                 storeLevel:(ZYLogStashStoreLevel)storeLevel{
    if (!filePath ||
        ![filePath isKindOfClass:[NSString class]] ||
        ([filePath isKindOfClass:[NSString class]] && (filePath.length == 0))) {
        filePath = [ZYLogStashTask randomFilePath];
    }
    if (!service ||
        ![service isKindOfClass:[NSString class]] ||
        ([service isKindOfClass:[NSString class]] && (service.length == 0))) {
        service = ZYLogStashTaskService_Common;
    }
    BOOL isDirectory = NO;
    BOOL isExists = [NSFileManager.defaultManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (isExists || isDirectory) {
        // file has exists at target filePath
        return nil;
    }
    BOOL result = [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    if (result) {
        ZYLogStashTask *logTask = [ZYLogStashTask logTask:service filePath:filePath storeLevel:storeLevel];
        if (logTask) {
            [self cacheLogTask:logTask];
            [self changeRestoreTimerStatus];
            return logTask.taskId;
        }
    }
    return nil;
}
- (NSArray <NSString *>*)logTaskIdsInService:(NSString *)service{
    NSArray *taskArr = [[ZYLogger logger] logTaskInService:service];
    if (taskArr && (taskArr.count > 0)) {
        return [taskArr valueForKey:@"taskId"];
    }
    return nil;
}
+ (NSArray <NSString *>*)logTaskIdsInService:(NSString *)service{
    return [[ZYLogger logger] logTaskIdsInService:service];
}
+ (NSArray <ZYLogStashTask *>*)logTaskInService:(NSString *)service{
    return [[ZYLogger logger] logTaskInService:service];
}
- (NSArray <ZYLogStashTask *>*)logTaskInService:(NSString *)service{
    if (!service ||
        (service.length == 0) ||
        (self.taskDict.count == 0)) {
        return nil;
    }
    NSArray *retArray = nil;
    Lock();
    if ([self.taskDict.allKeys containsObject:service]) {
        id taskArrObj = [self.taskDict objectForKey:service];
        if (taskArrObj && [taskArrObj isKindOfClass:[NSArray class]]) {
            retArray = taskArrObj;
        }
    }
    Unlock();
    return retArray;
}
- (BOOL)cacheLogTask:(ZYLogStashTask *)logTask{
    if (!logTask || !logTask.isValuable) {
        return NO;
    }
    Lock();
    if ([self.taskDict.allKeys containsObject:logTask.service]) {
        NSArray *taskArr = [self logTaskInService:logTask.service];
        if (taskArr) {
            NSMutableArray *newArr = taskArr.mutableCopy;
            [newArr addObject:logTask];
            [self.taskDict setObject:newArr forKey:logTask.service];
        }
    } else {
        [self.taskDict setObject:@[logTask] forKey:logTask.service];
    }
    Unlock();
    return YES;
}
- (ZYLogStashTask *)logTask:(NSString *)taskId{
    if (!taskId || (taskId.length == 0) || (self.taskDict.count == 0)) {
        return nil;
    }
    Lock();
    ZYLogStashTask *logTask;
    for (NSArray <ZYLogStashTask *>*taskArr in self.taskDict.allValues) {
        for (ZYLogStashTask *theTask in taskArr) {
            if ([theTask.taskId isEqualToString:taskId]) {
                logTask = theTask;
                break;
            }
        }
        if (logTask) {
            break;
        }
    }
    Unlock();
    return logTask;
}
- (BOOL)store:(nonnull NSString *)logRecord inTask:(nonnull NSString *)taskId{
    ZYLogStashTask *logTask = [self logTask:taskId];
    if (!logTask) {
        return NO;
    }
    __block BOOL result = NO;
    dispatch_async(store_queue, ^{
        result = logTask.record(logRecord);
    });
    return result;
}
- (BOOL)finishLogTask:(nonnull NSString *)taskId{
    if (!taskId || (taskId.length == 0) || (self.taskDict.count == 0)) {
        return NO;
    }
    Lock();
    ZYLogStashTask *logTask;
    id serviceKey;
    for (NSInteger idx = 0; idx < self.taskDict.allKeys.count; idx++) {
        serviceKey = self.taskDict.allKeys[idx];
        NSArray <ZYLogStashTask *>*taskArr = self.taskDict[serviceKey];
        for (ZYLogStashTask *theTask in taskArr) {
            if ([theTask.taskId isEqualToString:taskId]) {
                logTask = theTask;
                break;
            }
        }
        if (logTask) {
            break;
        }
    }
    if (logTask && serviceKey) {
        dispatch_async(store_queue, ^{
            [logTask finish];
        });
        NSMutableArray <ZYLogStashTask *>*taskArr = self.taskDict[serviceKey].mutableCopy;
        [taskArr removeObject:logTask];
        if (taskArr.count > 0) {
            [self.taskDict setObject:taskArr forKey:serviceKey];
        } else {
            [self.taskDict removeObjectForKey:serviceKey];
        }
        
    }
    Unlock();
    if (!serviceKey) {
        return NO;
    }
    [self changeRestoreTimerStatus];
    return YES;
}
+ (BOOL)finishLogTask:(nonnull NSString *)taskId{
    return [[ZYLogger logger] finishLogTask:taskId];
}
+ (NSString *)registLogTask:(nullable NSString *)service
                   filePath:(nullable NSString *)filePath
                 storeLevel:(ZYLogStashStoreLevel)storeLevel{
    return [[ZYLogger logger] registLogTask:service filePath:filePath storeLevel:storeLevel];
}

+ (BOOL)store:(nonnull NSString *)logRecord inTask:(nonnull NSString *)taskId{
    return [[ZYLogger logger] store:logRecord inTask:taskId];
}

- (NSMutableDictionary *)taskDict{
    if (_taskDict == nil) {
        _taskDict = @{}.mutableCopy;
    }
    return _taskDict;
}

@end
