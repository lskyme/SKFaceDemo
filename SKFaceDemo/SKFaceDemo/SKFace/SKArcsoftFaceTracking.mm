//
//  SKArcsoftFaceTracking.mm
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import "SKArcsoftFaceTracking.h"
#import "Utility.h"
#import "asvloffscreen.h"
#import "ammem.h"
#import <arcsoft_fsdk_face_tracking/arcsoft_fsdk_face_tracking.h>
#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#include <dlib/array2d.h>

#include <dlib/opencv.h>
#include <opencv2/opencv.hpp>

#import "SKOpenCVFaceTracking.h"

#define AFR_FT_MEM_SIZE         1024*1024*5
#define AFR_FT_MAX_FACE_NUM     5

@interface SKArcsoftFaceTracking () {
    
    MHandle          _arcsoftFT;
    MVoid*           _memBufferFT;
    
    const char*      _arcAppId;
    const char*      _arcAppKey;
    
    dlib::shape_predictor sp;
    
    SKOpenCVFaceRect lastFaceRect;
    
}

@property(nonatomic, assign, readwrite) BOOL prepared;

@end

@implementation SKArcsoftFaceTracking

- (instancetype)initWithAppId:(NSString *)appId appKey:(NSString *)appKey {
    self = [super init];
    if (self) {
        _prepared = NO;
        _arcAppId = [appId UTF8String];
        _arcAppKey = [appKey UTF8String];
        [self setupEngines];
    }
    return self;
}
    
- (void)setupEngines {
    _memBufferFT = MMemAlloc(MNull, AFR_FT_MEM_SIZE);
    MMemSet(_memBufferFT, 0, AFR_FT_MEM_SIZE);
    AFT_FSDK_InitialFaceEngine((MPChar)_arcAppId, (MPChar)_arcAppKey, (MByte*)_memBufferFT, AFR_FT_MEM_SIZE, &_arcsoftFT, AFT_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FT_MAX_FACE_NUM);
    
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    dlib::deserialize(modelFileNameCString) >> sp;
    
    self.prepared = YES;
}
    
- (void)destroy {
    AFT_FSDK_UninitialFaceEngine(_arcsoftFT);
    _arcsoftFT = MNull;
    if(_memBufferFT != MNull)
    {
        MMemFree(MNull, _memBufferFT);
        _memBufferFT = MNull;
    }
}

