//
//  HomeViewController.m
//  Solve Something
//
//  Created by Jason Ting on 3/17/12.
//  Copyright (c) 2012 jzlabs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "HomeViewController.h"
#import "SolveViewController.h"
#import "AssetsLibrary/AssetsLibrary.h"
#import "FlurryAnalytics.h"
#import "GSAdEngine.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "Appirater.h"
#import "NSString+HMAC.h"
#define SHARED_SECRET @"allyourdrawingsarebelongtous!"

@implementation HomeViewController

@synthesize iAdView;
@synthesize gsAdView;
@synthesize gsBannerView;
@synthesize lastImage;
@synthesize lastResults;
@synthesize picker;
@synthesize instructionsView;
@synthesize logoView;
@synthesize letsGoButton;
@synthesize instructionsPanelView;
@synthesize answersButton;
@synthesize navBarView;
@synthesize quickImportButton;
@synthesize cameraRollButton;
@synthesize spinner;
@synthesize panelView;
@synthesize lightbulbView;
@synthesize errorView;
@synthesize errorLabel;

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
    self.picker = [[[UIImagePickerController alloc] init] autorelease];
    self.picker.delegate = self;

    [self.errorLabel setFont:[UIFont fontWithName:@"MyriadPro-Regular" size:16]];        
	self.gsAdView = [GSAdView adViewForSlotNamed:@"bannerSlot" delegate:self refreshInterval:kGSMinimumRefreshInterval];    
}

- (void)viewDidUnload
{
    [self setSpinner:nil];
    [self setPanelView:nil];
    [self setLightbulbView:nil];
    [self setQuickImportButton:nil];
    [self setCameraRollButton:nil];
    [self setErrorLabel:nil];
    [self setInstructionsView:nil];
    [self setLogoView:nil];
    [self setInstructionsPanelView:nil];
    [self setLetsGoButton:nil];
    [self setNavBarView:nil];
    [self setAnswersButton:nil];
    [self setErrorView:nil];
    [self setGsBannerView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self resetUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [FlurryAnalytics logPageView];
    if(self.instructionsView.alpha == 1) {
        CGRect newLogoFrame = self.logoView.frame;
        newLogoFrame.origin.y = 10;       
        
        [UIView animateWithDuration:0.5 delay:0 options:0 animations:^{
            self.logoView.frame = newLogoFrame;            
        } completion:^(BOOL finished) {}];

        [UIView animateWithDuration:0.5 delay:0.5 options:0 animations:^{            
            self.instructionsPanelView.alpha = 1;        
        } completion:^(BOOL finished) {}];        
        
        [UIView animateWithDuration:0.5 delay:0.75 options:0 animations:^{                
            self.letsGoButton.alpha = 1;
        } completion:^(BOOL finished) {}];        
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

# pragma mark - UI
- (void)resetUI {
    self.spinner.hidden = YES;
    self.lightbulbView.hidden = YES;
    self.quickImportButton.hidden = NO;    
    self.cameraRollButton.hidden = NO;
}

- (IBAction)showAnswers:(id)sender {
    [self showAnswersWithImage:self.lastImage andResults:self.lastResults];
}

- (IBAction)quickImport:(id)sender {
    [FlurryAnalytics logEvent:@"QuickImport"];    
    ALAssetsLibrary *library = [[[ALAssetsLibrary alloc] init] autorelease];      
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        void(^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop){
            if(group == nil) return;
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {         
                if(result == nil || index < [group numberOfAssets] - 1) return;
                [self solveImage:[UIImage imageWithCGImage:[[result defaultRepresentation] fullResolutionImage]]];
            }];
            [group numberOfAssets];
        };
        void(^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error){        
            NSString *otherButton = nil;
            if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"prefs://"]]) {
                otherButton = @"Settings";
            }
            [FlurryAnalytics logEvent:@"Quick Import Error"];
            UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Whoops!"
                                                                 message:@"We need location permission to import your latest photo. Please go to Settings and turn Location Services to \"ON\""
                                                                delegate:self
                                                       cancelButtonTitle:@"OK"
                                                       otherButtonTitles:otherButton, nil] autorelease];
            [alertView show];
        };  
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                               usingBlock:assetGroupEnumerator 
                             failureBlock:assetGroupEnumberatorFailure];        
        [pool release];
    });
}

