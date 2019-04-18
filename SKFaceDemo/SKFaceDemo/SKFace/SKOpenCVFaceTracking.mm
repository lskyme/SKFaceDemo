//
//  SKOpenCVFaceTracking.mm
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import "SKOpenCVFaceTracking.h"

#include <dlib/image_processing.h>
#include <dlib/opencv.h>
#include <opencv2/opencv.hpp>

#import "SKOpenCVFaceDetection.h"

@interface SKOpenCVFaceTracking ()

@property(nonatomic, assign, readwrite) BOOL prepared;

@end

@implementation SKOpenCVFaceTracking {
    
    cv::CascadeClassifier faceDetector;
    dlib::shape_predictor sp;
    
}
    
-(instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
        [self setupEngines];
    }
    return self;
}
    
-(void)setupEngines {
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2"
                                                                ofType:@"xml"];
    const CFIndex CASCADE_NAME_LEN = 2048;
    char *CASCADE_NAME = (char *) malloc(CASCADE_NAME_LEN);
    CFStringGetFileSystemRepresentation( (CFStringRef)faceCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
    faceDetector.load(CASCADE_NAME);
    
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    dlib::deserialize(modelFileNameCString) >> sp;
    
    self.prepared = YES;
}
    
- (CVImageBufferRef)markFeaturePointsWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!self.prepared) {
        [self setupEngines];
    }
    
    cv::Mat cvImg = [SKOpenCVFaceTracking matFromBuffer:sampleBuffer];
    
    cv::Mat grayImg;
    cv::cvtColor(cvImg, grayImg, CV_BGRA2GRAY);
    cv::equalizeHist(grayImg, grayImg);
    
    cv::vector<cv::Rect> faceRects;
    double scalingFactor = 1.1;
    int minNeighbors = 2;
    int flags = 0;
    cv::Size minimumSize(30,30);
    faceDetector.detectMultiScale(grayImg, faceRects,
                                  scalingFactor, minNeighbors, flags, cv::Size(30, 30));
    
    cv::cvtColor(cvImg, cvImg, CV_BGRA2BGR);
    
    dlib::cv_image<dlib::bgr_pixel> dlibImg(cvImg);
    
    for(unsigned int i= 0;i < faceRects.size();i++){
        const cv::Rect& face = faceRects[i];
        dlib::rectangle dlibRect(face.x, face.y, face.x + face.width, face.y + face.height);
        dlib::full_object_detection shape = sp(dlibImg, dlibRect);
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
            dlib::point p = shape.part(k);
            dlib::draw_solid_circle(dlibImg, p, 3, dlib::bgr_pixel(0, 0, 255));
        }
    }
    
    cv::Mat newCVImg = dlib::toMat(dlibImg);
    
    return [SKOpenCVFaceTracking ImageBufferFromMat:newCVImg];
}
    
- (CVImageBufferRef)markAreaWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!self.prepared) {
        [self setupEngines];
    }
    
    cv::Mat cvImg = [SKOpenCVFaceTracking matFromBuffer:sampleBuffer];
    
    cv::Mat grayImg;
    cv::cvtColor(cvImg, grayImg, CV_BGRA2GRAY);
    cv::equalizeHist(grayImg, grayImg);
    
    cv::vector<cv::Rect> faceRects;
    double scalingFactor = 1.1;
    int minNeighbors = 2;
    int flags = 0;
    cv::Size minimumSize(30,30);
    faceDetector.detectMultiScale(grayImg, faceRects,
                                  scalingFactor, minNeighbors, flags, cv::Size(30, 30));
    
    cv::cvtColor(cvImg, cvImg, CV_BGRA2BGR);
    
    dlib::cv_image<dlib::bgr_pixel> dlibImg(cvImg);
    
    for(unsigned int i= 0;i < faceRects.size();i++){
        const cv::Rect& face = faceRects[i];
        cv::rectangle(cvImg, cv::Point(face.x, face.y), cv::Point(face.x + face.width, face.y + face.height), cv::Scalar(0, 0, 255));
    }
    
    return [SKOpenCVFaceTracking ImageBufferFromMat:cvImg];
}
    
+ (cv::Mat)matFromBuffer:(CMSampleBufferRef)buffer {
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(buffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    cv::Mat mat = cv::Mat(bufferHeight, bufferWidth, CV_8UC4, pixel, CVPixelBufferGetBytesPerRow(pixelBuffer));
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    return mat;
}
    
+ (CVImageBufferRef)ImageBufferFromMat:(cv::Mat)mat {
    
    cv::cvtColor(mat, mat, CV_BGR2BGRA);
    
    int width = mat.cols;
    int height = mat.rows;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             // [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             // [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             [NSNumber numberWithInt:width], kCVPixelBufferWidthKey,
                             [NSNumber numberWithInt:height], kCVPixelBufferHeightKey,
                             nil];
    
    CVPixelBufferRef imageBuffer;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorMalloc, width, height, kCVPixelFormatType_32BGRA, (CFDictionaryRef) CFBridgingRetain(options), &imageBuffer) ;
    
    
    NSParameterAssert(status == kCVReturnSuccess && imageBuffer != NULL);
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *base = CVPixelBufferGetBaseAddress(imageBuffer) ;
    memcpy(base, mat.data, mat.total()*4);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    return imageBuffer;
}

@end