- (void)markFeaturePointsWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!self.prepared) {
        [self setupEngines];
    }
    
    if (NULL == sampleBuffer) {
        return;
    }
    
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    OSType pixelType =  CVPixelBufferGetPixelFormatType(cameraFrame);
    
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    
    ASVLOFFSCREEN* pOff = MNull;
    
    if (kCVPixelFormatType_32BGRA == pixelType) {
        pOff = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_RGB32_B8G8R8A8];
        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
        uint8_t  *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(cameraFrame);
        
        if (rowBytePlane0 == pOff->pi32Pitch[0]) {
            memcpy(pOff->ppu8Plane[0], baseAddress, bufferHeight * pOff->pi32Pitch[0]);
        } else {
            for (int i = 0; i < bufferHeight; ++i) {
                memcpy(pOff->ppu8Plane[0] + i * pOff->pi32Pitch[0] , baseAddress + i * rowBytePlane0, pOff->pi32Pitch[0] );
            }
        }
    } else if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelType || kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelType) {
        pOff = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_NV12];
        uint8_t  *baseAddress0 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0); // Y
        uint8_t  *baseAddress1 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1); // UV
        
        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
        size_t   rowBytePlane1 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 1);
        
        // Y data
        if (rowBytePlane0 == pOff->pi32Pitch[0]) {
            memcpy(pOff->ppu8Plane[0], baseAddress0, rowBytePlane0*bufferHeight);
        } else {
            for (int i = 0; i < bufferHeight; ++i) {
                memcpy(pOff->ppu8Plane[0] + i * bufferWidth, baseAddress0 + i * rowBytePlane0, bufferWidth);
            }
        }
        
        // uv data
        if (rowBytePlane1 == pOff->pi32Pitch[1]) {
            memcpy(pOff->ppu8Plane[1], baseAddress1, rowBytePlane1 * bufferHeight / 2);
        } else {
            uint8_t  *pPlanUV = pOff->ppu8Plane[1];
            for (int i = 0; i < bufferHeight / 2; ++i) {
                memcpy(pPlanUV + i * bufferWidth, baseAddress1+ i * rowBytePlane1, bufferWidth);
            }
        }
    }
    
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    if (pOff != MNull) {
        LPAFT_FSDK_FACERES pFaceResFT = MNull;
        AFT_FSDK_FaceFeatureDetect(_arcsoftFT, pOff, &pFaceResFT);
        
        if(pFaceResFT && pFaceResFT->nFace > 0) {
            CVPixelBufferLockBaseAddress(cameraFrame, 0);
            unsigned char *data = (unsigned char *)CVPixelBufferGetBaseAddress(cameraFrame);

            dlib::array2d<dlib::bgr_pixel> img;
            img.set_size(bufferHeight, bufferWidth);
            img.reset();
            long position = 0;

            while (img.move_next()) {
                dlib::bgr_pixel& pixel = img.element();

                long bufferLocation = position * 4;
                char b = data[bufferLocation];
                char g = data[bufferLocation + 1];
                char r = data[bufferLocation + 2];

                dlib::bgr_pixel newpixel(b, g, r);
                pixel = newpixel;

                position++;
            }

            for (int face=0; face<pFaceResFT->nFace; face++) {
                dlib::rectangle dlibRect(pFaceResFT->rcFace[face].left, pFaceResFT->rcFace[face].top, pFaceResFT->rcFace[face].right, pFaceResFT->rcFace[face].bottom);
                dlib::full_object_detection shape = sp(img, dlibRect);
                for (unsigned long k = 0; k < shape.num_parts(); k++) {
                    dlib::point p = shape.part(k);
                    dlib::draw_solid_circle(img, p, 3, dlib::rgb_pixel(255, 0, 0));
                }
            }

            img.reset();
            position = 0;
            while (img.move_next()) {
                dlib::bgr_pixel& pixel = img.element();
                long bufferLocation = position * 4;
                data[bufferLocation] = pixel.blue;
                data[bufferLocation + 1] = pixel.green;
                data[bufferLocation + 2] = pixel.red;

                position++;
            }

            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
        }
        [Utility freeOffscreen:pOff];
    }
}
- (void)markAreaWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!self.prepared) {
        [self setupEngines];
    }
    
    if (NULL == sampleBuffer) {
        return;
    }
    
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
    OSType pixelType =  CVPixelBufferGetPixelFormatType(cameraFrame);
    
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    
    ASVLOFFSCREEN* pOff = MNull;
    
    if (kCVPixelFormatType_32BGRA == pixelType) {
        pOff = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_RGB32_B8G8R8A8];
        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
        uint8_t  *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(cameraFrame);
        
        if (rowBytePlane0 == pOff->pi32Pitch[0]) {
            memcpy(pOff->ppu8Plane[0], baseAddress, bufferHeight * pOff->pi32Pitch[0]);
        } else {
            for (int i = 0; i < bufferHeight; ++i) {
                memcpy(pOff->ppu8Plane[0] + i * pOff->pi32Pitch[0] , baseAddress + i * rowBytePlane0, pOff->pi32Pitch[0] );
            }
        }
    } else if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelType || kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelType) {
        pOff = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_NV12];
        uint8_t  *baseAddress0 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0); // Y
        uint8_t  *baseAddress1 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1); // UV
        
        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
        size_t   rowBytePlane1 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 1);
        
        // Y data
        if (rowBytePlane0 == pOff->pi32Pitch[0]) {
            memcpy(pOff->ppu8Plane[0], baseAddress0, rowBytePlane0*bufferHeight);
        } else {
            for (int i = 0; i < bufferHeight; ++i) {
                memcpy(pOff->ppu8Plane[0] + i * bufferWidth, baseAddress0 + i * rowBytePlane0, bufferWidth);
            }
        }
        
        // uv data
        if (rowBytePlane1 == pOff->pi32Pitch[1]) {
            memcpy(pOff->ppu8Plane[1], baseAddress1, rowBytePlane1 * bufferHeight / 2);
        } else {
            uint8_t  *pPlanUV = pOff->ppu8Plane[1];
            for (int i = 0; i < bufferHeight / 2; ++i) {
                memcpy(pPlanUV + i * bufferWidth, baseAddress1+ i * rowBytePlane1, bufferWidth);
            }
        }
    }
    
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    if (pOff != MNull) {
        LPAFT_FSDK_FACERES pFaceResFT = MNull;
        AFT_FSDK_FaceFeatureDetect(_arcsoftFT, pOff, &pFaceResFT);
        
        if(pFaceResFT && pFaceResFT->nFace > 0) {
            CVPixelBufferLockBaseAddress(cameraFrame, 0);
            unsigned char *data = (unsigned char *)CVPixelBufferGetBaseAddress(cameraFrame);
            
            dlib::array2d<dlib::bgr_pixel> img;
            img.set_size(bufferHeight, bufferWidth);
            img.reset();
            long position = 0;
            
            while (img.move_next()) {
                dlib::bgr_pixel& pixel = img.element();
                
                long bufferLocation = position * 4;
                char b = data[bufferLocation];
                char g = data[bufferLocation + 1];
                char r = data[bufferLocation + 2];
                
                dlib::bgr_pixel newpixel(b, g, r);
                pixel = newpixel;
                
                position++;
            }
            
            for (int face=0; face<pFaceResFT->nFace; face++) {
                dlib::rectangle dlibRect(pFaceResFT->rcFace[face].left, pFaceResFT->rcFace[face].top, pFaceResFT->rcFace[face].right, pFaceResFT->rcFace[face].bottom);
                dlib::draw_rectangle(img, dlibRect, dlib::rgb_pixel(255, 0, 0));
            }
            
            img.reset();
            position = 0;
            while (img.move_next()) {
                dlib::bgr_pixel& pixel = img.element();
                long bufferLocation = position * 4;
                data[bufferLocation] = pixel.blue;
                data[bufferLocation + 1] = pixel.green;
                data[bufferLocation + 2] = pixel.red;
                
                position++;
            }
            
            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
        }
        [Utility freeOffscreen:pOff];
    }
}

