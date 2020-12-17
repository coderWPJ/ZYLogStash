//
//  ViewController.m
//  ZYLogStash
//
//  Created by 吴鹏举 on 2020/12/15.
//

#import "ViewController.h"
#import "ZYSandBoxFileExplorerVC.h"
#import "LogTestVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *sandboxBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    sandboxBtn.frame = CGRectMake(100, 100, 60, 50);
    sandboxBtn.backgroundColor = [UIColor redColor];
    [sandboxBtn setTitle:@"沙盒" forState:UIControlStateNormal];
    [sandboxBtn addTarget:self action:@selector(btnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sandboxBtn];
    
    UIButton *logBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    logBtn.frame = CGRectMake(100, 200, 60, 50);
    logBtn.backgroundColor = [UIColor redColor];
    [logBtn setTitle:@"logVC" forState:UIControlStateNormal];
    [logBtn addTarget:self action:@selector(enterLogPage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:logBtn];
    
    
}

- (void)enterLogPage{
    LogTestVC *logVC = [[LogTestVC alloc] init];
    logVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:logVC animated:YES completion:nil];
}

- (void)btnAction{
    [ZYSandBoxFileExplorerVC showSandboxInfo:self];
}

@end
