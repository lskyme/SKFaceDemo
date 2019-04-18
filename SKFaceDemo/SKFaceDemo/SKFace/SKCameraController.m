//
//  SKCameraController.m
//  SKFaceDemo
//
//  Created by DFSX on 2018/5/2.
//  Copyright © 2018年 Lskyme. All rights reserved.
//

#import "SKCameraController.h"

@interface SKCameraController () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureSession    *captureSession;
    AVCaptureConnection *videoConnection;
}
@end

@implementation SKCameraController

- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
        if ([device position] == position) {
            return device;
        }
    return nil;
}

- (BOOL)setupCaptureSession:(AVCaptureVideoOrientation)videoOrientation {
    captureSession = [[AVCaptureSession alloc] init];
    
    [captureSession beginConfiguration];
    
    AVCaptureDevice *videoDevice = [self videoDeviceWithPosition:AVCaptureDevicePositionFront];
    
    AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if ([captureSession canAddInput:videoIn]) {
        [captureSession addInput:videoIn];
    }
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
    
//#ifdef __OUTPUT_BGRA__
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//#else
//    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//#endif
    [videoOut setVideoSettings:dic];
    
    dispatch_queue_t videoCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
    [videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
    
    if ([captureSession canAddOutput:videoOut]) {
        [captureSession addOutput:videoOut];
    }
    
    videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    
    if (videoConnection.supportsVideoMirroring) {
        [videoConnection setVideoMirrored:YES];
    }
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:videoOrientation];
    }
    
    if ([captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    [captureSession commitConfiguration];
    
    return YES;
}

- (void)startCaptureSession {
    if (!captureSession) {
        return;
    }
    if (!captureSession.isRunning) {
        [captureSession startRunning];
    }
}

- (void)stopCaptureSession {
    [captureSession stopRunning];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (connection == videoConnection) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(skCameraControllerCaptureOutput:didOutputSampleBuffer:fromConnection:)]) {
            [self.delegate skCameraControllerCaptureOutput:output didOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
}

@end
