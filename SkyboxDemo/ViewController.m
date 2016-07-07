//
//  ViewController.m
//  SkyboxDemo
//
//  Created by 严明俊 on 16/7/5.
//  Copyright © 2016年 yanmingjun. All rights reserved.
//

#import "ViewController.h"
#import "UIView+SnapShot.h"
#import "RenderingEngine.h"

@interface ViewController ()
@property (nonatomic) NSInteger textureIndex;

@property (nonatomic, weak) IBOutlet UIButton *testButton;
@property (nonatomic, weak) UIImageView *animationImageView;
@property (nonatomic) BOOL needAnimation;
@property (nonatomic, strong) RenderingEngine *renderingEngine;

@end


@implementation ViewController

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupUI];
}

#pragma mark - GLKView Delegate Method

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.renderingEngine prepareToDraw];
    [self updateButtonLocation];
    [self.renderingEngine draw];
    
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
    GLKVector3 location = [self.renderingEngine convertWorldCoordinateToScreenCoordinate:GLKVector3Make(0, 0, -1.1)];
    self.testButton.hidden = (location.z < 0.5);
    self.testButton.center = CGPointMake(location.x, self.view.frame.size.height - location.y);
}

- (void)setupUI {
    GLKView *view = (GLKView *)self.view;
    _renderingEngine = [[RenderingEngine alloc] initWithGLKView:view];
    _renderingEngine.textureNames = @[@"Park2", @"SwedishRoyalCastle", @"pisa", @"Escher", @"skybox", @"Park3Med", @"Bridge2"];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
    [view addGestureRecognizer:panGesture];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureHandle:)];
    [view addGestureRecognizer:pinchGesture];
}

- (void)pinchGestureHandle:(UIPinchGestureRecognizer *)pinchGesture {
    CGFloat scale = pinchGesture.scale;
    if (pinchGesture.state == UIGestureRecognizerStateBegan) {
        [self.renderingEngine onPinchBegin];
    } else if (pinchGesture.state == UIGestureRecognizerStateChanged) {
        [self.renderingEngine onFingerPinch:scale];
    }
}

- (void)panGestureHandle:(UIPanGestureRecognizer *)panGesutre {
    CGPoint translation = [panGesutre translationInView:panGesutre.view];
    if (panGesutre.state == UIGestureRecognizerStateBegan) {
        [self.renderingEngine onMoveBegin];
    } else if (panGesutre.state == UIGestureRecognizerStateChanged) {
        [self.renderingEngine onFingerMove:translation];
    }
}

#pragma mark - Actions
//切换场景
- (IBAction)changeSceneButtonPressed:(id)sender {
    self.textureIndex++;
    if (self.textureIndex > 6) {
        self.textureIndex = 0;
    }
    self.renderingEngine.currentTextureIndex = self.textureIndex;
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
