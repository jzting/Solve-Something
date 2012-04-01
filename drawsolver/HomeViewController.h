//
//  HomeViewController.h
//  drawsolver
//
//  Created by Jason Ting on 3/17/12.
//  Copyright (c) 2012 jzlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (retain, nonatomic) UIImagePickerController *picker;
- (IBAction)showPicker:(id)sender;

@end
