//
//  SKCameraController.h
//  SKFaceDemo
//
//  Created by DFSX on 2018/5/2.
//  Copyright © 2018年 Lskyme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol SKCameraControllerDelgate <NSObject>

- (void)skCameraControllerCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;

@end

@interface SKCameraController : NSObject

@property (nonatomic, weak) id <SKCameraControllerDelgate> delegate;

- (BOOL)setupCaptureSession:(AVCaptureVideoOrientation)videoOrientation;
- (void)startCaptureSession;
- (void)stopCaptureSession;

@end
