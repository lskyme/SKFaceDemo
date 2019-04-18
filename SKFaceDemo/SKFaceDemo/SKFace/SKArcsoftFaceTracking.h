//
//  SKArcsoftFaceTracking.h
//  SKFaceDemo
//
//  Created by DFSX on 2019/1/23.
//  Copyright © 2019 Lskyme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface SKArcsoftFaceTracking : NSObject
    
@property(nonatomic, assign, readonly) BOOL prepared;
    
- (instancetype)initWithAppId:(NSString *)appId appKey:(NSString *)appKey;
- (void)destroy;
- (void)markFeaturePointsWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)markAreaWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
