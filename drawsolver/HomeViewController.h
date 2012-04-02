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
@property (retain, nonatomic) IBOutlet UIButton *quickImportButton;
@property (retain, nonatomic) IBOutlet UIButton *cameraRollButton;
@property (retain, nonatomic) IBOutlet UIImageView *spinner;
@property (retain, nonatomic) IBOutlet UIView *panelView;
@property (retain, nonatomic) IBOutlet UIImageView *lightbulbView;
@property (retain, nonatomic) IBOutlet UILabel *errorLabel;

- (IBAction)quickImport:(id)sender;
- (IBAction)showPicker:(id)sender;

@end