//
//  ZYLogStashTask.m
//  Pods
//
//  Created by 吴鹏举 on 2020/12/15.
//

#import "ZYLogStashTask.h"

#import <stdio.h>

@interface ZYLogStashTask ()
{
    double _lastSyncTimestamp;
    
    FILE *_file;
}
@property (nonatomic, copy, readwrite) NSString *taskId;

@property (nonatomic, assign) double syncInterval;

@property (nonatomic, strong) NSMutableArray <NSString *>*contents;

@end

@implementation ZYLogStashTask

+ (instancetype)logTask:(NSString *)filePath storeLevel:(ZYLogStashStoreLevel)storeLevel{
    return [[ZYLogStashTask alloc] initWithFilePath:filePath storeLevel:storeLevel];
}

- (instancetype)initWithFilePath:(NSString *)filePath storeLevel:(ZYLogStashStoreLevel)storeLevel{
    self = [super init];
    if (self) {
        [self resetLastSyncTimestamp];
        
        self.filePath = filePath;
        self.storeLevel = storeLevel;
        self.taskId = [ZYLogStashTask uuidString];
        
        self.syncInterval = [ZYLogStashTask syncIntervalFromStoreLevel:storeLevel];
    }
    return self;
}

- (void)finish{
    self.contents = nil;
    [self closeFile];
}

- (BOOL)openFile{
    if (!self.filePath || (self.filePath.length == 0)) {
        return NO;
    }
    _file = fopen(self.filePath.UTF8String, "a+");
    if (_file == NULL) {
        perror("Open file failure");
        return NO;
    }
    return YES;
}

- (BOOL)closeFile{
    if (_file != NULL) {
        int result = fclose(_file);
        return (result == 0);
    } else {
        return YES;
    }
}

- (BOOL)appendContent:(NSString *)content{
    content = [content stringByAppendingString:@"\n"];
    if (_file == NULL) {
        return NO;
    }
    return fputs(content.UTF8String, _file);
}

+ (double)syncIntervalFromStoreLevel:(ZYLogStashStoreLevel)level{
    NSDictionary *dict = @{@(ZYLogStashStoreLevel_Manual):@(0),
                           @(ZYLogStashStoreLevel_Auto_Immediately):@(0),
                           @(ZYLogStashStoreLevel_Auto_Sec_1):@(1.0f),
                           @(ZYLogStashStoreLevel_Auto_Sec_5):@(5.0f),
                           @(ZYLogStashStoreLevel_Auto_Sec_10):@(10.0f),
                           @(ZYLogStashStoreLevel_Auto_Sec_15):@(15.0f),
                           @(ZYLogStashStoreLevel_Auto_Sec_30):@(30.0f),
                           @(ZYLogStashStoreLevel_Auto_Sec_45):@(45.0f),
                           @(ZYLogStashStoreLevel_Auto_min_1):@(60.0f),
    };
    id keyObj = @(level);
    if ([dict.allKeys containsObject:keyObj]) {
        return [dict[keyObj] doubleValue];
    }
    return 0;
}

- (void)resetLastSyncTimestamp{
    _lastSyncTimestamp = NSDate.date.timeIntervalSince1970;
}

/// record
- (BOOL)record:(nonnull NSString *)content{
    if (!content ||
        ![content isKindOfClass:[NSString class]] ||
        (content.length == 0)) {
        return NO;
    }
    @synchronized (self) {
        [self.contents addObject:content];
    }
    if (self.storeLevel == ZYLogStashStoreLevel_Auto_Immediately) {
        [self synchronize];
    }
    return YES;
}
- (BOOL(^)(NSString *content))record{
    return ^(NSString *content){
        return [self record:content];
    };
}
/// synchronize to file
- (BOOL)synchronize{
    NSInteger status = 0;
    if (self.openFile) {
        status = 1;
        @synchronized (self) {
            for (NSInteger idx = 0; idx < self.contents.count; idx++) {
                BOOL putsResult = [self appendContent:self.contents[idx]];
                if (!putsResult) {
                    status = 2;
                }
                NSLog(@"字符串写入结果：%@", putsResult?@"成功":@"失败");
            }
            [self.contents removeAllObjects];
        }
    }
    [self closeFile];
    [self resetLastSyncTimestamp];
    return (status == 1);
}
- (BOOL)synchronizeIfNeeded{
    if ((self.storeLevel == ZYLogStashStoreLevel_Manual) ||
        (self.storeLevel == ZYLogStashStoreLevel_Auto_Immediately)) {
        return [self synchronize];
    }
    double curTime = NSDate.date.timeIntervalSince1970;
    if ((curTime-_lastSyncTimestamp) > self.syncInterval) {
        return [self synchronize];
    }
    return NO;
}

- (NSMutableArray *)contents{
    if (!_contents) {
        _contents = @[].mutableCopy;
    }
    return _contents;
}

+ (NSString *)cacheFilePathInSandbox{
    NSArray *cacPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [cacPath objectAtIndex:0];
}
+ (NSString *)defaultLogDirectoryPath{
    return [[self cacheFilePathInSandbox] stringByAppendingPathComponent:@"ZYLogger"];
}
+ (NSString *)randomFilePath{
    NSString *fileName = [NSString stringWithFormat:@"%.0f_%u.txt", [NSDate.date timeIntervalSince1970], arc4random()%100];
    NSString *directory = [self defaultLogDirectoryPath];
    return [directory stringByAppendingPathComponent:fileName];
}
+ (NSString*)uuidString {
    CFUUIDRef puuid = CFUUIDCreate(nil);
    CFStringRef uuidString = CFUUIDCreateString(nil, puuid);
    NSString * result = (NSString *)CFBridgingRelease(CFStringCreateCopy( NULL, uuidString));
    CFRelease(puuid);
    CFRelease(uuidString);
    return result;
}
- (void)dealloc{
//    NSLog(@"<ZYLogStashTask dealloc !!!>");
}
@end
