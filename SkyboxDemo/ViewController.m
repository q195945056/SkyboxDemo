//
//  ViewController.m
//  SkyboxDemo
//
//  Created by 严明俊 on 16/7/5.
//  Copyright © 2016年 yanmingjun. All rights reserved.
//

#import "ViewController.h"
#import "GLKContext.h"
#import "UIView+SnapShot.h"

@interface ViewController ()

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

@property (nonatomic, weak) IBOutlet UIButton *testButton;

@property (nonatomic, weak) UIImageView *animationImageView;

@property (nonatomic) BOOL needAnimation;

@end

static const CGFloat defaultFovy = 80.0f;

@implementation ViewController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupUI];
}

#pragma mark - GLKView Delegate Method

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [(GLKContext *)view.context clear:GL_COLOR_BUFFER_BIT];
    const GLfloat aspectRatio = (GLfloat)view.drawableWidth / (GLfloat)view.drawableHeight;
    [self preparePointOfViewWithAspectRatio:aspectRatio];
    
    [self.skyboxEffect prepareToDraw];
    
    [self updateButtonLocation];
    [self.skyboxEffect draw];
    if (self.needAnimation) {
        [self.animationImageView removeFromSuperview];
        
        CATransition *transition = [CATransition animation];
        transition.duration = 1;
        [self.view.layer addAnimation:transition forKey:@"fade"];
        self.needAnimation = NO;
    }
}

#pragma mark - Private Methods

- (void)updateButtonLocation {
    GLKVector3 location;
    GLKEffectPropertyTransform *transfrom = self.skyboxEffect.transform;
    GLKMatrix4 modelviewMatrix = transfrom.modelviewMatrix;
    GLKMatrix4 projectionMatrix = transfrom.projectionMatrix;
    gluProject(GLKVector3Make(0, 0, -1.1),
               modelviewMatrix,
               projectionMatrix,
               CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height),
               &location);
    self.testButton.hidden = (location.z < 0.5);
    self.testButton.center = CGPointMake(location.x, self.view.frame.size.height - location.y);
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

- (void)setupUI {
    GLKView *view = (GLKView *)self.view;
    NSAssert([view isKindOfClass:[GLKView class]],
             @"View controller's view is not a GLKView");
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.context = [[GLKContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:view.context];
    
    self.eyePosition = GLKVector3Make(0, 0, 0);
    self.xAxisAngle = 0;
    [self calculateCameraMatrixParam];

    self.skyboxEffect = [[GLKSkyboxEffect alloc] init];
    self.textureIndex = 0;
    [self changeScene];
    //设置天空盒大小
    self.skyboxEffect.xSize = 2.0f;
    self.skyboxEffect.ySize = 2.0f;
    self.skyboxEffect.zSize = 2.0f;
    self.skyboxEffect.center = self.eyePosition;//相机位置
    
    self.previousFovyRadians = self.fovyRadians = defaultFovy;

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
    [view addGestureRecognizer:panGesture];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureHandle:)];
    [view addGestureRecognizer:pinchGesture];
}

- (void)pinchGestureHandle:(UIPinchGestureRecognizer *)pinchGesture {
    CGFloat scale = pinchGesture.scale;
    if (pinchGesture.state == UIGestureRecognizerStateBegan) {
        self.previousFovyRadians = self.fovyRadians;
    } else if (pinchGesture.state == UIGestureRecognizerStateChanged) {
        self.fovyRadians = self.previousFovyRadians / scale;
        if (self.fovyRadians < 30) {
            self.fovyRadians = 30;
        } else if (self.fovyRadians > defaultFovy) {
            self.fovyRadians = defaultFovy;
        }
    }
}

- (CGFloat)screenRadius {
    GLKView *view = (GLKView *)self.view;
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
               CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height),
               &leftLocation);
    
    GLKVector3 rightLocation;
    gluProject(GLKVector3Make(1.0, 0, -1.0),
               modelviewMatrix,
               projectionMatrix,
               CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height),
               &rightLocation);
    CGFloat radius = (rightLocation.x - leftLocation.x) / 2;
    
    return radius;
}

- (void)panGestureHandle:(UIPanGestureRecognizer *)panGesutre {
    CGPoint translation = [panGesutre translationInView:panGesutre.view];
    if (panGesutre.state == UIGestureRecognizerStateBegan) {
        self.previousXAngle = self.xAxisAngle;
        self.previousYAngle = self.yAxisAngle;
    } else if (panGesutre.state == UIGestureRecognizerStateChanged) {
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
}

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

//切换场景
- (void)changeScene {
    NSArray *textureNames = @[@"Park2", @"SwedishRoyalCastle", @"pisa", @"Escher", @"skybox", @"Park3Med", @"Bridge2"];
    NSString *textName = textureNames[self.textureIndex];
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

#pragma mark - Actions 

//切换场景
- (IBAction)changeSceneButtonPressed:(id)sender {
    
    self.textureIndex++;
    if (self.textureIndex > 6) {
        self.textureIndex = 0;
    }
    [self changeScene];
    
    UIImage *image = [self.view capture];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:imageView];
    self.animationImageView = imageView;
    self.needAnimation = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
