//
//  SKOpenCVFaceDetection.mm
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import "SKOpenCVFaceDetection.h"

#include <dlib/image_processing.h>
#include <dlib/opencv.h>
#include <opencv2/opencv.hpp>

@implementation SKOpenCVFaceInfo
@end

@interface SKOpenCVFaceDetection ()
    
@property(nonatomic, assign, readwrite) BOOL prepared;

@end

@implementation SKOpenCVFaceDetection {
    
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
    
- (void)setupEngines {
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2"
                                                                ofType:@"xml"];
    const CFIndex CASCADE_NAME_LEN = 2048;
    char *CASCADE_NAME = (char *) malloc(CASCADE_NAME_LEN);
    CFStringGetFileSystemRepresentation((CFStringRef)faceCascadePath, CASCADE_NAME, CASCADE_NAME_LEN);
    faceDetector.load(CASCADE_NAME);
    
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    dlib::deserialize(modelFileNameCString) >> sp;
    
    self.prepared = YES;
}
    
- (UIImage *)markFeaturePointsWithImage:(UIImage *)image faceInfos:(NSArray *)faceinfos {
    if (!self.prepared) {
        [self setupEngines];
    }
    
    cv::Mat img = [SKOpenCVFaceDetection cvMatFromUIImage:image];
    cv::cvtColor(img, img, CV_RGBA2RGB);
    dlib::cv_image<dlib::rgb_pixel> dlibImg(img);
    
    for(unsigned int i= 0;i < faceinfos.count;i++) {
        id obj = faceinfos[i];
        if ([obj isKindOfClass:[SKOpenCVFaceInfo class]]) {
            SKOpenCVFaceRect rect = ((SKOpenCVFaceInfo *)obj).rect;
            dlib::rectangle dlibRect(rect.left, rect.top, rect.right, rect.bottom);
            dlib::full_object_detection shape = sp(dlibImg, dlibRect);
            for (unsigned long k = 0; k < shape.num_parts(); k++) {
                dlib::point p = shape.part(k);
                dlib::draw_solid_circle(dlibImg, p, 3, dlib::rgb_pixel(255, 0, 0));
            }
        }
    }
    
    cv::Mat newCVImg = dlib::toMat(dlibImg);
    return [SKOpenCVFaceDetection UIImageFromCVMat:newCVImg];
}
    
- (NSArray *)detectReturnRectsWithImage:(UIImage *)image {
    if (!self.prepared) {
        [self setupEngines];
    }
    
    cv::Mat img = [SKOpenCVFaceDetection cvMatFromUIImage:image];
    
    cv::Mat grayImg;
    cv::cvtColor(img, grayImg, CV_RGBA2GRAY);
    cv::equalizeHist(grayImg, grayImg);
    
    cv::vector<cv::Rect> faceRects;
    double scalingFactor = 1.1;
    int minNeighbors = 2;
    int flags = 0;
    cv::Size minimumSize(30,30);
    faceDetector.detectMultiScale(grayImg, faceRects,
                                  scalingFactor, minNeighbors, flags, cv::Size(30, 30));
    
    NSMutableArray *infos = [[NSMutableArray alloc] initWithCapacity:0];
    for(unsigned int i= 0;i < faceRects.size();i++) {
        const cv::Rect& face = faceRects[i];
        SKOpenCVFaceInfo *info = [[SKOpenCVFaceInfo alloc] init];
        SKOpenCVFaceRect rect;
        rect.left = face.x;
        rect.top = face.y;
        rect.right = face.x + face.width;
        rect.bottom = face.y + face.height;
        info.rect = rect;
        [infos addObject:info];
    }
    
    return infos;
}
    
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols;
    CGFloat rows;
    if (image.imageOrientation == UIImageOrientationLeft || image.imageOrientation == UIImageOrientationRight) {
        cols = image.size.height;
        rows = image.size.width;
    } else {
        cols = image.size.width;
        rows = image.size.height;
    }
    cv::Mat cvMat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    cvMat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}
    
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}
    
@end

