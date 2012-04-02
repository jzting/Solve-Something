//
//  ViewController.m
//  drawsolver
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
#define SHARED_SECRET @"allyourdrawingsarebelongtous!"


@implementation HomeViewController

@synthesize iAdView;
@synthesize gsAdView;
@synthesize picker;
@synthesize quickImportButton;
@synthesize cameraRollButton;
@synthesize spinner;
@synthesize panelView;
@synthesize lightbulbView;
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
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;        
    self.picker = [[UIImagePickerController alloc] init];
    self.picker.delegate = self;

    [self.errorLabel setFont:[UIFont fontWithName:@"MyriadPro-Regular" size:16]];        
	self.gsAdView = [GSAdView adViewForSlotNamed:@"bannerSlot" delegate:self refreshInterval:kGSMinimumRefreshInterval];    
    [GSAdEngine setFullScreenDelegate:self forSlotNamed:@"fullscreenSlot"];    
}

- (void)viewDidUnload
{
    [self setSpinner:nil];
    [self setPanelView:nil];
    [self setLightbulbView:nil];
    [self setQuickImportButton:nil];
    [self setCameraRollButton:nil];
    [self setErrorLabel:nil];
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

- (IBAction)quickImport:(id)sender {
    [FlurryAnalytics logEvent:@"QuickImport"];    
    ALAssetsLibrary *library = [[[ALAssetsLibrary alloc] init] autorelease];      
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        void(^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop){
            if(group == nil) return;
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {         
                if(result == nil || index < [group numberOfAssets] - 1) return;
                NSLog(@"index: %i", index);
                [self solveImage:[UIImage imageWithCGImage:[[result defaultRepresentation] fullResolutionImage]]];
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
    [self dismissModalViewControllerAnimated:NO];    
    [self solveImage:[info valueForKey:UIImagePickerControllerOriginalImage]];    
}

# pragma mark - Solving
- (void)solveImage:(UIImage *)image {
    NSString *version;
    CGRect cropRect;
    
    if(image.size.width == 320 && image.size.height == 640) {
        version = @"lo";
        cropRect = CGRectMake(0, 331, 320, 149);
        [self sendScreen:image forVersion:version andRect:cropRect];
    }
    else if(image.size.width == 640 && image.size.height == 960) {
        version = @"hi";
        cropRect = CGRectMake(0, 661, 640, 299);
        [self sendScreen:image forVersion:version andRect:cropRect];        
    }
    else {
        self.quickImportButton.hidden = YES;
        self.errorLabel.text = @"Sorry, this does not look like a valid screenshot. Please try again.";
        self.errorLabel.hidden = NO;        
    }                                       
}

- (NSString *)createUUID {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject) autorelease];
    CFRelease(uuidObject);    
    return uuidStr;
}

- (void)animateSpinner {
    self.errorLabel.hidden = YES;
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

- (void)sendScreen:(UIImage *)image forVersion:(NSString *)version andRect:(CGRect)cropRect {
    [FlurryAnalytics logEvent:@"Solve" timed:YES];    
    NSDate *start = [NSDate date];        
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);        
    NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithCGImage:imageRef], 0.10);
    CGImageRelease(imageRef);    
    
    NSString *request_id = [self createUUID];
    double timestamp = [[NSDate date] timeIntervalSince1970];    
    NSString *auth_code = [[NSString stringWithFormat:@"%@:%f", request_id, timestamp]  HMACWithSecret:SHARED_SECRET];
    
    NSLog(@"request_id: %@", request_id);
    NSLog(@"auth_code: %@", auth_code);    
    
    // NSURL *url = [NSURL URLWithString:@"http://drawsolver.jzlabs.com"];                   
    NSURL *url = [NSURL URLWithString:@"http://192.168.1.125:5001"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:version, @"version", request_id, @"request_id", auth_code, @"auth_code", [NSString stringWithFormat:@"%f", timestamp], @"timestamp", nil];    
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/" parameters:params constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {                    
        [formData appendPartWithFileData:imageData name:@"file" fileName:@"screen.jpg" mimeType:@"image/jpeg"];
        
    }];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {        
        [self stopSpinner];        
        NSLog(@"JSON: %@", JSON); 
        [Appirater userDidSignificantEvent:YES];
        
        double networkTime = [[NSDate date] timeIntervalSinceDate:start] - [[JSON objectForKey:@"time_taken"] floatValue];        
        [FlurryAnalytics endTimedEvent:@"Solve" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i", [response statusCode]], @"result", nil]];    
        [FlurryAnalytics logEvent:@"Processing Time" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[JSON objectForKey:@"time_taken"], @"seconds" , nil]];        
        [FlurryAnalytics logEvent:@"Network Time" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", networkTime], @"seconds" , nil]];
        [FlurryAnalytics logEvent:@"Total Time" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSinceDate:start]], @"seconds" , nil]];
        
        // TODO: if no results, show message        
        NSString *messageString = [[JSON objectForKey:@"results"] componentsJoinedByString:@"  "];        
        
        NSString *logString = [NSString stringWithFormat:@"started %@\nprocessed in %@s\ntotal in %0.2fs", [JSON objectForKey:@"started"], [JSON objectForKey:@"time_taken"], [[NSDate date] timeIntervalSinceDate:start]];
        
        NSLog(@"processed in %@s", [JSON objectForKey:@"time_taken"]);
        NSLog(@"total time: %0.2fs", [[NSDate date] timeIntervalSinceDate:start]);
        
        SolveViewController *viewController = [[[SolveViewController alloc] initWithNibName:@"SolveViewController" bundle:nil] autorelease];
        viewController.image = image;
        viewController.results = [JSON objectForKey:@"results"];
        [self presentModalViewController:viewController animated:YES];
        
        //    [GSAdEngine displayFullScreenAdForSlotNamed:@"fullscreenSlot"];          
