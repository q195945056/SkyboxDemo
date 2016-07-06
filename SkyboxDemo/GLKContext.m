//
//  GLKContext.m
//  SkyboxDemo
//
//  Created by 严明俊 on 16/7/5.
//  Copyright © 2016年 yanmingjun. All rights reserved.
//

#import "GLKContext.h"

@implementation GLKContext
@synthesize clearColor = _clearColor;

- (void)setClearColor:(GLKVector4)clearColorRGBA
{
    _clearColor = clearColorRGBA;
    
    NSAssert(self == [[self class] currentContext],
             @"Receiving context required to be current context");
    
    glClearColor(
                 clearColorRGBA.r,
                 clearColorRGBA.g,
                 clearColorRGBA.b,
                 clearColorRGBA.a);
}

- (GLKVector4)clearColor
{
    return _clearColor;
}

- (void)clear:(GLbitfield)mask
{
    NSAssert(self == [[self class] currentContext],
             @"Receiving context required to be current context");
    
    glClear(mask);
}

- (void)enable:(GLenum)capability;
{
    NSAssert(self == [[self class] currentContext],
             @"Receiving context required to be current context");
    
    glEnable(capability);
}

- (void)disable:(GLenum)capability;
{
    NSAssert(self == [[self class] currentContext],
             @"Receiving context required to be current context");
    
    glDisable(capability);
}

- (void)setBlendSourceFunction:(GLenum)sfactor
           destinationFunction:(GLenum)dfactor;
{
    glBlendFunc(sfactor, dfactor);
}

@end
