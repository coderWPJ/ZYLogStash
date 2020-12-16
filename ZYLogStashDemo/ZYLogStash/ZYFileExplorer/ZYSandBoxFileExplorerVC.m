//
//  ZYSandBoxFileExplorerVC.m
//  ZYLibrary
//
//  Created by wu on 2020/3/26.
//  Copyright © 2020 ZHIYUN. All rights reserved.
//

#import "ZYSandBoxFileExplorerVC.h"
#import "ZTTXTReaderVC.h"

#import <Masonry.h>
#include <sys/stat.h>
#include <dirent.h>

//#import "ZYDevFloatTool.h"


@interface ZYSandBoxFileExplorerVC ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSString *directoryPath;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *dataSource;

@property (nonatomic, assign) BOOL isHost;

@end

@implementation ZYSandBoxFileExplorerVC

+ (instancetype)showSandboxInfo:(UIViewController *)enterVC{
    ZYSandBoxFileExplorerVC *feVC = [[ZYSandBoxFileExplorerVC alloc] init];
    feVC.isHost = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:feVC];
    feVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [enterVC presentViewController:nav animated:YES completion:nil];
    return feVC;
}

+ (instancetype)FileExplorerVC:(NSString *)directoryPath{
    ZYSandBoxFileExplorerVC *retVC = [[ZYSandBoxFileExplorerVC alloc] initWithDirectoryPath:directoryPath];
    return retVC;
}

- (instancetype)initWithDirectoryPath:(NSString *)directoryPath{
    self = [super init];
    if (self) {
        self.directoryPath = directoryPath;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    if (self.navigationController.viewControllers.count == 1) {
        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [backBtn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
        [backBtn setTitle:@"关闭" forState:UIControlStateNormal];
        [backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
        [self.navigationItem setLeftBarButtonItem:backItem];
    }
    self.navigationItem.title = self.directoryPath.lastPathComponent;
    
    [self requestAllFiles];
}

- (void)requestAllFiles{
    if (self.isHost) {
        NSMutableArray *dataArr = @[@"Documents", @"Library", @"Caches", @"Temporary"].mutableCopy;
        self.dataSource = dataArr;
        [self.tableView reloadData];
        return;
    }
    if (!self.directoryPath || (self.directoryPath.length == 0)) {
        return;
    }
    
    NSArray *urlResouceKeys = @[NSURLCreationDateKey,NSURLLocalizedNameKey,NSURLLocalizedTypeDescriptionKey];
    NSArray <NSURL *>*urlsArr = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.directoryPath]
                                                              includingPropertiesForKeys:urlResouceKeys
                                                                                 options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                   error:nil];
    NSMutableArray *dataArr = @[].mutableCopy;
    for (NSInteger idx = 0; idx < urlsArr.count; idx++) {
        NSString *fileStr = urlsArr[idx].absoluteString.lastPathComponent;
        [dataArr addObject:fileStr];
    }
    self.dataSource = dataArr;
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const cellIdentify = @"ZYFileExplorerVCCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentify];
        cell.backgroundColor = [UIColor lightGrayColor];
    }
    NSString *fileName = self.dataSource[indexPath.section];
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    cell.textLabel.text = fileName;
    if ([fileName componentsSeparatedByString:@"."].count == 1) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    long long sizeValue = [[self class] fileSizeAtPath:[self filePathAtINdexPath:indexPath]];
    cell.detailTextLabel.text = [self resSizeMDes:sizeValue];
    return cell;
}

//ios 11以上
- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)){
    NSString *fileName = self.dataSource[indexPath.section];
    if ([fileName componentsSeparatedByString:@"."].count == 1) {
        return nil;
    }
    __weak typeof(self) weakSelf = self;
    UIContextualAction *exportAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"导出" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [tableView setEditing:NO animated:YES];
        [strongSelf exportFile:indexPath];
        
    }];
    UISwipeActionsConfiguration *config = [UISwipeActionsConfiguration configurationWithActions:@[exportAction]];
    config.performsFirstActionWithFullSwipe = NO;
    return config;
}

