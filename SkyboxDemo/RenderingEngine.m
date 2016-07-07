//
//  RenderingEngine.m
//  SkyboxDemo
//
//  Created by 严明俊 on 16/7/7.
//  Copyright © 2016年 yanmingjun. All rights reserved.
//

#import "RenderingEngine.h"
#import "GLKContext.h"

static const CGFloat defaultFovy = 80.0f;

id<IRenderingEngine> CreateRenderingEngine(GLKView *view) {
    return [[RenderingEngine alloc] initWithGLKView:view];
}

@interface RenderingEngine ()

@property (nonatomic, weak) GLKView *glView;
@property (nonatomic, strong) GLKSkyboxEffect *skyboxEffect;
@property (nonatomic) GLKVector3 eyePosition;
@property (nonatomic) GLKVector3 lookAtPosition;
@property (nonatomic) GLKVector3 upVector;

@property (nonatomic) CGFloat xAxisAngle;
@property (nonatomic) CGFloat yAxisAngle;

@property (nonatomic) CGFloat previousXAngle;
@property (nonatomic) CGFloat previousYAngle;

@property (nonatomic) CGFloat fovyRadians;
@property (nonatomic) CGFloat previousFovyRadians;

@property (nonatomic) NSInteger textureIndex;

@end

@implementation RenderingEngine

#pragma mark - Public Methods

- (instancetype)initWithGLKView:(GLKView *)view {
    self = [super init];
    if (self) {
        NSAssert([view isKindOfClass:[GLKView class]],
                 @"View controller's view is not a GLKView");
        _glView = view;

        
        view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        view.context = [[GLKContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:view.context];
        
        self.eyePosition = GLKVector3Make(0, 0, 0);
        self.xAxisAngle = 0;
        [self calculateCameraMatrixParam];
        
        self.skyboxEffect = [[GLKSkyboxEffect alloc] init];
        _currentTextureIndex = -1;

        //设置天空盒大小
        self.skyboxEffect.xSize = 1.0f;
        self.skyboxEffect.ySize = 1.0f;
        self.skyboxEffect.zSize = 1.0f;
        self.skyboxEffect.center = self.eyePosition;//相机位置
        
        self.previousFovyRadians = self.fovyRadians = defaultFovy;
    }
    return self;
}

- (void)prepareToDraw {
    [(GLKContext *)self.glView.context clear:GL_COLOR_BUFFER_BIT];
    const GLfloat aspectRatio = (GLfloat)self.glView.drawableWidth / (GLfloat)self.glView.drawableHeight;
    [self preparePointOfViewWithAspectRatio:aspectRatio];
    
    [self.skyboxEffect prepareToDraw];
}

- (void)draw {
    [self.skyboxEffect draw];
}

#pragma mark - Private Methods

- (void)calculateCameraMatrixParam {
    GLKVector3 lookAtPosition = GLKVector3Make(0, 0, -0.5);
    GLKMatrix4 yAxisRotation = GLKMatrix4MakeRotation(self.yAxisAngle, 0, 1, 0);
    GLKMatrix4 xAxisRotation = GLKMatrix4MakeRotation(self.xAxisAngle, 1, 0, 0);
    GLKMatrix4 combination = GLKMatrix4Multiply(yAxisRotation, xAxisRotation);
    GLKVector3 newLookAtPosition = GLKMatrix4MultiplyVector3(combination, lookAtPosition);
    self.lookAtPosition = newLookAtPosition;
    
    GLKVector3 upVector = GLKVector3Make(0, 1, 0);
    GLKVector3 newUpVector = GLKMatrix4MultiplyVector3(combination, upVector);
    self.upVector = newUpVector;
}

- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio
{
    self.skyboxEffect.transform.projectionMatrix =
    GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.fovyRadians),//视野角度
                              aspectRatio,//宽高比
                              0.1f,   // Don't make near plane too close
                              20.0f); // Far arbitrarily far enough to contain scenex
    
    self.skyboxEffect.transform.modelviewMatrix =
    GLKMatrix4MakeLookAt(self.eyePosition.x,      // 相机位置
                         self.eyePosition.y,
                         self.eyePosition.z,
                         self.lookAtPosition.x,   // 目标位置
                         self.lookAtPosition.y,
                         self.lookAtPosition.z,
                         self.upVector.x,         // 上向量direction
                         self.upVector.y,
                         self.upVector.z);
}

#pragma mark - Properties

- (void)setTextureNames:(NSArray *)textureNames {
    if (_textureNames != textureNames) {
        _textureNames = textureNames;
        self.currentTextureIndex = 0;
    }
}

