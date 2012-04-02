//
//  HomeViewController.h
//  drawsolver
//
//  Created by Jason Ting on 3/17/12.
//  Copyright (c) 2012 jzlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "GreystripeDelegate.h"
#import "GSAdView.h"

@interface HomeViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ADBannerViewDelegate, GreystripeDelegate> {
    GSAdView *gsAdView;
    ADBannerView *iAdView;
}

@property (nonatomic,retain) GSAdView *gsAdView;
@property (nonatomic,retain) ADBannerView *iAdView;
@property (retain, nonatomic) UIImagePickerController *picker;
- (IBAction)showPicker:(id)sender;

@end
