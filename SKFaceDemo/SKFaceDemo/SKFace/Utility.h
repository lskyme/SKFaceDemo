//
//  Utility.h
//  SKFaceDemo
//
//  Created by DFSX on 2018/5/2.
//  Copyright © 2018年 Lskyme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>
#import "asvloffscreen.h"
#import <UIKit/UIKit.h>

#import "SKOpenCVFaceDetection.h"

@interface Utility : NSObject

+ (LPASVLOFFSCREEN)createOffscreen:(MInt32)width height:(MInt32)height format:(MUInt32)format;
+ (void)freeOffscreen:(LPASVLOFFSCREEN)pOffscreen;
+ (LPASVLOFFSCREEN)createOffscreenWithUIImage:(UIImage*)image;
+ (CGRect)imageFaceRectToImageView:(UIImageView *)imageView faceMRect:(MRECT)mRect;
+ (CGRect)imageFaceRectToImageView:(UIImageView *)imageView faceRect:(SKOpenCVFaceRect)mRect;
+ (CGRect)bufferFaceRectToView:(UIView *)view buffer:(CVImageBufferRef)buffer faceRect:(SKOpenCVFaceRect)mRect;

@end
