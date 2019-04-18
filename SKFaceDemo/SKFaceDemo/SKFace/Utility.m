//
//  Utility.m
//  SKFaceDemo
//
//  Created by DFSX on 2018/5/2.
//  Copyright © 2018年 Lskyme. All rights reserved.
//

#import "Utility.h"

#import "SKOpenCVFaceDetection.h"

@implementation Utility

+ (LPASVLOFFSCREEN)createOffscreen:(MInt32)width height:(MInt32)height format:(MUInt32)format {
    ASVLOFFSCREEN* pOffscreen = MNull;
    do {
        pOffscreen = (ASVLOFFSCREEN*)malloc(sizeof(ASVLOFFSCREEN));
        if(!pOffscreen)
            break;
        memset(pOffscreen, 0, sizeof(ASVLOFFSCREEN));
        pOffscreen->u32PixelArrayFormat = format;
        pOffscreen->i32Width = width;
        pOffscreen->i32Height = height;
        
        if (ASVL_PAF_NV12 == format || ASVL_PAF_NV21 == format) {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width;        //Y
            pOffscreen->pi32Pitch[1] = pOffscreen->i32Width;        //UV
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * 3/2 * pOffscreen->pi32Pitch[0] ) ;    // Y
            pOffscreen->ppu8Plane[1] = pOffscreen->ppu8Plane[0] + pOffscreen->i32Height * pOffscreen->pi32Pitch[0]; // UV
            memset(pOffscreen->ppu8Plane[0], 0, height * 3/2 * pOffscreen->pi32Pitch[0]);
        } else if (ASVL_PAF_RGB32_R8G8B8A8 == format || ASVL_PAF_RGB32_B8G8R8A8 == format) {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width * 4;
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0]);
        } else if (ASVL_PAF_RGB24_R8G8B8 == format || ASVL_PAF_RGB24_B8G8R8 == format) {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width * 3;
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0]);
        } else if (ASVL_PAF_GRAY == format) {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width;
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0]);
        } else if (ASVL_PAF_YUYV == format) {
            pOffscreen->pi32Pitch[0] = pOffscreen->i32Width * 2;
            pOffscreen->ppu8Plane[0] = (MUInt8*)malloc(height * pOffscreen->pi32Pitch[0]);
        }
        
    }while(false);
    
    return pOffscreen;
}

+ (void)freeOffscreen:(LPASVLOFFSCREEN)pOffscreen {
    if (MNull != pOffscreen) {
        if (MNull != pOffscreen->ppu8Plane[0]) {
            free(pOffscreen->ppu8Plane[0]);
            pOffscreen->ppu8Plane[0] = MNull;
        }
        free(pOffscreen);
        pOffscreen = MNull;
    }
}

+ (LPASVLOFFSCREEN)createOffscreenWithUIImage:(UIImage*)image {
    CGImageRef imageRef = image.CGImage;
    long width = CGImageGetWidth(imageRef);
    long height = CGImageGetHeight(imageRef);
    long pitch = CGImageGetBytesPerRow(imageRef);
    long bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    int bytesPerPixel = (int)bitsPerPixel/8;
    if(bytesPerPixel < 4)
        return MNull;
    
    CFDataRef dataProvider = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    GLubyte *imageBuffer = (GLubyte *)CFDataGetBytePtr(dataProvider);
   
    LPASVLOFFSCREEN pOffscreen = [Utility createOffscreen:(MInt32)width height:(MInt32)height format:ASVL_PAF_RGB24_B8G8R8];
    MUInt32 dstPitch = pOffscreen->pi32Pitch[0];
    MUInt8* dstLine = pOffscreen->ppu8Plane[0];
    GLubyte* sourceLine = imageBuffer;
    for (int j=0; j<height; j++) {
        for (int i=0; i<width; i++) {
            dstLine[i*3] = sourceLine[i*bytesPerPixel+2];
            dstLine[i*3+1] = sourceLine[i*bytesPerPixel+1];
            dstLine[i*3+2] = sourceLine[i*bytesPerPixel];
        }
        sourceLine += pitch;
        dstLine += dstPitch;
    }

    CFRelease(dataProvider);
    
    return pOffscreen;
}

+ (CGRect)imageFaceRectToImageView:(UIImageView *)imageView faceMRect:(MRECT)mRect {
    CGRect frameFaceRect = {0};
    CGRect imageDisplayRect = imageView.bounds;
    CGSize imageSize = imageView.image.size;
    if(imageSize.width * CGRectGetHeight(imageView.bounds) > imageSize.height * CGRectGetWidth(imageView.bounds)) {
        imageDisplayRect.size.height = imageSize.height*CGRectGetWidth(imageView.bounds)/imageSize.width;
        imageDisplayRect.origin.y = (CGRectGetHeight(imageView.bounds) - imageDisplayRect.size.height) / 2;
    } else {
        imageDisplayRect.size.width = imageSize.width * CGRectGetHeight(imageView.bounds) / imageSize.height;
        imageDisplayRect.origin.x = (CGRectGetWidth(imageView.bounds) - imageDisplayRect.size.width) / 2;
    }
    
    MRECT faceRectInImage = mRect;
    UIImageOrientation imageOrientation = imageView.image.imageOrientation;
    switch (imageOrientation) {
        case UIImageOrientationRight: {
            faceRectInImage.left = imageSize.width - mRect.bottom;
            faceRectInImage.right = imageSize.width - mRect.top;
            faceRectInImage.top = mRect.left;
            faceRectInImage.bottom = mRect.right;
        }
            break;
        case UIImageOrientationLeft: {
            faceRectInImage.left = mRect.top;
            faceRectInImage.right = mRect.bottom;
            faceRectInImage.top = imageSize.height - mRect.right;
            faceRectInImage.bottom = imageSize.height - mRect.left;
        }
            break;
        case UIImageOrientationDown: {
            faceRectInImage.left = imageSize.width - mRect.right;
            faceRectInImage.right = imageSize.width - mRect.left;
            faceRectInImage.top = imageSize.height - mRect.bottom;
            faceRectInImage.bottom = imageSize.height - mRect.top;
        }
            break;
        default:
            break;
    }
    
    frameFaceRect.size.width = CGRectGetWidth(imageDisplayRect) * (faceRectInImage.right - faceRectInImage.left) / imageSize.width;
    frameFaceRect.size.height = CGRectGetHeight(imageDisplayRect) * (faceRectInImage.bottom - faceRectInImage.top) / imageSize.height;
    frameFaceRect.origin.x = imageDisplayRect.origin.x + CGRectGetWidth(imageDisplayRect) * faceRectInImage.left / imageSize.width;
    frameFaceRect.origin.y = imageDisplayRect.origin.y + CGRectGetHeight(imageDisplayRect) * faceRectInImage.top / imageSize.height;
    
    return frameFaceRect;
}

