//
//  SKOpenCVFaceDetection.h
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct {
    
    int left;
    int top;
    int right;
    int bottom;
    
} SKOpenCVFaceRect;

@interface SKOpenCVFaceInfo: NSObject
    
@property (nonatomic, assign) SKOpenCVFaceRect rect;
    
@end

@interface SKOpenCVFaceDetection : NSObject
    
@property(nonatomic, assign, readonly) BOOL prepared;

- (UIImage *)markFeaturePointsWithImage:(UIImage *)image faceInfos:(NSArray *)faceinfos;
- (NSArray *)detectReturnRectsWithImage:(UIImage *)image;

@end

