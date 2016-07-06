//
//  UIView+SnapShot.m
//  CurrencyExchangeRate
//
//  Created by 严明俊 on 13-9-17.
//  Copyright (c) 2013年 HuangZhenPeng. All rights reserved.
//

#import "UIView+SnapShot.h"

@implementation UIView (SnapShot)

// get the current view screen shot
- (UIImage *)capture
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, [UIScreen mainScreen].scale);
    
    
    if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    } else {
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
