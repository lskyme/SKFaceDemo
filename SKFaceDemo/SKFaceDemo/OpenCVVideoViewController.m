//
//  OpenCVVideoViewController.m
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import "OpenCVVideoViewController.h"
#import "SKCameraController.h"
#import "SKGLKView.h"
#import "SKOpenCVFaceTracking.h"

#import "SKOpenCVFaceDetection.h"
#import "Utility.h"

@interface OpenCVVideoViewController () <SKCameraControllerDelgate>

@property (weak, nonatomic) IBOutlet UIView *glViewContainer;
@property (weak, nonatomic) IBOutlet UISegmentedControl *markSegmentControl;
@property (weak, nonatomic) IBOutlet UIButton *trackingButton;
    
@property (nonatomic, strong) SKCameraController *cameraController;
@property (nonatomic, strong) SKGLKView *glView;
    
@property (nonatomic, strong) SKOpenCVFaceTracking *tracking;
    
@end

@implementation OpenCVVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)uiOrientation;
    
    self.cameraController = [[SKCameraController alloc] init];
    self.cameraController.delegate = self;
    [self.cameraController setupCaptureSession:videoOrientation];
    
    self.glView = [[SKGLKView alloc] initWithFrame:_glViewContainer.bounds];
    [_glViewContainer insertSubview:self.glView atIndex:0];
    
    [self.cameraController startCaptureSession];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.cameraController stopCaptureSession];
}
    
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _glView.frame = _glViewContainer.bounds;
}

- (IBAction)tracking:(id)sender {
    self.tracking = [[SKOpenCVFaceTracking alloc] init];
    [_trackingButton setEnabled:NO];
}

- (void)dealloc {
    NSLog(@"%@ released", self.classForCoder);
}
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"memory warning!");
}

#pragma mark - SKCameraControllerDelgate
    
-(void)skCameraControllerCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.tracking.prepared) {
        CVImageBufferRef bufferRef = NULL;
        switch (_markSegmentControl.selectedSegmentIndex) {
            case 0:
            bufferRef = [self.tracking markAreaWithSampleBuffer:sampleBuffer];
            break;
            case 1:
            bufferRef = [self.tracking markFeaturePointsWithSampleBuffer:sampleBuffer];
            default:
            break;
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.glView renderWithCVPixelBuffer:bufferRef orientation:0 mirror:NO];
        });
        CFRelease(bufferRef);
    } else {
        CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.glView renderWithCVPixelBuffer:cameraFrame orientation:0 mirror:NO];
        });
    }
}
    
@end
