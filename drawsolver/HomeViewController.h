//
//  HomeViewController.h
//  Solve Something
//
//  Created by Jason Ting on 3/17/12.
//  Copyright (c) 2012 jzlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import "GreystripeDelegate.h"
#import "GSAdView.h"

@interface HomeViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ADBannerViewDelegate, GreystripeDelegate, UIAlertViewDelegate> {
    GSAdView *gsAdView;
    ADBannerView *iAdView;
    UIImage *lastImage;
    NSArray *lastResults;
}

@property (nonatomic,retain) GSAdView *gsAdView;
@property (retain, nonatomic) IBOutlet UIView *gsBannerView;
@property (nonatomic,retain) IBOutlet ADBannerView *iAdView;
@property (nonatomic, retain) UIImage *lastImage;
@property (nonatomic, retain)  NSArray *lastResults;
@property (retain, nonatomic) UIImagePickerController *picker;
@property (retain, nonatomic) IBOutlet UIView *instructionsView;
@property (retain, nonatomic) IBOutlet UIImageView *logoView;
@property (retain, nonatomic) IBOutlet UIButton *letsGoButton;
@property (retain, nonatomic) IBOutlet UIImageView *instructionsPanelView;
@property (retain, nonatomic) IBOutlet UIButton *answersButton;
@property (retain, nonatomic) IBOutlet UIImageView *navBarView;
@property (retain, nonatomic) IBOutlet UIButton *quickImportButton;
@property (retain, nonatomic) IBOutlet UIButton *cameraRollButton;
@property (retain, nonatomic) IBOutlet UIImageView *spinner;
@property (retain, nonatomic) IBOutlet UIView *panelView;
@property (retain, nonatomic) IBOutlet UIImageView *lightbulbView;
@property (retain, nonatomic) IBOutlet UIView *errorView;
@property (retain, nonatomic) IBOutlet UILabel *errorLabel;

- (IBAction)quickImport:(id)sender;
- (IBAction)showPicker:(id)sender;
- (IBAction)dismissInstructions:(id)sender;
- (IBAction)showAnswers:(id)sender;
- (void)resetUI;
- (void)showAnswers:(id)sender;
- (void)solveImage:(UIImage *)image;
- (void)sendScreen:(UIImage *)image forVersion:(NSString *)version andRect:(CGRect)cropRect;
- (void)showAnswersWithImage:(UIImage *)image andResults:(NSArray *)results;
- (void)showErrorView;
- (void)hideErrorView;

@end