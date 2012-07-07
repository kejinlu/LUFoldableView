/*
 Copyright (c) 2012, Luke
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of the geeklu.com nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "LUImageHelper.h"

CGImageRef CreateMask(CGSize size, UIEdgeInsets insets)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       size.width,
                                                       size.height,
                                                       8,
                                                       size.width * 32,
                                                       colorSpace,
                                                       kCGBitmapByteOrderDefault | kCGImageAlphaNone);
    if (bitmapContext == NULL) 
    {
        NSLog(@"create mask bitmap context failed");
		return nil;
    }
    
    // fill the black color in whole size, anything in black area will be transparent.
    CGContextSetFillColorWithColor(bitmapContext, [UIColor blackColor].CGColor);
    CGContextFillRect(bitmapContext, CGRectMake(0, 0, size.width, size.height));
    
    // fill the white color in whole size, anything in white area will keep.
    CGContextSetFillColorWithColor(bitmapContext, [UIColor whiteColor].CGColor);
    CGContextFillRect(bitmapContext, CGRectMake(insets.left , insets.bottom, size.width - (insets.left + insets.right), size.height - (insets.top + insets.bottom)));
    
    // acquire the mask
    CGImageRef maskImageRef = CGBitmapContextCreateImage(bitmapContext);
    
    // clean up
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(colorSpace);
    
    return maskImageRef;
}


CGImageRef CreateImageWithBorderInset(CGImageRef originImage,CGSize originImageSize, UIEdgeInsets borderInsets){
    size_t newWidth = originImageSize.width + borderInsets.left + borderInsets.right;
    size_t newHeight = originImageSize.height + borderInsets.top + borderInsets.bottom;
    
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = bitsPerPixel * newWidth;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();    
    if(colorSpace == NULL) 
    {
		NSLog(@"create color space failed");
		return nil;
	}
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       newWidth,
                                                       newHeight,
                                                       bitsPerComponent,
                                                       bytesPerRow,
                                                       colorSpace,
                                                       kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    if (bitmapContext == NULL) 
    {
        NSLog(@"create bitmap context failed");
		return nil;
    }
    
    // acquire image with opaque border 
    CGRect imageRect = CGRectMake(borderInsets.left, borderInsets.bottom, originImageSize.width, originImageSize.height);
    CGContextDrawImage(bitmapContext, imageRect, originImage);
    CGImageRef opaqueBorderImageRef = CGBitmapContextCreateImage(bitmapContext);
    
    // acquire image with transparent border 
    CGImageRef maskImageRef = CreateMask(CGSizeMake(newWidth, newHeight), borderInsets);
    CGImageRef transparentBorderImageRef = CGImageCreateWithMask(opaqueBorderImageRef, maskImageRef);
    
    // clean up
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(bitmapContext);
    CGImageRelease(opaqueBorderImageRef);
    CGImageRelease(maskImageRef);
    
    return transparentBorderImageRef;
}


CGImageRef CreateBlackImage(CGSize size)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       size.width,
                                                       size.height,
                                                       8,
                                                       size.width * 32,
                                                       colorSpace,
                                                       kCGBitmapByteOrderDefault | kCGImageAlphaNone);
    if (bitmapContext == NULL) 
    {
        NSLog(@"create mask bitmap context failed");
		return nil;
    }
    
    // fill the black color in whole size, anything in black area will be transparent.
    CGContextSetFillColorWithColor(bitmapContext, [UIColor blackColor].CGColor);
    CGContextFillRect(bitmapContext, CGRectMake(0, 0, size.width, size.height));
    
    // acquire the mask
    CGImageRef blackImageRef = CGBitmapContextCreateImage(bitmapContext);
    
    // clean up
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(colorSpace);
    
    return blackImageRef;
}
