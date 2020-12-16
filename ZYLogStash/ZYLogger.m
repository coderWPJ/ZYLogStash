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
@property (nonatomic, strong) NSMutableDictionary <NSString *, ZYLogStashTask *>*taskDict;

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
    NSLog(@"restoreTask, restoreTask, restoreTask");
    if (self.taskDict && (self.taskDict.count > 0)) {
        for (ZYLogStashTask *logTask in self.taskDict.allValues) {
            [logTask synchronizeIfNeeded];
        }
    }
}

- (NSString *)registLogTask:(nullable NSString *)filePath
                 storeLevel:(ZYLogStashStoreLevel)storeLevel{
    if (!filePath ||
        ![filePath isKindOfClass:[NSString class]] ||
        ([filePath isKindOfClass:[NSString class]] && (filePath.length == 0))) {
        filePath = [ZYLogStashTask randomFilePath];
    }
    BOOL isDirectory = NO;
    BOOL isExists = [NSFileManager.defaultManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (isExists || isDirectory) {
        // file has exists at target filePath
        return nil;
    }
    BOOL result = [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    if (result) {
        ZYLogStashTask *logTask = [ZYLogStashTask logTask:filePath storeLevel:storeLevel];
        if (logTask) {
            Lock();
            [self.taskDict setValue:logTask forKey:logTask.taskId];
            Unlock();
            [self changeRestoreTimerStatus];
            return logTask.taskId;
        }
    }
    return nil;
}

- (ZYLogStashTask *)logTask:(NSString *)taskId{
    if (!taskId || (taskId.length == 0)) {
        return nil;
    }
    ZYLogStashTask *logTask;
    Lock();
    if ([self.taskDict.allKeys containsObject:taskId]) {
        logTask = [self.taskDict objectForKey:taskId];
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
    ZYLogStashTask *logTask = [self logTask:taskId];
    if (!logTask) {
        return NO;
    }
    dispatch_async(store_queue, ^{
        [logTask finish];
    });
    Lock();
    [self.taskDict removeObjectForKey:taskId];
    Unlock();
    [self changeRestoreTimerStatus];
    return YES;
}
+ (BOOL)finishLogTask:(nonnull NSString *)taskId{
    return [[ZYLogger logger] finishLogTask:taskId];
}

+ (NSString *)registLogTask:(nullable NSString *)filePath
                 storeLevel:(ZYLogStashStoreLevel)storeLevel{
    return [[ZYLogger logger] registLogTask:filePath storeLevel:storeLevel];
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