- (void)setCurrentTextureIndex:(NSInteger)currentTextureIndex {
    NSAssert(currentTextureIndex >= 0 && currentTextureIndex <= self.textureNames.count - 1, @"数组越界");
    if (_currentTextureIndex != currentTextureIndex) {
        _currentTextureIndex = currentTextureIndex;
        NSString *textName = self.textureNames[currentTextureIndex];
        NSArray *names = @[@"px", @"nx", @"py", @"ny", @"pz", @"nz"];
        NSMutableArray *paths = [NSMutableArray arrayWithCapacity:names.count];
        for (NSString *name in names) {
            NSString *fullName = [textName stringByAppendingString:name];
            NSString *path = [[NSBundle mainBundle] pathForResource:fullName ofType:@"jpg"];
            if (!path) {
                path = [[NSBundle mainBundle] pathForResource:fullName ofType:@"png"];
            }
            if (path) {
                [paths addObject:path];
            }
        }
        if (paths.count == 6) {
            NSError *error = nil;
            GLKTextureInfo *textureInfo = [GLKTextureLoader cubeMapWithContentsOfFiles:paths options:nil error:&error];
            
            GLuint previousTextureID = self.skyboxEffect.textureCubeMap.name;
            glDeleteTextures(1, &previousTextureID);
            
            self.skyboxEffect.textureCubeMap.name = textureInfo.name;
            self.skyboxEffect.textureCubeMap.target = textureInfo.target;
            self.xAxisAngle = self.yAxisAngle = 0;
            [self calculateCameraMatrixParam];
        }
    }
}

#pragma  mark - Pan Related Method

- (void)onMoveBegin {
    self.previousXAngle = self.xAxisAngle;
    self.previousYAngle = self.yAxisAngle;
}

- (void)onFingerMove:(CGPoint)translation {
    CGFloat radius = [self screenRadius];//计算天空盒在屏幕坐标系中的半径
    
    CGFloat offsetX = translation.x;
    CGFloat theta = atanf(offsetX / radius);
    self.yAxisAngle = self.previousYAngle + theta;
    
    CGFloat offsetY = translation.y;
    CGFloat xTheta = atanf(offsetY / radius);
    CGFloat xAngle = self.previousXAngle + xTheta;
    if (xAngle <= -M_PI_2) {
        xAngle = -M_PI_2;
    } else if (xAngle >= M_PI_2) {
        xAngle = M_PI_2;
    }
    self.xAxisAngle = xAngle;
    [self calculateCameraMatrixParam];
}

- (CGFloat)screenRadius {
    GLKView *view = self.glView;
    const GLfloat aspectRatio = (GLfloat)view.drawableWidth / (GLfloat)view.drawableHeight;
    GLKMatrix4 projectionMatrix =
    GLKMatrix4MakePerspective(GLKMathDegreesToRadians(self.fovyRadians),//视野角度
                              aspectRatio,//宽高比
                              0.1f,   // Don't make near plane too close
                              20.0f); // Far arbitrarily far enough to contain scenex
    
    GLKMatrix4 modelviewMatrix =
    GLKMatrix4MakeLookAt(0,      // 相机位置
                         0,
                         0,
                         0,   // 目标位置
                         0,
                         -0.5,
                         0,         // 上向量
                         1,
                         0);
    GLKVector3 leftLocation;
    gluProject(GLKVector3Make(-1.0, 0, -1.0),
               modelviewMatrix,
               projectionMatrix,
               CGRectMake(0, 0, view.frame.size.width, view.frame.size.height),
               &leftLocation);
    
    GLKVector3 rightLocation;
    gluProject(GLKVector3Make(1.0, 0, -1.0),
               modelviewMatrix,
               projectionMatrix,
               CGRectMake(0, 0, view.frame.size.width, view.frame.size.height),
               &rightLocation);
    CGFloat radius = (rightLocation.x - leftLocation.x) / 2;
    
    return radius;
}

#pragma mark - Pinch Related Methods

- (void)onPinchBegin {
    self.previousFovyRadians = self.fovyRadians;
}

- (void)onFingerPinch:(CGFloat)scale {
    self.fovyRadians = self.previousFovyRadians / scale;
    if (self.fovyRadians < 30) {
        self.fovyRadians = 30;
    } else if (self.fovyRadians > defaultFovy) {
        self.fovyRadians = defaultFovy;
    }
}

#pragma mark - Coordinate Convert Method

- (GLKVector3)convertWorldCoordinateToScreenCoordinate:(GLKVector3)location {
    GLKVector3 result;
    GLKEffectPropertyTransform *transfrom = self.skyboxEffect.transform;
    GLKMatrix4 modelviewMatrix = transfrom.modelviewMatrix;
    GLKMatrix4 projectionMatrix = transfrom.projectionMatrix;
    gluProject(location,
               modelviewMatrix,
               projectionMatrix,
               CGRectMake(0, 0, self.glView.frame.size.width, self.glView.frame.size.height),
               &result);
    return result;
}

@end
