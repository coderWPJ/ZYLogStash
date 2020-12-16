//
//  ZTTXTReaderVC.m
//  ZYLibrary
//
//  Created by wu on 2020/9/16.
//  Copyright © 2020 ZHIYUN. All rights reserved.
//

#import "ZTTXTReaderVC.h"

@interface ZTTXTReaderVC ()

@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) UITextView *txtView;

@end

@implementation ZTTXTReaderVC

+ (instancetype)readerVCWithFilePath:(NSString *)filePath{
    ZTTXTReaderVC *retVC = [[ZTTXTReaderVC alloc] initWithFilePath:filePath];
    return retVC;
}

- (instancetype)initWithFilePath:(NSString *)filePath{
    self = [super init];
    if (self) {
        self.filePath = filePath;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = self.filePath.lastPathComponent;
    
    self.txtView = [[UITextView alloc] init];
    self.txtView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    self.txtView.editable = NO;
    self.txtView.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:self.txtView];
    
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfFile:self.filePath encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        self.txtView.text = content;
    }
    
    UIButton *managerSubscriptionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [managerSubscriptionBtn setTitle:@"导出" forState:UIControlStateNormal];
    managerSubscriptionBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [managerSubscriptionBtn addTarget:self action:@selector(exportFile) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:managerSubscriptionBtn];
}

- (void)exportFile{
    NSArray *objectsToShare = @[[NSURL fileURLWithPath:self.filePath]];
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    NSArray *excludedActivities = @[UIActivityTypePostToTwitter,
                                    UIActivityTypePostToFacebook,
                                    UIActivityTypePostToWeibo,
                                    UIActivityTypeMessage,
                                    UIActivityTypeMail,
                                    UIActivityTypePrint,
                                    UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeAssignToContact,
                                    UIActivityTypeSaveToCameraRoll,
                                    UIActivityTypeAddToReadingList,
                                    UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo,
                                    UIActivityTypePostToTencentWeibo];
    controller.excludedActivityTypes = excludedActivities;          // Present the controller
    [self presentViewController:controller animated:YES completion:nil];
}

@end
