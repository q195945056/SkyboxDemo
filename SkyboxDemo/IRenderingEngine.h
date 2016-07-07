//
//  IRenderingEngine.h
//  SkyboxDemo
//
//  Created by 严明俊 on 16/7/7.
//  Copyright © 2016年 yanmingjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@protocol IRenderingEngine <NSObject>

@property (nonatomic, copy) NSArray *textureNames;

@property (nonatomic) NSInteger currentTextureIndex;

- (instancetype)initWithGLKView:(GLKView *)view;//初始化

- (void)prepareToDraw;

- (void)draw;//渲染

//世界坐标转屏幕坐标
- (GLKVector3)convertWorldCoordinateToScreenCoordinate:(GLKVector3)location;

- (void)onMoveBegin;

- (void)onPinchBegin;

//手指拖动时调用
- (void)onFingerMove:(CGPoint)translation;

//缩放
- (void)onFingerPinch:(CGFloat)scale;

@end

id<IRenderingEngine> CreateRenderingEngine(GLKView *view);
