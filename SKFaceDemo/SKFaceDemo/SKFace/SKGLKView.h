//
//  SKGLKView.h
//  SKFaceDemo
//
//  Created by DFSX on 2018/5/2.
//  Copyright © 2018年 Lskyme. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

@interface SKGLKView : GLKView

-(void) renderWithRGBA32Data:(unsigned int) nWidth height:(unsigned int) nHeight imageData:(GLbyte*) imageData format:(CIFormat) format;
-(void) renderWithTexture:(unsigned int) nTextureID width:(unsigned int) nWidth height:(unsigned int) nHeight;
-(void) renderWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer orientation:(int)nOrientation mirror:(BOOL) bMirror;

@end
