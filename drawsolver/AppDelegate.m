//
//  AppDelegate.m
//  Solve Something
//
//  Created by Jason Ting on 3/17/12.
//  Copyright (c) 2012 jzlabs. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeViewController.h"
#import "Appirater.h"
#import "FlurryAnalytics.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
}

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
     
    HomeViewController *homeViewController = [[[HomeViewController alloc] initWithNibName:@"HomeViewController" bundle:nil] autorelease];
    self.navigationController = [[[UINavigationController alloc] initWithRootViewController:homeViewController] autorelease];
    self.navigationController.navigationBarHidden = YES;
    self.window.rootViewController = self.navigationController;
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    [FlurryAnalytics startSession:@"AQKQNCHBKC4Y5PIN8VLB"];
    [Appirater appLaunched:YES];
    
	//Define two ad slots. Name them and give the sizes as one banner and one fullscreen.
	GSAdSlotDescription * slot1 = [GSAdSlotDescription descriptionWithSize:kGSAdSizeBanner name:@"bannerSlot"];
	GSAdSlotDescription * slot2 = [GSAdSlotDescription descriptionWithSize:kGSAdSizeIPhoneFullScreen name:@"fullscreenSlot"];
	
	//Start the GSAdEngine with our slots.
	[GSAdEngine startupWithAppID:@"9d713c2a-841f-4205-8702-0ba42387b393" adSlotDescriptions:[NSArray arrayWithObjects:slot1, slot2, nil]];

	//Use the .version property to check that the latest SDK is included
    //NSLog(@"GSAdEngine is loaded with version %@ and id %@", GSAdEngine.version, [GSAdEngine hashedDeviceIdentifier]);
    
    [self.window makeKeyAndVisible];    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end