//
//  ViewController.m
//  JKSocialSharingCollection
//
//  Created by Jayesh Kawli Backup on 7/18/15.
//  Copyright (c) 2015 Jayesh Kawli Backup. All rights reserved.
//

#import "ViewController.h"
#import <FBSDKCoreKit.h>
#import <FBSDKLoginKit.h>
#import <FBSDKGraphRequestConnection.h>

@interface ViewController ()<FBSDKLoginButtonDelegate>

@property (strong, nonatomic) FBSDKLoginButton *loginButton;
@property (strong, nonatomic) FBSDKAccessToken* accessToken;
@property (weak, nonatomic) IBOutlet UIButton *manualLoginButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([FBSDKAccessToken currentAccessToken]) {
        // User is logged in, do work such as go to next view controller.
    }
    
    self.accessToken = [FBSDKAccessToken currentAccessToken];
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    
    
    if (self.accessToken) {
        [self.manualLoginButton setTitle:@"Logout" forState:UIControlStateNormal];
        NSLog(@"User is already logged in");
        NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
        [parameters setValue:@"id, name, email, gender, languages" forKey:@"fields"];
    
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            NSLog(@"Fetched User %@", result);
        }];
    } else {
        [self.manualLoginButton setTitle:@"Login" forState:UIControlStateNormal];
        NSLog(@"User is not logged in the app");
    }
    
    FBSDKProfile* profile = [FBSDKProfile currentProfile];
    NSLog(@"First name %@ and Last name %@", profile.firstName, profile.lastName);
    
    self.loginButton = [[FBSDKLoginButton alloc] init];
    self.loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    self.loginButton.delegate = self;
    id topLayout = self.topLayoutGuide;
    self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.loginButton];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_loginButton]-20-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_loginButton)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayout]-20-[_loginButton(44)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(topLayout, _loginButton)]];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:FBSDKAccessTokenDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"User Login status changed");
        self.accessToken = [FBSDKAccessToken currentAccessToken];
    }];
}

- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    if (error) {
        // Process error
    } else if (result.isCancelled) {
        // Handle cancellations
        NSLog(@"Permission grant is cancelled to the app");
    } else {
        // If you ask for multiple permissions at once, you
        // should check if specific permissions missing
        if ([result.grantedPermissions containsObject:@"email"]) {
            NSLog(@"Email Permission grapnted");
        }
        if ([result.grantedPermissions containsObject:@"public_profile"]) {
            NSLog(@"Public Profile granted");
        }
        if ([result.grantedPermissions containsObject:@"user_friends"]) {
            NSLog(@"User Friends granted");
        }
        
        if (!result.grantedPermissions.count) {
            NSLog(@"No permission granted to the app");
        }
    }
}

- (IBAction)manualLoginFacebookButtonPressed:(id)sender {
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    
    if (!self.accessToken) {
        [login logInWithReadPermissions:@[@"public_profile", @"email", @"user_friends"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (error) {
                // Process error
            } else if (result.isCancelled) {
                // Handle cancellations
            } else {
                // If you ask for multiple permissions at once, you
                // should check if specific permissions missing
                if ([result.grantedPermissions containsObject:@"email"]) {
                    NSLog(@"Email Permission grapnted");
                }
                if ([result.grantedPermissions containsObject:@"public_profile"]) {
                    NSLog(@"Public Profile granted");
                }
                if ([result.grantedPermissions containsObject:@"user_friends"]) {
                    NSLog(@"User Friends granted");
                }
                
                if (!result.grantedPermissions.count) {
                    NSLog(@"No permission granted to the app");
                }
            }
        }];
    } else {
        [login logOut];
    }
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    
}

@end
