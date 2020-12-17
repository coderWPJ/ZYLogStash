//
//  LogTestVC.m
//  ZYLogStash
//
//  Created by 吴鹏举 on 2020/12/16.
//

#import "LogTestVC.h"

#import <ZYLogger.h>

@interface LogTestVC ()

@property (nonatomic, copy) NSString *taskId;

@end

@implementation LogTestVC

static NSString *serviceStr = @"LogTestVC";
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor cyanColor];
    
    UIButton *sandboxBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sandboxBtn.frame = CGRectMake(100, 100, 60, 50);
    sandboxBtn.backgroundColor = [UIColor redColor];
    [sandboxBtn setTitle:@"返回" forState:UIControlStateNormal];
    [sandboxBtn addTarget:self action:@selector(btnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sandboxBtn];
    
    
    self.taskId = [ZYLogger registLogTask:serviceStr filePath:nil storeLevel:ZYLogStashStoreLevel_Auto_Sec_10];
    
    [ZYLogger store:@"Hello" inTask:self.taskId];
    [ZYLogger store:@"i" inTask:self.taskId];
    [ZYLogger store:@"am" inTask:self.taskId];
    [ZYLogger store:@"张三" inTask:self.taskId];
    [ZYLogger store:@"哈哈哈哈" inTask:self.taskId];
    [ZYLogger store:@"what's" inTask:self.taskId];
    [ZYLogger store:@"your" inTask:self.taskId];
    [ZYLogger store:@"name" inTask:self.taskId];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [ZYLogger finishLogTask:self.taskId];
}

- (void)btnAction{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc{
    NSLog(@"<LogTestVC dealloc!!!>");
}

@end
