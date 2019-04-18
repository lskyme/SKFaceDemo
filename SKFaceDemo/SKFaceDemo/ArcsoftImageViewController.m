//
//  ArcsoftImageViewController.m
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import "ArcsoftImageViewController.h"
#import "SKArcsoftFaceDetection.h"
#import "UIAlertController+Extension.h"
#import "Utility.h"
#import <Photos/Photos.h>

//使用arcsoft请到虹软官网注册后填入
#define kArcAppId @""
#define kArcAppKey @""

@interface ArcsoftImageViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
    
@property (weak, nonatomic) IBOutlet UIView *imageViewContainer;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *markSegmentControl;
@property (weak, nonatomic) IBOutlet UIButton *detectButton;

@property(nonatomic, strong) NSMutableArray *faceViews;
@property(nonatomic, copy) NSArray *faceInfos;
@property(nonatomic, strong) UIImage *originalImage;

@property(nonatomic, strong) SKArcsoftFaceDetection *detection;

@property(nonatomic, assign) BOOL isGotoImagePicker;
@end

@implementation ArcsoftImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.faceViews = [[NSMutableArray alloc] init];
    self.detection = [[SKArcsoftFaceDetection alloc] initWithAppId:kArcAppId appKey:kArcAppKey];
    self.faceInfos = [[NSArray alloc] init];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (!_isGotoImagePicker) {
        [_detection destroy];
    }
}

- (IBAction)selectImage:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    imagePicker.allowsEditing = NO;
    _isGotoImagePicker = YES;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)detectImage:(id)sender {
    if (_originalImage == nil) {
        [UIAlertController showOneActionWithViewController:self title:@"警告" message:@"没有图片可检测，请先选择一张图片" actionTitle:@"确定" handler:nil];
        return;
    }
    
    [_detectButton setEnabled:NO];
    
    _faceInfos = [self.detection detectReturnRectsWithImage:_originalImage];
    
    switch (_markSegmentControl.selectedSegmentIndex) {
        case 0:
        [self setupFaceViews];
        break;
        case 1: {
            UIImage *markedImage = [self.detection markFeaturePointsWithImage:_originalImage faceInfos:_faceInfos];
            self.imageView.image = markedImage;
        }
        break;
        default:
        break;
    }
    
}

- (IBAction)markChanged:(id)sender {
    if (!self.imageView.image) {
        return;
    }
    
    switch (_markSegmentControl.selectedSegmentIndex) {
        case 0: {
            self.imageView.image = _originalImage;
            [self setupFaceViews];
        }
        break;
        case 1: {
            [self clearFaceViews];
            UIImage *markedImage = [self.detection markFeaturePointsWithImage:_originalImage faceInfos:_faceInfos];
            self.imageView.image = markedImage;
        }
        break;
        default:
        break;
    }
}
    
- (void)setupFaceViews {
    for (int face=0; face<_faceInfos.count; face++) {
        SKArcsoftFaceInfo *faceInfo = [_faceInfos objectAtIndex:face];
        CGRect frame = [Utility imageFaceRectToImageView:self.imageView faceMRect:faceInfo.rect];
        UIView *faceView = [[UIView alloc] initWithFrame:frame];
        faceView.backgroundColor = UIColor.clearColor;
        faceView.layer.borderColor = UIColor.redColor.CGColor;
        faceView.layer.borderWidth = 2;
        [self.faceViews addObject:faceView];
        [_imageViewContainer addSubview:faceView];
    }
}
    
- (void)clearFaceViews {
    for (UIView *view in self.faceViews) {
        [view removeFromSuperview];
    }
    [self.faceViews removeAllObjects];
}
    
- (void)setOriginalImage:(UIImage *)originalImage {
    if (![_originalImage isEqual:originalImage]) {
        _originalImage = originalImage;
        _imageView.image = originalImage;
    }
}
    
-(void)dealloc {
    NSLog(@"%@ released", self.classForCoder);
}

#pragma mark - UIImagePickerControllerDelegate
    
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    _isGotoImagePicker = NO;
}
    
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self clearFaceViews];
    self.faceInfos = [[NSArray alloc] init];
    
    [_detectButton setEnabled:YES];
    
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    self.originalImage = originalImage;
    [picker dismissViewControllerAnimated:YES completion:nil];
    _isGotoImagePicker = NO;
}
    
@end
