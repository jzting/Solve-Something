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

@implementation SolveViewController
@synthesize screenshotView;
@synthesize image;
@synthesize resultLabel;
@synthesize logLabel;
@synthesize loadingIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    NSDate *start = [NSDate date];    
    // Do any additional setup after loading the view from its nib.
    self.screenshotView.image = image;
    
    NSString *version;
    CGRect cropRect;

    if(image.size.width == 320 && image.size.height == 640) {
        version = @"lo";
        cropRect = CGRectMake(0, 331, 320, 149);
    }
    else if(image.size.width == 640 && image.size.height == 960) {
        version = @"hi";
        cropRect = CGRectMake(0, 661, 640, 299);
    }
    else {
        NSLog(@"not a valid screenshot");
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);        
    NSData *imageData = UIImageJPEGRepresentation([UIImage imageWithCGImage:imageRef], 0.10);
    CGImageRelease(imageRef);    
    
    NSURL *url = [NSURL URLWithString:@"http://drawsolver.jzlabs.com"];                   
//    NSURL *url = [NSURL URLWithString:@"http://192.168.1.125:5001"];
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/" parameters:nil constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {                    
        [formData appendPartWithFileData:imageData name:@"file" fileName:@"screen.jpg" mimeType:@"image/jpeg"];
        
    }];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {                    
        NSLog(@"JSON: %@", JSON); 
        NSString *messageString = [[JSON objectForKey:@"results"] componentsJoinedByString:@"  "];        
        
        NSString *logString = [NSString stringWithFormat:@"started %@\nprocessed in %@s\ntotal in %0.2fs", [JSON objectForKey:@"started"], [JSON objectForKey:@"time_taken"], [[NSDate date] timeIntervalSinceDate:start]];
                               
        NSLog(@"processed in %@s", [JSON objectForKey:@"time_taken"]);
        NSLog(@"total time: %0.2fs", [[NSDate date] timeIntervalSinceDate:start]);
        self.loadingIndicator.hidden = YES;
        resultLabel.text = messageString;
        logLabel.text = logString;        
                               
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {                    
        NSLog(@"error: %@ %@", error, request);                            
        self.loadingIndicator.hidden = YES;        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Invalid Screenshot"
                                                          message:@"This does not look like a Draw Something game screen."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        
        [message show];
    }];            
    
    [operation setUploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        NSLog(@"Sent %d of %d bytes", totalBytesWritten, totalBytesExpectedToWrite);
    }];                    
    
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];                
    [queue addOperation:operation];        
}

- (void)viewDidUnload
{
    [self setResultLabel:nil];
    [self setLoadingIndicator:nil];
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

- (void)dealloc {
    [resultLabel release];
    [loadingIndicator release];
    [logLabel release];
    [super dealloc];
}
@end
