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

@implementation HomeViewController

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
    [self presentModalViewController:self.picker animated:YES];            
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {    
    SolveViewController *viewController = [[[SolveViewController alloc] initWithNibName:@"SolveViewController" bundle:nil] autorelease];
    viewController.image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [self dismissModalViewControllerAnimated:NO];       
    [self.navigationController pushViewController:viewController animated:YES];
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
