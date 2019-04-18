//
//  SKArcsoftFaceDetection.h
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "amcomdef.h"

@interface SKArcsoftFaceInfo: NSObject
    
@property (nonatomic, assign) MRECT rect;
    
@end

@interface SKArcsoftFaceDetection : NSObject
    
@property(nonatomic, assign, readonly) BOOL prepared;
    
- (instancetype)initWithAppId:(NSString *)appId appKey:(NSString *)appKey;
- (UIImage *)markFeaturePointsWithImage:(UIImage *)image faceInfos:(NSArray *)faceinfos;
- (NSArray *)detectReturnRectsWithImage:(UIImage *)image;
- (void)destroy;

@end