- (IBAction)showPicker:(id)sender {
    [FlurryAnalytics logEvent:@"CameraRoll"];    
    [self presentViewController:self.picker animated:YES completion:nil];            
}

- (IBAction)dismissInstructions:(id)sender {
    if([sender tag] == 100) {
        [FlurryAnalytics logEvent:@"Dismiss-Panel"];
    }
    else {
        [FlurryAnalytics logEvent:@"Dismiss-Button"];
    }

    CGAffineTransform tr = CGAffineTransformScale(self.instructionsView.transform, 1.33, 1.33);    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.instructionsView.alpha = 0;
    self.instructionsView.transform = tr;
    [UIView commitAnimations];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {    
    [FlurryAnalytics logEvent:@"CameraRoll-Finished"];
    [self dismissViewControllerAnimated:YES completion:nil];    
    [self solveImage:[info valueForKey:UIImagePickerControllerOriginalImage]];    
}

# pragma mark - Solving
- (void)solveImage:(UIImage *)image {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *version;
    CGRect cropRect;
    
    if(image.size.width == 320 && image.size.height == 480) {
        version = @"lo";
        cropRect = CGRectMake(0, 331, 320, 149);
        if([userDefaults objectForKey:@"letters_rect_lo"]) {
            NSArray *lettersRect = [userDefaults objectForKey:@"letters_rect_lo"];
            NSLog(@"letters_rect_lo %@", lettersRect);
            cropRect = CGRectMake([[lettersRect objectAtIndex:0] floatValue],
                                  [[lettersRect objectAtIndex:1] floatValue],
                                  [[lettersRect objectAtIndex:2] floatValue],
                                  [[lettersRect objectAtIndex:3] floatValue]);
        }
        [self sendScreen:image forVersion:version andRect:cropRect];
    }
    else if(image.size.width == 640 && image.size.height == 960) {
        version = @"hi";
        cropRect = CGRectMake(0, 661, 640, 299);
        if([userDefaults objectForKey:@"letters_rect_hi"]) {
            NSArray *lettersRect = [userDefaults objectForKey:@"letters_rect_hi"];
            NSLog(@"letters_rect_hi %@", lettersRect);
            cropRect = CGRectMake([[lettersRect objectAtIndex:0] floatValue],
                                  [[lettersRect objectAtIndex:1] floatValue],
                                  [[lettersRect objectAtIndex:2] floatValue],
                                  [[lettersRect objectAtIndex:3] floatValue]);
        }
        [self sendScreen:image forVersion:version andRect:cropRect];        
    }
    else {
        self.errorLabel.text = @"Sorry, this does not look like a valid screenshot. Please try again.";
        [FlurryAnalytics logEvent:@"Invalid Screenshot" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%0.2f", image.size.width], @"width", [NSString stringWithFormat:@"%0.2f", image.size.height], @"height", nil]];        
        [self showErrorView];
    }                                       
}

- (NSString *)createUUID {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject) autorelease];
    CFRelease(uuidObject);    
    return uuidStr;
}

- (void)animateSpinner {
    self.spinner.hidden = NO;
    self.lightbulbView.hidden = NO;    
    self.quickImportButton.hidden = YES;
    self.cameraRollButton.hidden = YES;
    
    CABasicAnimation *rotate;
    rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotate.fromValue = [NSNumber numberWithFloat:0];
    rotate.toValue = [NSNumber numberWithFloat:M_PI * 2];
    rotate.duration = 2;
    rotate.repeatCount = 1e9;
    [self.spinner.layer addAnimation:rotate forKey:@"10"];    
}

- (void)stopSpinner {
    self.lightbulbView.hidden = YES;        
    self.spinner.hidden = YES;
}

- (void)showErrorView {
    self.errorView.hidden = NO;  
    self.panelView.hidden = YES;    
}

- (void)hideErrorView {
    self.errorView.hidden = YES;  
    self.panelView.hidden = NO;    
}

