/*
 Copyright (c) 2012, Luke
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of the geeklu.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "LUFoldableView.h"
#import "LUFoldSegmentLayer.h"
#import "LUImageHelper.h"

#define DEFAULT_FRAME CGRectMake(0, 0, 10, 10)

#define FOLDING_ANIMATING_FPS 60
#define ZDISTANCE 1800.0
#define SHADOW_MAX_OPACITY 0.6

@implementation LUFoldableView
@synthesize imageToFold = _imageToFold;
@synthesize tailImage = _tailImage;
@synthesize numberOfFolds = _numberOfFolds;
@synthesize backgroundView = _backgroundView;


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private Methods
- (CATransform3D)_foldTransformIdentity{
    CATransform3D identity = CATransform3DIdentity;
    identity.m34 = - 1.0 / ZDISTANCE;
    return identity;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Basic
- (void)dealloc{
    [_imageToFold release];
    [_tailImage release];
    [_foldSegmentLayers release];
    [_tailLayer release];
    [_backgroundView release];
    [_containerView release];
    
    [super dealloc];
}


- (id)initWithImage:(UIImage *)imageToFold tailImage:(UIImage *)tailImage numberOfFolds:(NSInteger)numberOfFolds vertical:(BOOL)vertical{
    
    if (!imageToFold || numberOfFolds < 1) {
        return nil;
    }
    
    if (self = [super initWithFrame:DEFAULT_FRAME]) {
        _imageToFold = [imageToFold retain];
        _tailImage = [tailImage retain];
        _numberOfFolds = numberOfFolds;
        _vertical = vertical;
        _foldSegmentLayers = [[NSMutableArray alloc] initWithCapacity:_numberOfFolds * 2];
        
        //containerView容纳所有用于实现折叠的Layer
        _containerView = [[UIView alloc] initWithFrame:self.bounds];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _containerView.backgroundColor = [UIColor clearColor];
        [self addSubview:_containerView];
        
        //竖向折叠
        if (vertical) {
            CGFloat foldViewHeight = imageToFold.size.height ;
            if (tailImage) {
                foldViewHeight += tailImage.size.height;
            }
            //设置FoldableView自己的frame
            self.frame = CGRectMake(0, 0, imageToFold.size.width, foldViewHeight);
        
            //初始化用于折叠的所有Layer
            NSInteger foldSegmentCount = _numberOfFolds * 2;
            CGFloat segmentHeight = _imageToFold.size.height*1.0 / foldSegmentCount;
            for (int i = 0; i < foldSegmentCount; i ++) {
                LUFoldSegmentLayer *segmentLayer = [[[LUFoldSegmentLayer alloc] init] autorelease];
                segmentLayer.frame = CGRectMake(-1, segmentHeight * i, imageToFold.size.width + 2, segmentHeight);
                segmentLayer.shadowMaskInsets = UIEdgeInsetsMake(0, 1, 0, 1);
                
                CGRect segmentRect = CGRectMake(0, segmentHeight * i, imageToFold.size.width, segmentHeight);
                CGImageRef segmentImage = CGImageCreateWithImageInRect(_imageToFold.CGImage, segmentRect);
                CGImageRef optimizedSegmentImage = CreateImageWithBorderInset(segmentImage,segmentRect.size,UIEdgeInsetsMake(0, 1, 0, 1));//左边和右边各加一个单位透明的像素,防止折叠过程边角产生锯齿
                if (segmentImage) {
                   CFRelease(segmentImage); 
                }
                segmentLayer.contents =  (id)optimizedSegmentImage; //设置segmentLayer的内容          
                if (optimizedSegmentImage) {
                    CFRelease(optimizedSegmentImage);
                }
                
                segmentLayer.transform = [self _foldTransformIdentity];
                
                if (i % 2 == 0) {
                    segmentLayer.anchorPoint = CGPointMake(0.5, 0);
                    segmentLayer.position = CGPointMake(segmentLayer.position.x, segmentHeight * i);
                }else {
                    segmentLayer.anchorPoint = CGPointMake(0.5, 1);
                    segmentLayer.position = CGPointMake(segmentLayer.position.x, segmentHeight * (i + 1));
                }
                
                [_containerView.layer addSublayer:segmentLayer];
                [_foldSegmentLayers addObject:segmentLayer];
            }
            
            if (tailImage) {
                _tailLayer = [[CALayer alloc] init];
                _tailLayer.contents = (id)tailImage.CGImage;
                _tailLayer.anchorPoint = CGPointMake(0.5, 0);
                _tailLayer.frame = CGRectMake(0, 0, tailImage.size.width, tailImage.size.height);
                _tailLayer.position = CGPointMake(imageToFold.size.width/2.0, imageToFold.size.height);
                [_containerView.layer addSublayer:_tailLayer];
            }
            
        }else {
            //横向折叠
            
            CGFloat foldViewWidth = imageToFold.size.width ;
            if (tailImage) {
                foldViewWidth += tailImage.size.width;
            }
            //设置FoldableView自己的frame
            self.frame = CGRectMake(0, 0, foldViewWidth, imageToFold.size.height);
            
            //初始化用于折叠的所有Layer
            NSInteger foldSegmentCount = _numberOfFolds * 2;
            CGFloat segmentWidth = _imageToFold.size.width*1.0 / foldSegmentCount;
            for (int i = 0; i < foldSegmentCount; i ++) {
                LUFoldSegmentLayer *segmentLayer = [[[LUFoldSegmentLayer alloc] init] autorelease];
                segmentLayer.frame = CGRectMake(segmentWidth * i, -1, segmentWidth, self.frame.size.height + 2);
                segmentLayer.shadowMaskInsets = UIEdgeInsetsMake(1, 0, 1, 0);
                
                CGRect segmentRect = CGRectMake(segmentWidth * i, 0, segmentWidth, self.frame.size.height);
                CGImageRef segmentImage = CGImageCreateWithImageInRect(_imageToFold.CGImage, segmentRect);
                CGImageRef optimizedSegmentImage = CreateImageWithBorderInset(segmentImage,segmentRect.size,UIEdgeInsetsMake(1, 0, 1, 0));
                if (segmentImage) {
                    CFRelease(segmentImage);
                }
                segmentLayer.contents =  (id)optimizedSegmentImage;           
                if (optimizedSegmentImage) {
                    CFRelease(optimizedSegmentImage);
                }
                
                segmentLayer.transform = [self _foldTransformIdentity];

                if (i % 2 == 0) {
                    segmentLayer.anchorPoint = CGPointMake(0, 0.5);
                    segmentLayer.position = CGPointMake(segmentWidth * i, segmentLayer.position.y);
                }else {
                    segmentLayer.anchorPoint = CGPointMake(1, 0.5);
                    segmentLayer.position = CGPointMake(segmentWidth * (i+1), segmentLayer.position.y);
                }
                [_containerView.layer addSublayer:segmentLayer];
                [_foldSegmentLayers addObject:segmentLayer];
            }
            
            
            if (tailImage) {
                _tailLayer = [[CALayer alloc] init];
                _tailLayer.contents = (id)tailImage.CGImage;
                _tailLayer.anchorPoint = CGPointMake(0, 0.5);
                _tailLayer.frame = CGRectMake(0, 0, tailImage.size.width, tailImage.size.height);
                _tailLayer.position = CGPointMake(imageToFold.size.width, imageToFold.size.height/2.0);
                [_containerView.layer addSublayer:_tailLayer];
            }
        }
    }
    
    return self;
}


- (BOOL)isVertical{
    return _vertical;
}


- (void)setBackgroundView:(UIView *)backgroundView{
    if (backgroundView != _backgroundView) {
        [_backgroundView removeFromSuperview];
        [_backgroundView release];
        
        _backgroundView = [backgroundView retain];
        _backgroundView.frame = self.frame;
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self insertSubview:_backgroundView atIndex:0];
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Set FoldableView State


- (void)setFoldAngle:(CGFloat)angle{
    angle = round( angle * 10000.0 ) / 10000.0;  //降低精度
    
    if (_vertical) {
        CGFloat segmentHeight = _imageToFold.size.height * 1.0 / (_numberOfFolds * 2);
        CGFloat segmentProjectionHeightWithPrespetive = (ZDISTANCE * segmentHeight * cosf(angle))/(ZDISTANCE + segmentHeight * sinf(angle));
        
        for (int i = 0; i < [_foldSegmentLayers count]; i++) {
            LUFoldSegmentLayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            if (i % 2 == 0) {
                segmentLayer.transform = CATransform3DRotate([self _foldTransformIdentity], -angle, 1, 0, 0);
                segmentLayer.position = CGPointMake(segmentLayer.position.x,segmentProjectionHeightWithPrespetive * i);
            }else {
                segmentLayer.transform = CATransform3DRotate([self _foldTransformIdentity], angle, 1, 0, 0);
                segmentLayer.position = CGPointMake(segmentLayer.position.x, segmentProjectionHeightWithPrespetive * (i + 1));
                segmentLayer.shadowMaskOpacity = SHADOW_MAX_OPACITY * (angle / M_PI_2);
            }
        }
        
        if (_tailLayer) {
            _tailLayer.position = CGPointMake(_tailLayer.position.x, segmentProjectionHeightWithPrespetive * (_numberOfFolds * 2));
        }
    }else {
        CGFloat segmentWidth = _imageToFold.size.width*1.0 / (_numberOfFolds *2);
        CGFloat segmentProjectionWidthWithPrespetive = (ZDISTANCE * segmentWidth * cosf(angle))/(ZDISTANCE + segmentWidth * sinf(angle));
        
        for (int i = 0; i < [_foldSegmentLayers count]; i++) {
            LUFoldSegmentLayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            if (i % 2 == 0) {
                segmentLayer.transform = CATransform3DRotate([self _foldTransformIdentity], angle, 0, 1, 0);
                segmentLayer.position = CGPointMake(segmentProjectionWidthWithPrespetive * i, segmentLayer.position.y);
            }else {
                segmentLayer.transform = CATransform3DRotate([self _foldTransformIdentity], -angle, 0, 1, 0);
                segmentLayer.position = CGPointMake(segmentProjectionWidthWithPrespetive * (i + 1), segmentLayer.position.y);
                segmentLayer.shadowMaskOpacity = SHADOW_MAX_OPACITY * (angle / M_PI_2);
            }
        }
        
        if (_tailLayer) {
            _tailLayer.position = CGPointMake(segmentProjectionWidthWithPrespetive * (_numberOfFolds * 2), _tailLayer.position.y);
        }
    }
}


- (void)setFoldRate:(CGFloat)rate{
    //计算折叠率的时候，变化的长度是透视后的投影的变化长度
    CGFloat angle = M_PI_2;
    if (_vertical) {
        CGFloat segmentHeight = _imageToFold.size.height * 1.0 / (_numberOfFolds * 2);
        CGFloat segmentProjectionHeightWithPrespetive = _imageToFold.size.height*(1 - rate) / (_numberOfFolds * 2);
        if (segmentProjectionHeightWithPrespetive != 0) {
            CGFloat segmentProjectionHeightWithoutPrespetive = ((2*ZDISTANCE*ZDISTANCE/segmentProjectionHeightWithPrespetive) + sqrtf((4*ZDISTANCE*ZDISTANCE*ZDISTANCE*ZDISTANCE)/(segmentProjectionHeightWithPrespetive*segmentProjectionHeightWithPrespetive) - 4*(1+(ZDISTANCE*ZDISTANCE)/(segmentProjectionHeightWithPrespetive*segmentProjectionHeightWithPrespetive))*(ZDISTANCE*ZDISTANCE - segmentHeight *segmentHeight)))/(2*(1+(ZDISTANCE*ZDISTANCE)/(segmentProjectionHeightWithPrespetive*segmentProjectionHeightWithPrespetive)));
            
            angle = acosf(segmentProjectionHeightWithoutPrespetive/segmentHeight);
        }

    }else {
        CGFloat segmentWidth = _imageToFold.size.width*1.0 / (_numberOfFolds * 2);
        CGFloat segmentProjectionWidthWithPrespetive = _imageToFold.size.width * (1 - rate) / (_numberOfFolds * 2);
        if (segmentProjectionWidthWithPrespetive != 0) {
            CGFloat segmentProjectionWidthWithoutPrespetive = ((2*ZDISTANCE*ZDISTANCE/segmentProjectionWidthWithPrespetive) + sqrtf((4*ZDISTANCE*ZDISTANCE*ZDISTANCE*ZDISTANCE)/(segmentProjectionWidthWithPrespetive*segmentProjectionWidthWithPrespetive) - 4*(1+(ZDISTANCE*ZDISTANCE)/(segmentProjectionWidthWithPrespetive*segmentProjectionWidthWithPrespetive))*(ZDISTANCE*ZDISTANCE - segmentWidth *segmentWidth)))/(2*(1+(ZDISTANCE*ZDISTANCE)/(segmentProjectionWidthWithPrespetive*segmentProjectionWidthWithPrespetive)));
            
            angle = acosf(segmentProjectionWidthWithoutPrespetive/segmentWidth);
        }
    }
    
    [self setFoldAngle:angle];

}




////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Animation
- (void)unfoldFromFoldAngle:(CGFloat)angle 
               withDuration:(NSTimeInterval)duration 
                 completion:(void (^)(BOOL finished))completion{
    if (_vertical) {
        
        CGFloat segmentHeight = _imageToFold.size.height * 1.0 / (_numberOfFolds * 2);
        CGFloat segmentProjectionHeightWithPrespetive = (ZDISTANCE * segmentHeight * cosf(angle))/(ZDISTANCE + segmentHeight * sinf(angle));
        
        //初始状态设置
        for (int i = 0; i < [_foldSegmentLayers count]; i ++) {
            CALayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            
            if (i % 2 == 0) {
                segmentLayer.transform = CATransform3DRotate([self _foldTransformIdentity], -angle, 1, 0, 0);
                segmentLayer.position = CGPointMake(segmentLayer.position.x, segmentProjectionHeightWithPrespetive * i);
            }else {
                segmentLayer.transform = CATransform3DRotate([self _foldTransformIdentity], angle, 1, 0, 0);
                segmentLayer.position = CGPointMake(segmentLayer.position.x, segmentProjectionHeightWithPrespetive * (i + 1));
            }
        }
        if (_tailLayer) {
            _tailLayer.position = CGPointMake(_tailLayer.position.x, segmentProjectionHeightWithPrespetive * (_numberOfFolds * 2));
        }
        
        //开始准备动画
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:duration] forKey:kCATransactionAnimationDuration];
        [CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] forKey:kCATransactionAnimationTimingFunction];
        
        [CATransaction setCompletionBlock:^{
            if(completion) completion(YES);;
        }];
        
        for (int i = 0; i < [_foldSegmentLayers count]; i ++) {
            LUFoldSegmentLayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            
            //旋转
            CABasicAnimation* rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
            [rotateAnimation setFillMode:kCAFillModeForwards];
            [rotateAnimation setRemovedOnCompletion:NO];
            if (i % 2 == 0) {
                [rotateAnimation setFromValue:[NSNumber numberWithFloat:-angle]];
                [rotateAnimation setToValue:[NSNumber numberWithFloat:0.0]];
            }else {
                [rotateAnimation setFromValue:[NSNumber numberWithFloat:angle]];
                [rotateAnimation setToValue:[NSNumber numberWithFloat:0.0]];
            }
            [segmentLayer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
            
            //阴影变化
            if (i % 2 == 1) {
                CABasicAnimation* shadowAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                [shadowAnimation setFillMode:kCAFillModeForwards];
                [shadowAnimation setRemovedOnCompletion:NO];
                [shadowAnimation setFromValue:[NSNumber numberWithFloat:SHADOW_MAX_OPACITY * (angle / M_PI_2)]];
                [shadowAnimation setToValue:[NSNumber numberWithFloat:0.0]];
                [segmentLayer.shadowMaskLayer addAnimation:shadowAnimation forKey:@"shadowAnimation"];
            }
            
            //旋转过程中的layer的position校正
            CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
            [positionAnimation setFillMode:kCAFillModeForwards];
            [positionAnimation setRemovedOnCompletion:NO];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];
            for (int f = 0; f <= duration * FOLDING_ANIMATING_FPS; f ++) {
                CGFloat progress = (f*1.0)/(duration * FOLDING_ANIMATING_FPS);
                CGFloat angleAfterChange = angle - progress * angle;
                
                CGFloat segmentProjectionHeightWithPrespetive = (ZDISTANCE*segmentHeight*cosf(angleAfterChange))/(ZDISTANCE + segmentHeight *sinf(angleAfterChange));
                if (i%2 == 0) {
                    [values addObject:[NSValue valueWithCGPoint:CGPointMake(segmentLayer.position.x, i * segmentProjectionHeightWithPrespetive)]];
                }else {
                    [values addObject:[NSValue valueWithCGPoint:CGPointMake(segmentLayer.position.x, (i+1) * segmentProjectionHeightWithPrespetive)]];
                }
            }
            positionAnimation.values = values;
            [segmentLayer addAnimation:positionAnimation forKey:@"positionAnimation"];
        }
        
        //tailLayer的position校正
        if (_tailLayer) {
            CAKeyframeAnimation *tailPositionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
            [tailPositionAnimation setFillMode:kCAFillModeForwards];
            [tailPositionAnimation setRemovedOnCompletion:NO];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];
            for (int f = 0; f < duration * FOLDING_ANIMATING_FPS; f ++) {
                CGFloat progress = (f*1.0)/(duration * FOLDING_ANIMATING_FPS);
                CGFloat angleAfterChange = angle - progress * angle;
                
                CGFloat segmentProjectionHeightWithPrespetive = (ZDISTANCE * segmentHeight * cosf(angleAfterChange)) / (ZDISTANCE + segmentHeight * sinf(angleAfterChange));
                [values addObject:[NSValue valueWithCGPoint:CGPointMake(_tailLayer.position.x, (_numberOfFolds * 2) * segmentProjectionHeightWithPrespetive)]];
            }
            tailPositionAnimation.values = values;
            [_tailLayer addAnimation:tailPositionAnimation forKey:@"tailPositionAnimation"];
        }
        
        
        [CATransaction commit];
        
    }else {
        CGFloat segmentWidth = _imageToFold.size.width*1.0 / (_numberOfFolds * 2);
        CGFloat segmentProjectionWidthWithPrespetive = (ZDISTANCE * segmentWidth * cosf(angle))/(ZDISTANCE + segmentWidth * sinf(angle));

        //初始状态设置
        for (int i = 0; i < [_foldSegmentLayers count]; i ++) {
            CALayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            
            if (i % 2 == 0) {
                segmentLayer.transform = CATransform3DRotate([self _foldTransformIdentity], angle, 0, 1, 0);
                segmentLayer.position = CGPointMake(segmentProjectionWidthWithPrespetive * i, segmentLayer.position.y);
            }else {
                segmentLayer.transform = CATransform3DRotate([self _foldTransformIdentity], -angle, 0, 1, 0);
                segmentLayer.position = CGPointMake(segmentProjectionWidthWithPrespetive * (i + 1), segmentLayer.position.y);
            }
        }
        if (_tailLayer) {
            _tailLayer.position = CGPointMake(segmentProjectionWidthWithPrespetive * (_numberOfFolds * 2), _tailLayer.position.y);
        }
        
        //开始准备动画
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:duration] forKey:kCATransactionAnimationDuration];
        [CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] forKey:kCATransactionAnimationTimingFunction];
        
        [CATransaction setCompletionBlock:^{
            if(completion) completion(YES);;
        }];
        
        for (int i = 0; i < [_foldSegmentLayers count]; i ++) {
            LUFoldSegmentLayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            
            //旋转
            CABasicAnimation* rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
            [rotateAnimation setFillMode:kCAFillModeForwards];
            [rotateAnimation setRemovedOnCompletion:NO];
            if (i % 2 == 0) {
                [rotateAnimation setFromValue:[NSNumber numberWithFloat:angle]];
                [rotateAnimation setToValue:[NSNumber numberWithFloat:0.0]];
            }else {
                [rotateAnimation setFromValue:[NSNumber numberWithFloat:-angle]];
                [rotateAnimation setToValue:[NSNumber numberWithFloat:0.0]];
            }
            [segmentLayer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
            
            //阴影变化
            if (i % 2 == 1) {
                CABasicAnimation* shadowAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                [shadowAnimation setFillMode:kCAFillModeForwards];
                [shadowAnimation setRemovedOnCompletion:NO];
                [shadowAnimation setFromValue:[NSNumber numberWithFloat:SHADOW_MAX_OPACITY*(angle / M_PI_2)]];
                [shadowAnimation setToValue:[NSNumber numberWithFloat:0.0]];
                [segmentLayer.shadowMaskLayer addAnimation:shadowAnimation forKey:@"shadowAnimation"];
            }
            
            //旋转过程中的layer的position校正
            CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
            [positionAnimation setFillMode:kCAFillModeForwards];
            [positionAnimation setRemovedOnCompletion:NO];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];
            for (int f = 0; f <= duration * FOLDING_ANIMATING_FPS; f ++) {
                CGFloat progress = (f*1.0)/(duration * FOLDING_ANIMATING_FPS);
                CGFloat angleAfterChange = angle - progress * angle;
                
                CGFloat segmentProjectionWidthWithPrespetive = (ZDISTANCE*segmentWidth*cosf(angleAfterChange))/(ZDISTANCE + segmentWidth *sinf(angleAfterChange));
                if (i%2 == 0) {
                    [values addObject:[NSValue valueWithCGPoint:CGPointMake(i * segmentProjectionWidthWithPrespetive, segmentLayer.position.y)]];
                }else {
                    [values addObject:[NSValue valueWithCGPoint:CGPointMake((i+1) * segmentProjectionWidthWithPrespetive, segmentLayer.position.y)]];
                }
            }
            positionAnimation.values = values;
            [segmentLayer addAnimation:positionAnimation forKey:@"positionAnimation"];
        }
        
        //tailLayer的position校正
        if (_tailLayer) {
            CAKeyframeAnimation *tailPositionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
            [tailPositionAnimation setFillMode:kCAFillModeForwards];
            [tailPositionAnimation setRemovedOnCompletion:NO];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];
            for (int f = 0; f < duration * FOLDING_ANIMATING_FPS; f ++) {
                CGFloat progress = (f*1.0)/(duration * FOLDING_ANIMATING_FPS);
                CGFloat angleAfterChange = angle - progress * angle;
                
                CGFloat segmentProjectionWidthWithPrespetive = (ZDISTANCE * segmentWidth * cosf(angleAfterChange)) / (ZDISTANCE + segmentWidth * sinf(angleAfterChange));
                [values addObject:[NSValue valueWithCGPoint:CGPointMake((_numberOfFolds * 2) * segmentProjectionWidthWithPrespetive, _tailLayer.position.y)]];
            }
            tailPositionAnimation.values = values;
            [_tailLayer addAnimation:tailPositionAnimation forKey:@"tailPositionAnimation"];
        }
        
        
        [CATransaction commit];
    }
}


- (void)unfoldWithDuration:(NSTimeInterval)duration 
                completion:(void (^)(BOOL finished))completion{
    [self unfoldFromFoldAngle:M_PI_2 withDuration:duration completion:completion];
}


- (void)foldFromFoldAngle:(CGFloat)angle 
             withDuration:(NSTimeInterval)duration 
               completion:(void (^)(BOOL finished))completion{
    if (_vertical) {
        CGFloat segmentHeight = _imageToFold.size.height * 1.0 / (_numberOfFolds * 2);
        CGFloat segmentProjectionHeightWithPrespetive = (ZDISTANCE * segmentHeight * cosf(angle))/(ZDISTANCE + segmentHeight * sinf(angle));

        //初始状态设置
        for (int i = 0; i < [_foldSegmentLayers count]; i ++) {
            CALayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            
            if (i % 2 == 0) {
                segmentLayer.position = CGPointMake(segmentLayer.position.x, segmentProjectionHeightWithPrespetive * i);
            }else {
                segmentLayer.position = CGPointMake(segmentLayer.position.x, segmentProjectionHeightWithPrespetive * (i+1));
            }
        }
        if (_tailLayer) {
            _tailLayer.position = CGPointMake(_tailLayer.position.x, segmentProjectionHeightWithPrespetive * (_numberOfFolds * 2));
        }
        
        //动画设置
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:duration] forKey:kCATransactionAnimationDuration];
        [CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] forKey:kCATransactionAnimationTimingFunction];
        
        [CATransaction setCompletionBlock:^{
            if(completion) completion(YES);;
        }];
        
        for (int i = 0; i < [_foldSegmentLayers count]; i ++) {
            LUFoldSegmentLayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            
            //旋转动画
            CABasicAnimation* rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.x"];
            [rotateAnimation setFillMode:kCAFillModeForwards];
            [rotateAnimation setRemovedOnCompletion:NO];
            if (i % 2 == 0) {
                [rotateAnimation setFromValue:[NSNumber numberWithFloat:-angle]];
                [rotateAnimation setToValue:[NSNumber numberWithFloat:-M_PI_2]];
            }else {
                [rotateAnimation setFromValue:[NSNumber numberWithFloat:angle]];
                [rotateAnimation setToValue:[NSNumber numberWithFloat:M_PI_2]];
            }
            [segmentLayer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
            
            
            //阴影变化
            if (i % 2 == 1) {
                CABasicAnimation* shadowAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                [shadowAnimation setFillMode:kCAFillModeForwards];
                [shadowAnimation setRemovedOnCompletion:NO];
                [shadowAnimation setFromValue:[NSNumber numberWithFloat:SHADOW_MAX_OPACITY * (angle / M_PI_2)]];
                [shadowAnimation setToValue:[NSNumber numberWithFloat:SHADOW_MAX_OPACITY]];
                [segmentLayer.shadowMaskLayer addAnimation:shadowAnimation forKey:@"shadowAnimation"];
            }
            
            //layer 位置校正
            CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
            [positionAnimation setFillMode:kCAFillModeForwards];
            [positionAnimation setRemovedOnCompletion:NO];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];
            for (int f = 0; f <= duration * FOLDING_ANIMATING_FPS; f ++) {
                CGFloat progress = (f*1.0)/(duration * FOLDING_ANIMATING_FPS * 1.0);
                CGFloat angleAfterChange = angle + progress * (M_PI_2 - angle);
                
                CGFloat segmentProjectionHeightWithPrespetive = (ZDISTANCE*segmentHeight*cosf(angleAfterChange))/(ZDISTANCE + segmentHeight *sinf(angleAfterChange));
                if (i % 2 == 0) {
                    [values addObject:[NSValue valueWithCGPoint:CGPointMake(segmentLayer.position.x, i * segmentProjectionHeightWithPrespetive)]];
                }else {
                    [values addObject:[NSValue valueWithCGPoint:CGPointMake(segmentLayer.position.x, (i+1) * segmentProjectionHeightWithPrespetive)]];
                }
            }
            positionAnimation.values = values;
            [segmentLayer addAnimation:positionAnimation forKey:@"positionAnimation"];
        }
        
        
        //tailLayer位置校正
        if (_tailLayer) {
            CAKeyframeAnimation *tailPositionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
            [tailPositionAnimation setFillMode:kCAFillModeForwards];
            [tailPositionAnimation setRemovedOnCompletion:NO];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];
            for (int f = 0; f <= duration * FOLDING_ANIMATING_FPS; f ++) {
                CGFloat progress = (f * 1.0)/(duration * FOLDING_ANIMATING_FPS);
                CGFloat angleAfterChange = angle + progress * (M_PI_2 - angle);
                
                CGFloat segmentProjectionHeightWithPrespetive = (ZDISTANCE * segmentHeight * cosf(angleAfterChange))/(ZDISTANCE + segmentHeight * sinf(angleAfterChange));
                [values addObject:[NSValue valueWithCGPoint:CGPointMake( _tailLayer.position.x,(_numberOfFolds *2) * segmentProjectionHeightWithPrespetive)]];
            }
            tailPositionAnimation.values = values;
            [_tailLayer addAnimation:tailPositionAnimation forKey:@"tailPositionAnimation"];
        }
        
        
        [CATransaction commit];
    }else {
        CGFloat segmentWidth = _imageToFold.size.width * 1.0 / (_numberOfFolds * 2);
        CGFloat segmentProjectionWidthWithPrespetive = (ZDISTANCE * segmentWidth * cosf(angle))/(ZDISTANCE + segmentWidth * sinf(angle));

        //初始状态设置
        for (int i = 0; i < [_foldSegmentLayers count]; i ++) {
            CALayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            
            if (i % 2 == 0) {
                segmentLayer.position = CGPointMake(segmentProjectionWidthWithPrespetive * i, segmentLayer.position.y);
            }else {
                segmentLayer.position = CGPointMake(segmentProjectionWidthWithPrespetive * (i + 1), segmentLayer.position.y);
            }
        }
        if (_tailLayer) {
            _tailLayer.position = CGPointMake(segmentProjectionWidthWithPrespetive * (_numberOfFolds * 2), _tailLayer.position.y);
        }
        
        //动画设置
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:duration] forKey:kCATransactionAnimationDuration];
        [CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] forKey:kCATransactionAnimationTimingFunction];
        
        [CATransaction setCompletionBlock:^{
            if(completion) completion(YES);;
        }];
        
        for (int i = 0; i < [_foldSegmentLayers count]; i ++) {
            LUFoldSegmentLayer *segmentLayer = [_foldSegmentLayers objectAtIndex:i];
            
            //旋转动画
            CABasicAnimation* rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
            [rotateAnimation setFillMode:kCAFillModeForwards];
            [rotateAnimation setRemovedOnCompletion:NO];
            if (i%2 == 0) {
                [rotateAnimation setFromValue:[NSNumber numberWithFloat:angle]];
                [rotateAnimation setToValue:[NSNumber numberWithFloat:M_PI_2]];
            }else {
                [rotateAnimation setFromValue:[NSNumber numberWithFloat:-angle]];
                [rotateAnimation setToValue:[NSNumber numberWithFloat:-M_PI_2]];
            }
            [segmentLayer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
            
            
            //阴影变化
            if (i % 2 == 1) {
                CABasicAnimation* shadowAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                [shadowAnimation setFillMode:kCAFillModeForwards];
                [shadowAnimation setRemovedOnCompletion:NO];
                [shadowAnimation setFromValue:[NSNumber numberWithFloat:SHADOW_MAX_OPACITY * (angle / M_PI_2)]];
                [shadowAnimation setToValue:[NSNumber numberWithFloat:SHADOW_MAX_OPACITY]];
                [segmentLayer.shadowMaskLayer addAnimation:shadowAnimation forKey:@"shadowAnimation"];
            }
            
            //layer 位置校正
            CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
            [positionAnimation setFillMode:kCAFillModeForwards];
            [positionAnimation setRemovedOnCompletion:NO];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];
            for (int f = 0; f <= duration * FOLDING_ANIMATING_FPS; f ++) {
                CGFloat progress = (f*1.0)/(duration * FOLDING_ANIMATING_FPS * 1.0);
                CGFloat angleAfterChange = angle + progress * (M_PI_2 - angle);
                
                CGFloat segmentProjectionWidthWithPrespetive = (ZDISTANCE*segmentWidth*cosf(angleAfterChange))/(ZDISTANCE + segmentWidth *sinf(angleAfterChange));
                if (i % 2 == 0) {
                    [values addObject:[NSValue valueWithCGPoint:CGPointMake(i * segmentProjectionWidthWithPrespetive, segmentLayer.position.y)]];
                }else {
                    [values addObject:[NSValue valueWithCGPoint:CGPointMake((i+1) * segmentProjectionWidthWithPrespetive, segmentLayer.position.y)]];
                }
            }
            positionAnimation.values = values;
            [segmentLayer addAnimation:positionAnimation forKey:@"positionAnimation"];
        }
        
        
        //tailLayer位置校正
        if (_tailLayer) {
            CAKeyframeAnimation *tailPositionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
            [tailPositionAnimation setFillMode:kCAFillModeForwards];
            [tailPositionAnimation setRemovedOnCompletion:NO];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:0];
            for (int f = 0; f <= duration * FOLDING_ANIMATING_FPS; f ++) {
                CGFloat progress = (f * 1.0)/(duration * FOLDING_ANIMATING_FPS);
                CGFloat angleAfterChange = angle + progress * (M_PI_2 - angle);
                
                CGFloat segmentProjectionWidthWithPrespetive = (ZDISTANCE * segmentWidth * cosf(angleAfterChange))/(ZDISTANCE + segmentWidth * sinf(angleAfterChange));
                [values addObject:[NSValue valueWithCGPoint:CGPointMake((_numberOfFolds *2) * segmentProjectionWidthWithPrespetive, _tailLayer.position.y)]];
            }
            tailPositionAnimation.values = values;
            [_tailLayer addAnimation:tailPositionAnimation forKey:@"tailPositionAnimation"];
        }
        
        [CATransaction commit];
    }
}


- (void)foldWithDuration:(NSTimeInterval)duration 
              completion:(void (^)(BOOL finished))completion{
    [self foldFromFoldAngle:0.0 withDuration:duration completion:completion];
}

@end