//        resultLabel.text = messageString;
//        logLabel.text = logString;        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {                    
        [FlurryAnalytics endTimedEvent:@"Solve" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i", [response statusCode]], @"result", nil]];        
        [FlurryAnalytics logEvent:@"Total Time" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSinceDate:start]], @"seconds" , nil]];        
        NSLog(@"statusCode: %i", [response statusCode]);
        NSString *errorMessage = @"Sorry, there was an error analyzing your screenshot. Please try again.";
        
        switch([response statusCode]) {
            case 0:
                errorMessage = @"Error connecting to solving server. Please check your internet connection.";
                break;
            case 410:
                [FlurryAnalytics logEvent:@"Expired Code" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[JSON objectForKey:@"difference"] , @"difference", nil]];                
                break;
            case 500:
                [FlurryAnalytics logEvent:@"Invalid Screenshot" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[JSON objectForKey:@"filename"] , @"filename", nil]];
                break;
            default:
                break;
        }
        
        NSLog(@"error: %@ %@", error, request);                            
   
        [self stopSpinner];    
        self.cameraRollButton.hidden = NO;
        self.errorLabel.text = errorMessage;
        self.errorLabel.hidden = NO;
    }];            
    
    [operation setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        NSLog(@"Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];                    
    
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];                
    [queue addOperation:operation];  
    [self animateSpinner];
}



# pragma mark - Greystripe Delegates
- (void)greystripeAdReadyForSlotNamed:(NSString *)a_name
{
	NSLog(@"Ad for slot named %@ is ready.",a_name);
	
	//Depending on which ad is ready, put the banner view into the view hiearchy, or enable the fullscreen ad button
	if ([a_name isEqual:@"fullscreenSlot"]) {        
	} else if ([a_name isEqual:@"bannerSlot"]) {
		[self.view addSubview:gsAdView];
	}
} 

- (void)greystripeFullScreenDisplayWillOpen {
    
	NSLog(@"Full screen ad is opening.");
}

- (void)greystripeFullScreenDisplayWillClose {
	NSLog(@"Full screen ad is closing.");
}

#pragma mark - iAd Delegates
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
    [spinner release];
    [panelView release];
    [lightbulbView release];
    [quickImportButton release];
    [cameraRollButton release];
    [errorLabel release];
    [super dealloc];
}

@end
