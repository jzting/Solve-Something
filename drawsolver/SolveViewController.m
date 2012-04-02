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
    // Do any additional setup after loading the view from its nib.
    self.screenshotView.image = image;
    
    NSString *version;
    CGRect cropRect;

    if(image.size.width == 320 && image.size.height == 640) {
        version = @"lo";
        cropRect = CGRectMake(0, 331, 320, 149);
        [self sendScreenForVersion:version andRect:cropRect];
    }
    else if(image.size.width == 640 && image.size.height == 960) {
        version = @"hi";
        cropRect = CGRectMake(0, 661, 640, 299);
        [self sendScreenForVersion:version andRect:cropRect];        
    }
    else {
        NSLog(@"not a valid screenshot");
    }                
}

- (NSString *)createUUID
{
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject) autorelease];
    CFRelease(uuidObject);    
    return uuidStr;
}

- (void)sendScreenForVersion:(NSString *)version andRect:(CGRect)cropRect {
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
        self.loadingIndicator.hidden = YES;
        resultLabel.text = messageString;
        logLabel.text = logString;        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {                    
        [FlurryAnalytics endTimedEvent:@"Solve" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i", [response statusCode]], @"result", nil]];        
        [FlurryAnalytics logEvent:@"Total Time" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSinceDate:start]], @"seconds" , nil]];        
        NSLog(@"statusCode: %i", [response statusCode]);
        NSString *errorMessage;
        
        switch([response statusCode]) {
            case 0:
                errorMessage = @"Error connecting to solve server.";
                break;
            case 400:
                errorMessage = @"Not authorized.";                
            case 401:
                errorMessage = @"Not authorized.";                
            case 410:
                [FlurryAnalytics logEvent:@"Expired Code" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[JSON objectForKey:@"difference"] , @"difference", nil]];                
                errorMessage = @"Not authorized.";
                break;
            case 500:
                [FlurryAnalytics logEvent:@"Invalid Screenshot" withParameters:[NSDictionary dictionaryWithObjectsAndKeys:[JSON objectForKey:@"filename"] , @"filename", nil]];
                errorMessage = @"Invalid screenshot.";
                break;
            default:
                errorMessage = @"Error, please try again.";
                break;
        }
        
        NSLog(@"error: %@ %@", error, request);                            
        self.loadingIndicator.hidden = YES;        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error"
                                                          message:errorMessage
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