- (void)sendScreen:(UIImage *)image forVersion:(NSString *)version andRect:(CGRect)cropRect {
    [self hideErrorView];
    self.answersButton.enabled = NO;
    [GSAdEngine displayFullScreenAdForSlotNamed:@"fullscreenSlot"];
    [FlurryAnalytics logEvent:@"Solve" timed:YES];
    NSDate *start = [NSDate date];        
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    float quality = 0.10;
    if([userDefaults objectForKey:@"quality_hi"]) {
        quality = [userDefaults floatForKey:@"quality_hi"];
    }

    if([version isEqualToString:@"lo"]) {
        quality = 0.5;
        if([userDefaults objectForKey:@"quality_lo"]) {
            quality = [userDefaults floatForKey:@"quality_lo"];
        }
    }

    NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithCGImage:imageRef], quality);
    CGImageRelease(imageRef);    
    
    NSString *request_id = [self createUUID];
    double timestamp = [[NSDate date] timeIntervalSince1970];    
    NSString *auth_code = [[NSString stringWithFormat:@"%@:%f", request_id, timestamp]  HMACWithSecret:SHARED_SECRET];
    NSURL *url = [NSURL URLWithString:@"http://drawsolver.jzlabs.com"];                   
    //NSURL *url = [NSURL URLWithString:@"http://192.168.1.125:5001"];
    
    AFHTTPClient *httpClient = [[[AFHTTPClient alloc] initWithBaseURL:url] autorelease];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:version, @"version", request_id, @"request_id", auth_code, @"auth_code", [NSString stringWithFormat:@"%f", timestamp], @"timestamp", nil];    
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/" parameters:params constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {                    
        [formData appendPartWithFileData:imageData name:@"file" fileName:@"screen.jpg" mimeType:@"image/jpeg"];
    }];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {        
        [self stopSpinner];
        [Appirater userDidSignificantEvent:YES];
        double networkTime = [[NSDate date] timeIntervalSinceDate:start] - [[JSON objectForKey:@"time_taken"] floatValue];        
        [FlurryAnalytics endTimedEvent:@"Solve" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i", [response statusCode]], @"result", nil]];    
        [FlurryAnalytics logEvent:@"Processing Time" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[JSON objectForKey:@"time_taken"], @"seconds" , nil]];        
        [FlurryAnalytics logEvent:@"Network Time" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", networkTime], @"seconds" , nil]];
        [FlurryAnalytics logEvent:@"Total Time" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSinceDate:start]], @"seconds" , nil]];

        NSLog(@"Processed in %@s", [JSON objectForKey:@"time_taken"]);
        NSLog(@"Total time: %0.2fs", [[NSDate date] timeIntervalSinceDate:start]);
        
        if([[JSON objectForKey:@"results"] count] == 0) {
            [FlurryAnalytics logEvent:@"No Results"];
            [self stopSpinner];    
            self.errorLabel.text = @"Sorry, there was an error analyzing your screenshot. Please try again.";
            [self showErrorView];             
        }
        else {        
            self.navBarView.image = [UIImage imageNamed:@"navbar-import"];
            self.answersButton.enabled = YES;                
            [self showAnswersWithImage:image andResults:[JSON objectForKey:@"results"]];
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {                    
        [FlurryAnalytics endTimedEvent:@"Solve" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i", [response statusCode]], @"result", nil]];        
        [FlurryAnalytics logEvent:@"Total Time" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSinceDate:start]], @"seconds" , nil]];        
        NSLog(@"Status: %i", [response statusCode]);
        NSString *errorMessage = @"Sorry, there was an error analyzing your screenshot. Please try again.";
        
        switch([response statusCode]) {
            case 0:
                [FlurryAnalytics logEvent:@"Connection Timeout"];
                errorMessage = @"Error connecting to solving server. Please check your internet connection.";
                break;
            case 410:
                [FlurryAnalytics logEvent:@"Expired Code"];
                break;
            case 500:
                [FlurryAnalytics logEvent:@"Invalid Screenshot"];
                [self checkForServerUpdate];
                break;
            default:
                break;
        }
        
        if(self.lastImage) {
            self.answersButton.enabled = YES;
        }
        [self stopSpinner];    
        self.errorLabel.text = errorMessage;
        [self showErrorView];        
    }];            
    
    [operation setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        NSLog(@"Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];                    
    
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];                
    [queue addOperation:operation];  
    [self animateSpinner];
}

