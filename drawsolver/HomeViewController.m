//
//  ViewController.m
//  drawsolver
//
//  Created by Jason Ting on 3/17/12.
//  Copyright (c) 2012 jzlabs. All rights reserved.
//

#import "HomeViewController.h"
#import "SolveViewController.h"
#import "AssetsLibrary/AssetsLibrary.h"
#import "FlurryAnalytics.h"
#import "GSAdEngine.h"

@implementation HomeViewController

@synthesize gsAdView;
@synthesize picker;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.picker = [[UIImagePickerController alloc] init];
    self.picker.delegate = self;
    
	self.gsAdView = [GSAdView adViewForSlotNamed:@"bannerSlot" delegate:self refreshInterval:kGSMinimumRefreshInterval];    
    [GSAdEngine setFullScreenDelegate:self forSlotNamed:@"fullscreenSlot"];    
    
//    self.picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (IBAction)loadLatest:(id)sender {
    [FlurryAnalytics logEvent:@"QuickImport"];    
    ALAssetsLibrary *library = [[[ALAssetsLibrary alloc] init] autorelease];      
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        void(^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop){
            if(group == nil) return;
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {         
                if(result == nil || index < [group numberOfAssets] - 1) return;
                NSLog(@"index: %i", index);
                SolveViewController *viewController = [[[SolveViewController alloc] initWithNibName:@"SolveViewController" bundle:nil] autorelease];
                viewController.image = [UIImage imageWithCGImage:[[result defaultRepresentation] fullResolutionImage]];
                [self.navigationController pushViewController:viewController animated:YES];
                [GSAdEngine displayFullScreenAdForSlotNamed:@"fullscreenSlot"];                                
            }];
            [group numberOfAssets];
        };
        void(^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error){        
            NSLog(@"A problem occured %@", [error description]);
        };  
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                               usingBlock:assetGroupEnumerator 
                             failureBlock:assetGroupEnumberatorFailure];        
        [pool release];
    });
    

}

- (IBAction)showPicker:(id)sender {
    [FlurryAnalytics logEvent:@"CameraRoll"];    
    [self presentModalViewController:self.picker animated:YES];            
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {    
    [FlurryAnalytics logEvent:@"CameraRoll-Finished"];
    SolveViewController *viewController = [[[SolveViewController alloc] initWithNibName:@"SolveViewController" bundle:nil] autorelease];
    viewController.image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [self dismissModalViewControllerAnimated:NO];       
    [self.navigationController pushViewController:viewController animated:YES];
    [GSAdEngine displayFullScreenAdForSlotNamed:@"fullscreenSlot"];
}

# pragma -
//Delegate method is called when an ad is ready to be displayed
- (void)greystripeAdReadyForSlotNamed:(NSString *)a_name
{
	NSLog(@"Ad for slot named %@ is ready.",a_name);
	
	//Depending on which ad is ready, put the banner view into the view hiearchy, or enable the fullscreen ad button
	if ([a_name isEqual:@"fullscreenSlot"]) {        
	} else if ([a_name isEqual:@"bannerSlot"]) {
		[self.view addSubview:gsAdView];
	}
} 

//Delegate methods for full screen or click-through open and close. This is the place to suspend/restart other app activity.
- (void)greystripeFullScreenDisplayWillOpen {
    
	NSLog(@"Full screen ad is opening.");
}

- (void)greystripeFullScreenDisplayWillClose {
	NSLog(@"Full screen ad is closing.");
}

#pragma mark -
#pragma mark iAd delegate methods

- (void)moveBannerViewOnscreen {
    CGRect newBannerFrame = self.iAdView.frame;
    newBannerFrame.origin.y = 0;
    	
    [UIView beginAnimations:@"BannerViewIntro" context:NULL];
    [UIView setAnimationDuration:0.2];      
    self.iAdView.frame = newBannerFrame;  
    [UIView commitAnimations];	
}

- (void)moveBannerViewOffscreen:(BOOL)animated {
    CGRect newBannerFrame = self.iAdView.frame;
    newBannerFrame.origin.y = -70;
	    
	if(animated) {
		[UIView beginAnimations:@"BannerViewIntro" context:NULL];
		[UIView setAnimationDuration:0.2];
	}
	self.iAdView.frame = newBannerFrame;	
	
	if(animated) {
		[UIView commitAnimations];	
	}
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [self moveBannerViewOffscreen:YES];
}

- (void)bannerViewWillLoadAd:(ADBannerView *)banner {
    
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [self moveBannerViewOnscreen];  
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
	return YES;	
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {	
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)dealloc {
    [super dealloc];
}

@end
