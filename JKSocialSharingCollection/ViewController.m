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
#import <FBSDKShareButton.h>
#import <FBSDKShareLinkContent.h>
#import <FBSDKShareDialog.h>
#import <Google/SignIn.h>
#import <FBSDKGraphRequestConnection.h>

static NSString * const kClientId = @"638736319834-d0cfsnhu923iotabns3d8ptpuqlq0fhc.apps.googleusercontent.com";

@interface ViewController ()<FBSDKLoginButtonDelegate, FBSDKSharingDelegate, GIDSignInUIDelegate>

@property (strong, nonatomic) FBSDKLoginButton *loginButton;
@property (strong, nonatomic) FBSDKAccessToken* accessToken;
@property (weak, nonatomic) IBOutlet UIButton *manualLoginButton;
@property (strong, nonatomic) FBSDKShareButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *manualSharingButton;
@property(weak, nonatomic) IBOutlet GIDSignInButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupFacebookLogin];
    [self setupFacebookSharing];
    [self setupGooglePlusLogin];
}

- (void)setupGooglePlusLogin {
    [GIDSignIn sharedInstance].uiDelegate = self;
    [[GIDSignIn sharedInstance] signInSilently];
    
    GIDSignIn* sharedIns = [GIDSignIn sharedInstance];
    self.signInButton.hidden = [sharedIns hasAuthInKeychain];
    self.signOutButton.hidden = !self.signInButton.hidden;
    
    if ([sharedIns hasAuthInKeychain]) {
        NSLog(@"User Signed in");
    } else {
        NSLog(@"User Signed out");
    }
}

#pragma Methods for disconnecting app authorizations from Google+
- (void)disconnect {
    [[GIDSignIn sharedInstance] disconnect];
}

- (void)didDisconnectWithError:(NSError *)error {
    if (error) {
        NSLog(@"Received error %@", error);
    } else {
        // The user is signed out and disconnected.
        // Clean up user data as specified by the Google+ terms.
    }
}

#pragma Google Plus Sign out button
- (IBAction)didTapSignOut:(id)sender {
    [[GIDSignIn sharedInstance] signOut];
}

- (void)setupFacebookSharing {
    
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://developers.facebook.com"];
    content.contentTitle = @"Sample sharing on Facebook";
    content.contentDescription = @"Sharing Description for sample project";
    content.imageURL = [NSURL URLWithString:@"http://logodesignerblog.com/wp-content/uploads/2009/01/fedex2.gif"];
    
    self.shareButton = [[FBSDKShareButton alloc] init];
    self.shareButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.shareButton.shareContent = content;
    [self.view addSubview:self.shareButton];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_shareButton]-20-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_shareButton)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_manualLoginButton]-20-[_shareButton(44)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_manualLoginButton, _shareButton)]];
}

- (void)setupFacebookLogin {
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

- (IBAction)manualSharingButtonPressed:(id)sender {
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://developers.facebook.com"];
    content.contentTitle = @"Sample sharing on Facebook";
    content.contentDescription = @"Sharing Description for sample project";
    content.imageURL = [NSURL URLWithString:@"http://logodesignerblog.com/wp-content/uploads/2009/01/fedex2.gif"];

    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:self];
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
    
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    
}

@end