- (void)exportFile:(NSIndexPath *)indexPath{
    NSString *fileName = self.dataSource[indexPath.section];
    NSArray <NSString *>*allComponents = [fileName.lastPathComponent componentsSeparatedByString:@"."];
    if (allComponents.count > 1) {
        NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
        NSArray *objectsToShare = @[[NSURL fileURLWithPath:filePath]];
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
}

// Private
+ (long long) _folderSizeAtPath: (const char*)folderPath{
    long long folderSize = 0;
    DIR* dir = opendir(folderPath);
    if (dir == NULL) return 0;
        struct dirent* child;
        while ((child = readdir(dir))!=NULL) {
        if (child->d_type == DT_DIR && (
                                    (child->d_name[0] == '.' && child->d_name[1] == 0) || // 忽略目录 .
                                    (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0) // 忽略目录 ..
                                    )) continue;
    
        int folderPathLength = strlen(folderPath);
        char childPath[1024]; // 子文件的路径地址
        stpcpy(childPath, folderPath);
        if (folderPath[folderPathLength-1] != '/'){
            childPath[folderPathLength] = '/';
            folderPathLength++;
        }
        stpcpy(childPath+folderPathLength, child->d_name);
        childPath[folderPathLength + child->d_namlen] = 0;
        if (child->d_type == DT_DIR){ // directory
            folderSize += [self _folderSizeAtPath:childPath]; // 递归调用子目录
            // 把目录本身所占的空间也加上
//            struct stat st;
//            if(lstat(childPath, &st) == 0)
//                folderSize += st.st_size;
        }else if (child->d_type == DT_REG || child->d_type == DT_LNK){ // file or link
            struct stat st;
            if(lstat(childPath, &st) == 0)
                folderSize += st.st_size;
        }
    }
    return folderSize;
}


+ (long long)fileSizeAtPath:(NSString*)filePath
{
    NSFileManager* manager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL isExists = [manager fileExistsAtPath:filePath isDirectory:&isDirectory];
    long long retSize = 0;
    if (isExists){
        if (isDirectory) {
            return [self _folderSizeAtPath:[filePath cStringUsingEncoding:NSUTF8StringEncoding]];
        } else {
            retSize = [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
        }
    }
    return retSize;
}

- (NSString *)resSizeMDes:(long long)sizeValue{
    double oneKB = 1000.0f;
    double oneMB = oneKB*oneKB;
    double oneGB = oneMB*oneKB;
    NSString *resSizeMDes = @"";
    if (sizeValue >= oneGB) {
        resSizeMDes = [NSString stringWithFormat:@"%.1fG", ((double)sizeValue/oneGB)];
    } else {
        if (sizeValue >= oneMB) {
            resSizeMDes = [NSString stringWithFormat:@"%.1fM", ((double)sizeValue/oneMB)];
        } else {
            if (sizeValue < oneKB) {
                resSizeMDes = [NSString stringWithFormat:@"%ldB", sizeValue];
            } else {
                resSizeMDes = [NSString stringWithFormat:@"%.1fKB", (double)sizeValue/oneKB];
            }
        }
    }
    if ([resSizeMDes containsString:@".0"]) {
        resSizeMDes = [resSizeMDes stringByReplacingOccurrencesOfString:@".0" withString:@""];
    }
    return resSizeMDes;
}

- (NSString *)filePathAtINdexPath:(NSIndexPath *)indexPath{
    if (self.isHost) {
        NSString *fileName = self.dataSource[indexPath.section];
        NSArray *sandBoxArr = @[@"Documents", @"Library", @"Caches", @"Temporary"];
        NSString *path = nil;
        if ([sandBoxArr containsObject:fileName]) {
            switch ([sandBoxArr indexOfObject:fileName]) {
                case 0:
                    path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                    break;
                case 1:
                    path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
                    break;
                case 2:
                    path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
                    break;
                case 3:
                    path = NSTemporaryDirectory();
                    break;
                default:
                    break;
            }
        }
        return path;
    } else {
        NSString *fileName = self.dataSource[indexPath.section];
        NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
        return filePath;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.isHost) {
        NSString *fileName = self.dataSource[indexPath.section];
        NSArray *sandBoxArr = @[@"Documents", @"Library", @"Caches", @"Temporary"];
        NSString *path = nil;
        if ([sandBoxArr containsObject:fileName]) {
            switch ([sandBoxArr indexOfObject:fileName]) {
                case 0:
                    path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                    break;
                case 1:
                    path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
                    break;
                case 2:
                    path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
                    break;
                case 3:
                    path = NSTemporaryDirectory();
                    break;
                default:
                    break;
            }
        }
        if (path) {
            ZYSandBoxFileExplorerVC *feVC = [[ZYSandBoxFileExplorerVC alloc] initWithDirectoryPath:path];
            [self.navigationController pushViewController:feVC animated:YES];
        }
    } else {
        NSString *fileName = self.dataSource[indexPath.section];
        NSArray <NSString *>*allComponents = [fileName.lastPathComponent componentsSeparatedByString:@"."];
        if (allComponents.count == 1) {
            fileName = [self.directoryPath stringByAppendingPathComponent:fileName];
            ZYSandBoxFileExplorerVC *feVC = [[ZYSandBoxFileExplorerVC alloc] initWithDirectoryPath:fileName];
            [self.navigationController pushViewController:feVC animated:YES];
        } else {
            if ([allComponents.lastObject isEqualToString:@"json"]) {
                NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
                NSError *error = nil;
                NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
                if (!error) {
                    UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:@"查看json文件" message:content preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *action = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
                    [alertCon addAction:action];
                    [self presentViewController:alertCon animated:YES completion:nil];
                }
            } if ([allComponents.lastObject isEqualToString:@"txt"]) {
                NSString *filePath = [self.directoryPath stringByAppendingPathComponent:fileName];
                ZTTXTReaderVC *readerVC = [ZTTXTReaderVC readerVCWithFilePath:filePath];
                [self.navigationController pushViewController:readerVC animated:YES];
            }
        }
    }
}

- (UITableView *)tableView{
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.rowHeight = 60.0f;
        tableView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:tableView];
        _tableView = tableView;
    }
    return _tableView;
}

- (void)goBack{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    
    
}

@end
