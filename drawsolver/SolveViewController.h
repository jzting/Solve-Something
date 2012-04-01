//
//  SolveViewController.h
//  drawsolver
//
//  Created by Jason Ting on 3/17/12.
//  Copyright (c) 2012 jzlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SolveViewController : UIViewController

@property (retain, nonatomic) IBOutlet UIImageView *screenshotView;
@property (retain, nonatomic) UIImage* image;
@property (retain, nonatomic) IBOutlet UILabel *resultLabel;
@property (retain, nonatomic) IBOutlet UILabel *logLabel;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

- (IBAction)backToGame:(id)sender;
@end
