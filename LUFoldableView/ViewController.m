//
//  ViewController.m
//  LUFoldableView
//
//  Created by Lu Ke on 7/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "LUFoldableView.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    LUFoldableView *foldableView = [[[LUFoldableView alloc] initWithImage:[UIImage imageNamed:@"1.png"] tailImage:[UIImage imageNamed:@"2.png"] numberOfFolds:2 vertical:NO] autorelease];
    [self.view addSubview:foldableView];
    [foldableView foldWithDuration:3.5 completion:^(BOOL finished){}];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
