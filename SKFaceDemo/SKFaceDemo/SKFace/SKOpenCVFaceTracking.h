//
//  SKOpenCVFaceTracking.h
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface SKOpenCVFaceTracking : NSObject

@property(nonatomic, assign, readonly) BOOL prepared;
    
- (CVImageBufferRef)markFeaturePointsWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (CVImageBufferRef)markAreaWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