//- (void)markFeaturePointsWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
//    if (!self.prepared) {
//        [self setupEngines];
//    }
//
//    if (NULL == sampleBuffer) {
//        return;
//    }
//
//    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
//    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
//    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
//    OSType pixelType =  CVPixelBufferGetPixelFormatType(cameraFrame);
//
//    CVPixelBufferLockBaseAddress(cameraFrame, 0);
//
//    ASVLOFFSCREEN* pOff = MNull;
//
//    if (kCVPixelFormatType_32BGRA == pixelType) {
//        pOff = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_RGB32_B8G8R8A8];
//        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
//        uint8_t  *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(cameraFrame);
//
//        if (rowBytePlane0 == pOff->pi32Pitch[0]) {
//            memcpy(pOff->ppu8Plane[0], baseAddress, bufferHeight * pOff->pi32Pitch[0]);
//        } else {
//            for (int i = 0; i < bufferHeight; ++i) {
//                memcpy(pOff->ppu8Plane[0] + i * pOff->pi32Pitch[0] , baseAddress + i * rowBytePlane0, pOff->pi32Pitch[0] );
//            }
//        }
//    } else if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelType || kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelType) {
//        pOff = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_NV12];
//        uint8_t  *baseAddress0 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0); // Y
//        uint8_t  *baseAddress1 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1); // UV
//
//        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
//        size_t   rowBytePlane1 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 1);
//
//        // Y data
//        if (rowBytePlane0 == pOff->pi32Pitch[0]) {
//            memcpy(pOff->ppu8Plane[0], baseAddress0, rowBytePlane0*bufferHeight);
//        } else {
//            for (int i = 0; i < bufferHeight; ++i) {
//                memcpy(pOff->ppu8Plane[0] + i * bufferWidth, baseAddress0 + i * rowBytePlane0, bufferWidth);
//            }
//        }
//
//        // uv data
//        if (rowBytePlane1 == pOff->pi32Pitch[1]) {
//            memcpy(pOff->ppu8Plane[1], baseAddress1, rowBytePlane1 * bufferHeight / 2);
//        } else {
//            uint8_t  *pPlanUV = pOff->ppu8Plane[1];
//            for (int i = 0; i < bufferHeight / 2; ++i) {
//                memcpy(pPlanUV + i * bufferWidth, baseAddress1+ i * rowBytePlane1, bufferWidth);
//            }
//        }
//    }
//
//    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
//
//    if (pOff != MNull) {
//        LPAFT_FSDK_FACERES pFaceResFT = MNull;
//        AFT_FSDK_FaceFeatureDetect(_arcsoftFT, pOff, &pFaceResFT);
//
//        if(pFaceResFT && pFaceResFT->nFace > 0) {
//            CVPixelBufferLockBaseAddress(cameraFrame, 0);
//            unsigned char *data = (unsigned char *)CVPixelBufferGetBaseAddress(cameraFrame);
//
//            dlib::array2d<dlib::bgr_pixel> img;
//            img.set_size(bufferHeight, bufferWidth);
//            img.reset();
//            long position = 0;
//
//            while (img.move_next()) {
//                dlib::bgr_pixel& pixel = img.element();
//
//                long bufferLocation = position * 4;
//                char b = data[bufferLocation];
//                char g = data[bufferLocation + 1];
//                char r = data[bufferLocation + 2];
//
//                dlib::bgr_pixel newpixel(b, g, r);
//                pixel = newpixel;
//
//                position++;
//            }
//
//            for (int face=0; face<pFaceResFT->nFace; face++) {
//                dlib::rectangle dlibRect(pFaceResFT->rcFace[face].left, pFaceResFT->rcFace[face].top, pFaceResFT->rcFace[face].right, pFaceResFT->rcFace[face].bottom);
//                dlib::full_object_detection shape = sp(img, dlibRect);
//                for (unsigned long k = 0; k < shape.num_parts(); k++) {
//                    dlib::point p = shape.part(k);
//                    dlib::draw_solid_circle(img, p, 3, dlib::rgb_pixel(255, 0, 0));
//                }
//            }
//
//            img.reset();
//            position = 0;
//            while (img.move_next()) {
//                dlib::bgr_pixel& pixel = img.element();
//                long bufferLocation = position * 4;
//                data[bufferLocation] = pixel.blue;
//                data[bufferLocation + 1] = pixel.green;
//                data[bufferLocation + 2] = pixel.red;
//
//                position++;
//            }
//
//            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
//        }
//        [Utility freeOffscreen:pOff];
//    }
//}
//- (void)markAreaWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
//    if (!self.prepared) {
//        [self setupEngines];
//    }
//
//    if (NULL == sampleBuffer) {
//        return;
//    }
//
//    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
//    int bufferWidth = (int) CVPixelBufferGetWidth(cameraFrame);
//    int bufferHeight = (int) CVPixelBufferGetHeight(cameraFrame);
//    OSType pixelType =  CVPixelBufferGetPixelFormatType(cameraFrame);
//
//    CVPixelBufferLockBaseAddress(cameraFrame, 0);
//
//    ASVLOFFSCREEN* pOff = MNull;
//
//    if (kCVPixelFormatType_32BGRA == pixelType) {
//        pOff = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_RGB32_B8G8R8A8];
//        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
//        uint8_t  *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(cameraFrame);
//
//        if (rowBytePlane0 == pOff->pi32Pitch[0]) {
//            memcpy(pOff->ppu8Plane[0], baseAddress, bufferHeight * pOff->pi32Pitch[0]);
//        } else {
//            for (int i = 0; i < bufferHeight; ++i) {
//                memcpy(pOff->ppu8Plane[0] + i * pOff->pi32Pitch[0] , baseAddress + i * rowBytePlane0, pOff->pi32Pitch[0] );
//            }
//        }
//    } else if (kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange == pixelType || kCVPixelFormatType_420YpCbCr8BiPlanarFullRange == pixelType) {
//        pOff = [Utility createOffscreen:bufferWidth height:bufferHeight format:ASVL_PAF_NV12];
//        uint8_t  *baseAddress0 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0); // Y
//        uint8_t  *baseAddress1 = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1); // UV
//
//        size_t   rowBytePlane0 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
//        size_t   rowBytePlane1 = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 1);
//
//        // Y data
//        if (rowBytePlane0 == pOff->pi32Pitch[0]) {
//            memcpy(pOff->ppu8Plane[0], baseAddress0, rowBytePlane0*bufferHeight);
//        } else {
//            for (int i = 0; i < bufferHeight; ++i) {
//                memcpy(pOff->ppu8Plane[0] + i * bufferWidth, baseAddress0 + i * rowBytePlane0, bufferWidth);
//            }
//        }
//
//        // uv data
//        if (rowBytePlane1 == pOff->pi32Pitch[1]) {
//            memcpy(pOff->ppu8Plane[1], baseAddress1, rowBytePlane1 * bufferHeight / 2);
//        } else {
//            uint8_t  *pPlanUV = pOff->ppu8Plane[1];
//            for (int i = 0; i < bufferHeight / 2; ++i) {
//                memcpy(pPlanUV + i * bufferWidth, baseAddress1+ i * rowBytePlane1, bufferWidth);
//            }
//        }
//    }
//
//    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
//    if (pOff != MNull) {
//        LPAFT_FSDK_FACERES pFaceResFT = MNull;
//        AFT_FSDK_FaceFeatureDetect(_arcsoftFT, pOff, &pFaceResFT);
//
//        if(pFaceResFT && pFaceResFT->nFace > 0) {
//            CVPixelBufferLockBaseAddress(cameraFrame, 0);
//            unsigned char *data = (unsigned char *)CVPixelBufferGetBaseAddress(cameraFrame);
//
//            dlib::array2d<dlib::bgr_pixel> img;
//            img.set_size(bufferHeight, bufferWidth);
//            img.reset();
//            long position = 0;
//
//            while (img.move_next()) {
//                dlib::bgr_pixel& pixel = img.element();
//
//                long bufferLocation = position * 4;
//                char b = data[bufferLocation];
//                char g = data[bufferLocation + 1];
//                char r = data[bufferLocation + 2];
//
//                dlib::bgr_pixel newpixel(b, g, r);
//                pixel = newpixel;
//
//                position++;
//            }
//
//            for (int face=0; face<pFaceResFT->nFace; face++) {
//                MRECT faceRect = pFaceResFT->rcFace[face];
//                cv::rectangle(img, cv::Point(faceRect.left, faceRect.top), cv::Point(faceRect.right, faceRect.bottom), cv::Scalar(0, 0, 255));
//            }
//
//            img.reset();
//            position = 0;
//            while (img.move_next()) {
//                dlib::bgr_pixel& pixel = img.element();
//                long bufferLocation = position * 4;
//                data[bufferLocation] = pixel.blue;
//                data[bufferLocation + 1] = pixel.green;
//                data[bufferLocation + 2] = pixel.red;
//
//                position++;
//            }
//
//            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
//        }
//        [Utility freeOffscreen:pOff];
//    }
//}

@end
