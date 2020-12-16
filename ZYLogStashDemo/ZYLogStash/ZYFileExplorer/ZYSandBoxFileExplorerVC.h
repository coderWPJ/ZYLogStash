//
//  ZYSandBoxFileExplorerVC.h
//  ZYLibrary
//
//  Created by wu on 2020/3/26.
//  Copyright © 2020 ZHIYUN. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZYSandBoxFileExplorerVC : UIViewController

+ (instancetype)showSandboxInfo:(UIViewController *)enterVC;

+ (instancetype)FileExplorerVC:(NSString *)directoryPath;

@end

NS_ASSUME_NONNULL_END