- (void)checkForServerUpdate {
    NSLog(@"checking for server update");
    NSURL *url = [NSURL URLWithString:@"http://drawsolver.jzlabs.com/update"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *data = [JSON objectForKey:@"data"];
        NSDictionary *hi = [data objectForKey:@"hi"];
        NSDictionary *lo = [data objectForKey:@"lo"];
        NSLog(@"hi: %@", hi);
        NSLog(@"lo: %@", lo);
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:[lo objectForKey:@"quality"] forKey:@"quality_lo"];
		[userDefaults setObject:[hi objectForKey:@"quality"] forKey:@"quality_hi"];
		[userDefaults setObject:[lo objectForKey:@"image_rect"] forKey:@"image_rect_lo"];
		[userDefaults setObject:[hi objectForKey:@"image_rect"] forKey:@"image_rect_hi"];
		[userDefaults setObject:[lo objectForKey:@"letters_rect"] forKey:@"letters_rect_lo"];
		[userDefaults setObject:[hi objectForKey:@"letters_rect"] forKey:@"letters_rect_hi"];
    } failure:nil];
    [operation start];
}

- (void)showAnswersWithImage:(UIImage *)image andResults:(NSArray *)results {
    SolveViewController *viewController = [[[SolveViewController alloc] initWithNibName:@"SolveViewController" bundle:nil] autorelease];
    viewController.image = image;
    viewController.results = results;
    self.lastImage = image;
    self.lastResults = results;

    [self.navigationController pushViewController:viewController animated:NO];    
}

# pragma mark - UIAlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case 1:
		{
            [FlurryAnalytics logEvent:@"Enabling Location"];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=LOCATION_SERVICES"]];
			break;
		}
		default:
			break;
	}
}

# pragma mark - Greystripe Delegates
- (void)greystripeAdReadyForSlotNamed:(NSString *)a_name
{
	//Depending on which ad is ready, put the banner view into the view hiearchy, or enable the fullscreen ad button
	if ([a_name isEqual:@"fullscreenSlot"]) {        
	} else if ([a_name isEqual:@"bannerSlot"]) {
        [self.gsBannerView addSubview:gsAdView];
	}
} 

- (void)greystripeFullScreenDisplayWillClose {
    [FlurryAnalytics logEvent:@"Greystripe Ad Closed"];
	[self showAnswers:nil];
}

#pragma mark - iAd Delegates
- (void)adjustPanelFrame {
    CGRect newPanelFrame = self.panelView.frame;
    newPanelFrame.origin.y = 120;       
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [self.panelView setFrame:newPanelFrame];
    [UIView commitAnimations];    
}

- (void)hideGreystripeAd {
    CGRect newBannerFrame = self.iAdView.frame;
    newBannerFrame.origin.y = 430;       
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [self.iAdView setFrame:newBannerFrame];    
    self.gsBannerView.alpha = 0;
    [UIView commitAnimations];
}

- (void)showGreystripeAd {
    CGRect newBannerFrame = self.iAdView.frame;
    newBannerFrame.origin.y = 480;    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    [self.iAdView setFrame:newBannerFrame];
    self.gsBannerView.alpha = 1;
    [UIView commitAnimations];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [self showGreystripeAd];
}

- (void)bannerViewWillLoadAd:(ADBannerView *)banner {
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [FlurryAnalytics logEvent:@"iAd Loaded"];
    [self adjustPanelFrame];
    [self hideGreystripeAd];  
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
	return YES;	
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {	
    [FlurryAnalytics logEvent:@"iAd Closed"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [spinner release];
    [panelView release];
    [lightbulbView release];
    [quickImportButton release];
    [cameraRollButton release];
    [errorLabel release];
    [instructionsView release];
    [logoView release];
    [instructionsPanelView release];
    [letsGoButton release];
    [navBarView release];
    [answersButton release];
    [errorView release];
    [gsBannerView release];
    [super dealloc];
}

@end