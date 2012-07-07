/*
 Copyright (c) 2012, Luke
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of the geeklu.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "LUFoldSegmentLayer.h"
#import "LUImageHelper.h"

@implementation LUFoldSegmentLayer
@synthesize shadowMaskOpacity = _shadowMaskOpacity;
@synthesize shadowMaskLayer = _shadowMaskLayer;
@synthesize shadowMaskInsets = _shadowMaskInsets;

- (void)dealloc{
    [_shadowMaskLayer release];
    [super dealloc];
}


- (id)init{
    if (self = [super init]) {
        _shadowMaskLayer = [[CALayer alloc] init];
        _shadowMaskLayer.frame = self.bounds;
        //_shadowMaskLayer.backgroundColor = [UIColor blackColor].CGColor;
        _shadowMaskLayer.opacity = 0.0;
        _shadowMaskInsets = UIEdgeInsetsZero;
        
        [self addSublayer:_shadowMaskLayer];
    }
    return self;
}


- (void)setShadowMaskOpacity:(CGFloat)shadowMaskOpacity{
    _shadowMaskLayer.opacity = shadowMaskOpacity;
}

- (void)setShadowMaskInsets:(UIEdgeInsets)shadowMaskInsets{
    _shadowMaskInsets = shadowMaskInsets;
    
    CGSize blackSize = UIEdgeInsetsInsetRect(self.bounds, shadowMaskInsets).size;
    
    CGImageRef blackImage = CreateBlackImage(blackSize);
    CGImageRef opImage = CreateImageWithBorderInset(blackImage,blackSize,_shadowMaskInsets);
    _shadowMaskLayer.contents = (id)opImage;
    if (opImage) {
        CFRelease(opImage);
    }
    if (blackImage) {
        CFRelease(blackImage);
    }
    [self layoutIfNeeded];
}


//important
- (void)layoutSublayers{
    [super layoutSublayers];    
    _shadowMaskLayer.frame = self.bounds ;
}

@end