+ (CGRect)imageFaceRectToImageView:(UIImageView *)imageView faceRect:(SKOpenCVFaceRect)mRect {
    CGRect frameFaceRect = {0};
    CGRect imageDisplayRect = imageView.bounds;
    CGSize imageSize = imageView.image.size;
    if(imageSize.width * CGRectGetHeight(imageView.bounds) > imageSize.height * CGRectGetWidth(imageView.bounds)) {
        imageDisplayRect.size.height = imageSize.height*CGRectGetWidth(imageView.bounds)/imageSize.width;
        imageDisplayRect.origin.y = (CGRectGetHeight(imageView.bounds) - imageDisplayRect.size.height) / 2;
    } else {
        imageDisplayRect.size.width = imageSize.width * CGRectGetHeight(imageView.bounds) / imageSize.height;
        imageDisplayRect.origin.x = (CGRectGetWidth(imageView.bounds) - imageDisplayRect.size.width) / 2;
    }
    
    SKOpenCVFaceRect faceRectInImage = mRect;
    UIImageOrientation imageOrientation = imageView.image.imageOrientation;
    switch (imageOrientation) {
        case UIImageOrientationRight: {
            faceRectInImage.left = imageSize.width - mRect.bottom;
            faceRectInImage.right = imageSize.width - mRect.top;
            faceRectInImage.top = mRect.left;
            faceRectInImage.bottom = mRect.right;
        }
            break;
        case UIImageOrientationLeft: {
            faceRectInImage.left = mRect.top;
            faceRectInImage.right = mRect.bottom;
            faceRectInImage.top = imageSize.height - mRect.right;
            faceRectInImage.bottom = imageSize.height - mRect.left;
        }
            break;
        case UIImageOrientationDown: {
            faceRectInImage.left = imageSize.width - mRect.right;
            faceRectInImage.right = imageSize.width - mRect.left;
            faceRectInImage.top = imageSize.height - mRect.bottom;
            faceRectInImage.bottom = imageSize.height - mRect.top;
        }
            break;
        default:
            break;
    }
    
    frameFaceRect.size.width = CGRectGetWidth(imageDisplayRect) * (faceRectInImage.right - faceRectInImage.left) / imageSize.width;
    frameFaceRect.size.height = CGRectGetHeight(imageDisplayRect) * (faceRectInImage.bottom - faceRectInImage.top) / imageSize.height;
    frameFaceRect.origin.x = imageDisplayRect.origin.x + CGRectGetWidth(imageDisplayRect) * faceRectInImage.left / imageSize.width;
    frameFaceRect.origin.y = imageDisplayRect.origin.y + CGRectGetHeight(imageDisplayRect) * faceRectInImage.top / imageSize.height;
    
    return frameFaceRect;
}

+ (CGRect)bufferFaceRectToView:(UIView *)view buffer:(CVImageBufferRef)buffer faceRect:(SKOpenCVFaceRect)mRect {
    CGRect frameFaceRect = {0};
    CGRect bufferDisplayRect = view.bounds;
    CGSize bufferSize = CVImageBufferGetDisplaySize(buffer);
    
    if (bufferSize.width * CGRectGetHeight(bufferDisplayRect) > bufferSize.height * CGRectGetWidth(bufferDisplayRect)) {
        bufferDisplayRect.size.height = bufferSize.height * CGRectGetWidth(bufferDisplayRect) / bufferSize.width;
        bufferDisplayRect.origin.y = (CGRectGetHeight(bufferDisplayRect) - bufferDisplayRect.size.height) / 2;
    } else {
        bufferDisplayRect.size.width = bufferSize.width * CGRectGetHeight(bufferDisplayRect) / bufferSize.height;
        bufferDisplayRect.origin.x = (CGRectGetWidth(bufferDisplayRect) - bufferDisplayRect.size.width) / 2;
    }
    
    SKOpenCVFaceRect faceRectInImage = mRect;
    frameFaceRect.size.width = CGRectGetWidth(bufferDisplayRect) * (faceRectInImage.right - faceRectInImage.left) / bufferSize.width;
    frameFaceRect.size.height = CGRectGetHeight(bufferDisplayRect) * (faceRectInImage.bottom - faceRectInImage.top) / bufferSize.height;
    frameFaceRect.origin.x = bufferDisplayRect.origin.x + CGRectGetWidth(bufferDisplayRect) * faceRectInImage.left / bufferSize.width;
    frameFaceRect.origin.y = bufferDisplayRect.origin.y + CGRectGetHeight(bufferDisplayRect) * faceRectInImage.top / bufferSize.height;
    
    return frameFaceRect;
}

@end
