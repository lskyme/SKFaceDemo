//
//  ArcsoftVideoViewController.m
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import "ArcsoftVideoViewController.h"
#import "SKCameraController.h"
#import "SKGLKView.h"
#import "SKArcsoftFaceTracking.h"

#import "SKArcsoftFaceDetection.h"
#import "Utility.h"

//使用arcsoft请到虹软官网注册后填入
#define kArcAppId @""
#define kArcAppKey @""

@interface ArcsoftVideoViewController () <SKCameraControllerDelgate>

@property (weak, nonatomic) IBOutlet UIView *glViewContainer;
@property (weak, nonatomic) IBOutlet UISegmentedControl *markSegmentControl;
@property (weak, nonatomic) IBOutlet UIButton *trackingButton;

@property (nonatomic, strong) SKCameraController *cameraController;
@property (nonatomic, strong) SKGLKView *glView;

@property (nonatomic, strong) SKArcsoftFaceTracking *tracking;

@end

@implementation ArcsoftVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)uiOrientation;
    
    self.cameraController = [[SKCameraController alloc] init];
    self.cameraController.delegate = self;
    [self.cameraController setupCaptureSession:videoOrientation];
    
    self.glView = [[SKGLKView alloc] initWithFrame:_glViewContainer.bounds];
    [_glViewContainer insertSubview:_glView atIndex:0];
    
    [self.cameraController startCaptureSession];
}
    
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_cameraController stopCaptureSession];
    [_tracking destroy];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _glView.frame = _glViewContainer.bounds;
}

- (IBAction)tracking:(id)sender {
    self.tracking = [[SKArcsoftFaceTracking alloc] initWithAppId:kArcAppId appKey:kArcAppKey];
    [_trackingButton setEnabled:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"memory warning!");
}
    
-(void)dealloc {
    NSLog(@"%@ released", self.classForCoder);
}
    
#pragma mark - SKCameraControllerDelgate
    
-(void)skCameraControllerCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (self.tracking.prepared) {
        switch (_markSegmentControl.selectedSegmentIndex) {
            case 0:
            [self.tracking markAreaWithSampleBuffer:sampleBuffer];
            break;
            case 1:
            [self.tracking markFeaturePointsWithSampleBuffer:sampleBuffer];
            break;
            default:
            break;
        }
    }
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.glView renderWithCVPixelBuffer:cameraFrame orientation:0 mirror:NO];
    });
}
    
@end
