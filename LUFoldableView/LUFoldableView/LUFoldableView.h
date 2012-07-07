/*
 Copyright (c) 2012, Luke
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of the geeklu.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import <UIKit/UIKit.h>

@interface LUFoldableView : UIView{
    UIImage          *_imageToFold;
    UIImage          *_tailImage;
    NSInteger        _numberOfFolds;
    BOOL             _vertical;
    
    NSMutableArray  *_foldSegmentLayers;
    CALayer         *_tailLayer;
    
    UIView          *_backgroundView;
    UIView          *_containerView;    
}

@property (nonatomic, readonly) UIImage *imageToFold;
@property (nonatomic, readonly) UIImage *tailImage;
@property (nonatomic, readonly) NSInteger numberOfFolds;
@property (nonatomic, retain) UIView *backgroundView;


- (BOOL)isVertical;

/*!
 default initializer
 @param imageToFold     the image used to fold
 @param tailImage       the image follow the imageToFold
 @param numberOfFolds   the number of folds
 @param vertical        the orientation of the folding
 */
- (id)initWithImage:(UIImage *)imageToFold tailImage:(UIImage *)tailImage numberOfFolds:(NSInteger)numberOfFolds vertical:(BOOL)vertical;

/*!
 foldAngle是指每一个折叠单元改变的角度
 */
- (void)setFoldAngle:(CGFloat)angle;

/*!
 这里的foldRate是指当前折叠状态的的折叠率,这里的折叠率是指改变掉的长度占原总长度的比率
 */
- (void)setFoldRate:(CGFloat)rate;


- (void)unfoldFromFoldAngle:(CGFloat)angle 
                      withDuration:(NSTimeInterval)duration 
                        completion:(void (^)(BOOL finished))completion;

- (void)unfoldWithDuration:(NSTimeInterval)duration 
                       completion:(void (^)(BOOL finished))completion;


- (void)foldFromFoldAngle:(CGFloat)angle 
             withDuration:(NSTimeInterval)duration 
               completion:(void (^)(BOOL finished))completion;

- (void)foldWithDuration:(NSTimeInterval)duration 
                        completion:(void (^)(BOOL finished))completion;
@end
