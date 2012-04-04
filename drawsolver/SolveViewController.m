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
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@implementation SolveViewController
@synthesize screenshotView;
@synthesize image;
@synthesize results;
@synthesize resultLabel;
@synthesize logLabel;
@synthesize resultsTableView;

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
    
    CGRect cropRect;
    
    if(image.size.width == 320 && image.size.height == 480) {
        cropRect = CGRectMake(0, 53, 320, 277);
    }
    else if(image.size.width == 640 && image.size.height == 960) {
        cropRect = CGRectMake(0, 105, 640, 554);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);        
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  
    
    self.screenshotView.image = croppedImage;
    
    if([self.results count] == 1) {
        [self.resultsTableView setContentInset:UIEdgeInsetsMake(51, 0, 0, 0)];
    }
    else if([self.results count] == 2) {
        [self.resultsTableView setContentInset:UIEdgeInsetsMake(22, 0, 0, 0)];
    }
}

- (void)viewDidUnload
{
    [self setResultLabel:nil];
    [self setLogLabel:nil];
    [self setResultsTableView:nil];
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
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb225826214141508paid://"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb225826214141508paid://"]];                
    }    
    else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb225826214141508free://"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb225826214141508free://"]];
    }
}

- (IBAction)backToImport:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

# pragma mark UITableView methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.results count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [self.resultsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    if([indexPath indexAtPosition:1] != [self.results count] - 1) {
        cell.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-table-cell"]];
    }
    else {
        cell.contentView.backgroundColor = [UIColor clearColor];
    }
    
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.font = [UIFont fontWithName:@"GoLong" size:50];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.shadowColor = UIColorFromRGB(0x1e8538);
    cell.textLabel.shadowOffset = CGSizeMake(1,1);
    cell.textAlignment = UITextAlignmentCenter;
    cell.textLabel.text = [[self.results objectAtIndex:[indexPath indexAtPosition:1]] uppercaseString];    
    
    return cell;
}

- (void)dealloc {
    [resultLabel release];
    [logLabel release];
    [resultsTableView release];
    [super dealloc];
}
@end
