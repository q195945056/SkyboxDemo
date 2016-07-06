//
//  GLKContext.h
//  SkyboxDemo
//
//  Created by 严明俊 on 16/7/5.
//  Copyright © 2016年 yanmingjun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

GLK_INLINE GLint gluProject(GLKVector3 objectLocation, GLKMatrix4 modelViewMatrix, GLKMatrix4 projectionMatrix, CGRect viewport, GLKVector3 *screenLocation) {
    GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    GLKVector3 result = GLKMatrix4MultiplyVector3(modelViewProjectionMatrix, objectLocation);
    GLfloat x = viewport.origin.x + (1 + result.x) * viewport.size.width / 2;
    GLfloat y = viewport.origin.y + (1 + result.y) * viewport.size.height / 2;
    CGFloat z = (1 + result.z) / 2;
    *screenLocation = GLKVector3Make(x, y, z);
    return GL_TRUE;
}

@interface GLKContext : EAGLContext

@property (nonatomic, assign, readwrite) GLKVector4 clearColor;

- (void)clear:(GLbitfield)mask;
- (void)enable:(GLenum)capability;
- (void)disable:(GLenum)capability;
- (void)setBlendSourceFunction:(GLenum)sfactor destinationFunction:(GLenum)dfactor;

@end
