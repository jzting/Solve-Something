//
//  SolveViewController.m
//  drawsolver
//
//  Created by Jason Ting on 3/17/12.
//  Copyright (c) 2012 jzlabs. All rights reserved.
//

#import "SolveViewController.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "Appirater.h"
#import "FlurryAnalytics.h"
#define SHARED_SECRET @"allyourdrawingsarebelongtous!"

@implementation SolveViewController
@synthesize screenshotView;
@synthesize image;
@synthesize results;
@synthesize resultLabel;
@synthesize logLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;                
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    CGRect cropRect;
    
    if(image.size.width == 320 && image.size.height == 640) {
        cropRect = CGRectMake(0, 53, 320, 277);
    }
    else if(image.size.width == 640 && image.size.height == 960) {
        cropRect = CGRectMake(0, 105, 640, 554);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);        
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  
    
    self.screenshotView.image = croppedImage;
    [self.resultLabel setFont:[UIFont fontWithName:@"GoLong" size:40]];            
    self.resultLabel.text = [[results componentsJoinedByString:@"\n"] uppercaseString];
}


- (void)viewDidUnload
{
    [self setResultLabel:nil];
    [self setLogLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)backToGame:(id)sender {
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb225826214141508free://"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb225826214141508free://"]];        
    }
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb225826214141508paid://"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb225826214141508paid://"]];                
    }
    
}

- (IBAction)backToImport:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)dealloc {
    [resultLabel release];
    [logLabel release];
    [super dealloc];
}
@end
