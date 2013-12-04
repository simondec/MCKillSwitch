//
//  AppDelegate.m
//  MCKillSwitchExample
//
//  Created by Stéphanie Paquet on 2013-05-10.
//  Copyright (c) 2013 Mirego. All rights reserved.
//

#import "AppDelegate.h"
#import "MCKillSwitch.h"
#import "MCKillSwitchExampleRootViewController.h"

static BOOL const TestDefaultKillSwitch = YES;
static BOOL const TestCustomKillSwitch = NO;
static BOOL const TestStaticJSONFileKillSwitch = NO;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[MCKillSwitchExampleRootViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    if (TestDefaultKillSwitch) {
        [MCKillSwitch configureDefaultKillSwitchWithAPIKey:@"f146acb80b791e17a201e845137e9fc49b55bce02ab4e1e9e0c33216fc56f9fe"];
    }
    if (TestCustomKillSwitch) {
        [MCKillSwitch configureKillSwitchWithCustomURL:[NSURL URLWithString:@"__YOUR_BASE_URL__"] parameters:nil];
    }
    if (TestStaticJSONFileKillSwitch) {
        [MCKillSwitch configureStaticJSONFileKillSwitchWithURL:[NSURL URLWithString:@"http://lefrancois-test.s3.amazonaws.com/1.0.0.json"]];
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
