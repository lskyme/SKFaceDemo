//
//  SKArcsoftFaceDetection.mm
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import "SKArcsoftFaceDetection.h"
#import "Utility.h"
#import "asvloffscreen.h"
#import "ammem.h"
#import <arcsoft_fsdk_face_detection/arcsoft_fsdk_face_detection.h>
#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#include <dlib/array2d.h>

#define AFR_FD_MEM_SIZE         1024*1024*5
#define AFR_FD_MAX_FACE_NUM     5

@implementation SKArcsoftFaceInfo
@end

@interface SKArcsoftFaceDetection () {
    
    MHandle          _arcsoftFD;
    MVoid*           _memBufferFD;
    
    const char*      _arcAppId;
    const char*      _arcAppKey;
    
    dlib::shape_predictor sp;
}
    
@property(nonatomic, assign, readwrite) BOOL prepared;
    
@end

@implementation SKArcsoftFaceDetection
    
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
    _memBufferFD = MMemAlloc(MNull, AFR_FD_MEM_SIZE);
    MMemSet(_memBufferFD, 0, AFR_FD_MEM_SIZE);
    AFD_FSDK_InitialFaceEngine((MPChar)_arcAppId, (MPChar)_arcAppKey, (MByte*)_memBufferFD, AFR_FD_MEM_SIZE, &_arcsoftFD, AFD_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FD_MAX_FACE_NUM);
    
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    dlib::deserialize(modelFileNameCString) >> sp;
    
    self.prepared = YES;
}
    
- (void)destroy {
    AFD_FSDK_UninitialFaceEngine(_arcsoftFD);
    _arcsoftFD = MNull;
    if(_memBufferFD != MNull)
    {
        MMemFree(MNull, _memBufferFD);
        _memBufferFD = MNull;
    }
}

- (UIImage *)markFeaturePointsWithImage:(UIImage *)image faceInfos:(NSArray *)faceinfos {
    if (!self.prepared) {
        [self setupEngines];
    }
    
    CGImageRef cgimage = image.CGImage;
    size_t width = CGImageGetWidth(cgimage); // 图片宽度
    size_t height = CGImageGetHeight(cgimage); // 图片高度
    unsigned char *data = (unsigned char*)calloc(width * height * 4, sizeof(unsigned char)); // 取图片首地址
    size_t bitsPerComponent = 8; // r g b a 每个component bits数目
    size_t bytesPerRow = width * 4; // 一张图片每行字节数目 (每个像素点包含r g b a 四个字节)
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB(); // 创建rgb颜色空间
    CGContextRef context = CGBitmapContextCreate(data,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgimage);
    
    dlib::array2d<dlib::rgb_pixel> img;
    img.set_size(height, width);
    
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::rgb_pixel& pixel = img.element();
        
        long bufferLocation = position * 4;
        char r = data[bufferLocation];
        char g = data[bufferLocation + 1];
        char b = data[bufferLocation + 2];
        
        dlib::rgb_pixel newpixel(r, g, b);
        pixel = newpixel;
        
        position++;
    }
    
    for(unsigned int i= 0;i < faceinfos.count;i++) {
        id obj = faceinfos[i];
        if ([obj isKindOfClass:[SKArcsoftFaceInfo class]]) {
            MRECT rect = ((SKArcsoftFaceInfo *)obj).rect;
            dlib::rectangle dlibRect(rect.left, rect.top, rect.right, rect.bottom);
            dlib::full_object_detection shape = sp(img, dlibRect);
            for (unsigned long k = 0; k < shape.num_parts(); k++) {
                dlib::point p = shape.part(k);
                dlib::draw_solid_circle(img, p, 3, dlib::rgb_pixel(255, 0, 0));
            }
        }
    }
    
    img.reset();
    position = 0;
    while (img.move_next()) {
        dlib::rgb_pixel& pixel = img.element();
        long bufferLocation = position * 4;
        data[bufferLocation] = pixel.red;
        data[bufferLocation + 1] = pixel.green;
        data[bufferLocation + 2] = pixel.blue;
        
        position++;
    }
    
    CGImageRef newCGImageRef = CGBitmapContextCreateImage(context);
    
    return [UIImage imageWithCGImage:newCGImageRef];
}
    
- (NSArray *)detectReturnRectsWithImage:(UIImage *)image {
    if (!self.prepared) {
        [self setupEngines];
    }
    
    LPASVLOFFSCREEN pOffscreen = [Utility createOffscreenWithUIImage:image];
    LPAFD_FSDK_FACERES pFaceResFD = MNull;
    AFD_FSDK_StillImageFaceDetection(_arcsoftFD, pOffscreen, &pFaceResFD);
    
    NSMutableArray *infos = [[NSMutableArray alloc] initWithCapacity:0];
    if(pFaceResFD && pFaceResFD->nFace > 0) {
        for (int face=0; face<pFaceResFD->nFace; face++) {
            SKArcsoftFaceInfo *info = [[SKArcsoftFaceInfo alloc] init];
            info.rect = pFaceResFD->rcFace[face];
            [infos addObject:info];
        }
    }
    
    return infos;
}

@end
