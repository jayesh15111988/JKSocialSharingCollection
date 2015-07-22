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
#import <GooglePlus/GooglePlus.h>
#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GPPSignInButton.h>
#import <FBSDKGraphRequestConnection.h>

#import <STTwitter.h>

static NSString* OAUTH_TOKEN_STORE_KEY = @"oauth_token_key";
static NSString* OAUTH_TOKEN_STORE_SECRET = @"oauth_token_secret";
static NSString * const kClientId = @"638736319834-d0cfsnhu923iotabns3d8ptpuqlq0fhc.apps.googleusercontent.com";
static NSString *CONSUMER_KEY = @"XDHVqzmAg23XZ4OAeAna3GosK";
static NSString *CONSUMER_SECRET = @"bB4lKv2qlVbvTmQp6qvzEWwOmUgkFip5f97eSGzpHDZ9O0ZUrw";
static NSString *callback = @"myapp://twitter_access_tokens/";

@interface ViewController ()<FBSDKLoginButtonDelegate, FBSDKSharingDelegate, GPPSignInDelegate, GPPShareDelegate>

@property (strong, nonatomic) FBSDKLoginButton *facebookLoginButton;
@property (strong, nonatomic) FBSDKShareButton *facebookShareButton;
@property (strong, nonatomic) FBSDKAccessToken* facebookAccessToken;
@property (weak, nonatomic) IBOutlet UIButton *facebookSharingButton;
@property (strong, nonatomic) GPPSignInButton *googlePlusSignInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;
@property (weak, nonatomic) IBOutlet UIButton *googlePlusShareButton;
@property (strong, nonatomic) STTwitterAPI* twitter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupFacebookLogin];
    [self setupFacebookSharing];
    [self setupGooglePlusLogin];
    self.googlePlusSignInButton = [[GPPSignInButton alloc] initWithFrame:CGRectMake(80, 500, 200, 44)];
    self.googlePlusSignInButton.style = kGPPSignInButtonStyleWide;
    self.googlePlusSignInButton.colorScheme = kGPPSignInButtonColorSchemeDark;
    [self.googlePlusSignInButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.googlePlusSignInButton setTitle:@"Google Plus" forState:UIControlStateNormal];
    [self.view addSubview:self.googlePlusSignInButton];
    self.googlePlusSignInButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.googlePlusSignInButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.googlePlusSignInButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:200]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-200-[_googlePlusSignInButton(44)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_googlePlusSignInButton)]];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"update_token" object:nil queue:nil usingBlock:^(NSNotification *notification) {
        NSDictionary* tokenInfo = notification.userInfo;
        [self setOAuthToken:tokenInfo[@"oauth_token"] oauthVerifier:tokenInfo[@"oauth_verifier"]];
    }];
    
    self.facebookShareButton = [FBSDKShareButton new];
    self.facebookShareButton.translatesAutoresizingMaskIntoConstraints = NO;
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"http://www.google.com"];
    content.imageURL = [NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/4/40/R_federer.jpg"];
    content.contentTitle = @"Content title is just a faux pass";
    self.facebookShareButton.shareContent = content;
    [self.view addSubview:self.facebookShareButton];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-150-[_facebookShareButton(30)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_facebookShareButton)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.facebookShareButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.facebookShareButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:200]];
}

- (void)performTwitterLogin {
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:OAUTH_TOKEN_STORE_KEY]) {
        self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:CONSUMER_KEY consumerSecret:CONSUMER_SECRET oauthToken:[[NSUserDefaults standardUserDefaults] objectForKey:OAUTH_TOKEN_STORE_KEY] oauthTokenSecret:[[NSUserDefaults standardUserDefaults] objectForKey:OAUTH_TOKEN_STORE_SECRET]];
        
        [self.twitter verifyCredentialsWithUserSuccessBlock:^(NSString *username, NSString *userID) {
            
        } errorBlock:^(NSError *error) {
            
        }];
    } else {
        self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:CONSUMER_KEY
                                                 consumerSecret:CONSUMER_SECRET];
        
        [_twitter postTokenRequest:^(NSURL *url, NSString *oauthToken) {
            NSLog(@"-- url: %@", url);
            NSLog(@"-- oauthToken: %@", oauthToken);
            [[UIApplication sharedApplication] openURL:url];
        } authenticateInsteadOfAuthorize:YES
                        forceLogin:@(NO)
                        screenName:nil
                     oauthCallback:callback
                        errorBlock:^(NSError *error) {
                            NSLog(@"-- error: %@", [error localizedDescription]);
        }];
    }
}

- (void)setOAuthToken:(NSString *)token oauthVerifier:(NSString *)verifier {
    [self.twitter postAccessTokenRequestWithPIN:verifier successBlock:^(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName) {
        
        [self.twitter getAccountVerifyCredentialsWithSuccessBlock:^(NSDictionary *account) {
            
            
        } errorBlock:^(NSError *error) {
            
        }];
        
        
        [[NSUserDefaults standardUserDefaults] setValue:self.twitter.oauthAccessToken forKey:OAUTH_TOKEN_STORE_KEY];
        [[NSUserDefaults standardUserDefaults] setValue:self.twitter.oauthAccessTokenSecret forKey:OAUTH_TOKEN_STORE_SECRET];
        
        /*
         At this point, the user can use the API and you can read his access tokens with:
         
         _twitter.oauthAccessToken;
         _twitter.oauthAccessTokenSecret;
         
         You can store these tokens (in user default, or in keychain) so that the user doesn't need to authenticate again on next launches.
         
         Next time, just instanciate STTwitter with the class method:
         
         +[STTwitterAPI twitterAPIWithOAuthConsumerKey:consumerSecret:oauthToken:oauthTokenSecret:]
         
         Don't forget to call the -[STTwitter verifyCredentialsWithSuccessBlock:errorBlock:] after that.
         */
        
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    }];

}

- (IBAction)twitterLoginButtonPressed:(id)sender {
    [self performTwitterLogin];
}

- (IBAction)postToTwitterPressed:(id)sender {
    [self performTwitterStatusUpdate];
}

- (void)performTwitterStatusUpdate {
    
//    [_twitter postStatusUpdate:@"aasdasdasdasasasd1  d as dasd" inReplyToStatusID:nil latitude:nil longitude:nil placeID:nil displayCoordinates:nil trimUser:nil successBlock:^(NSDictionary *status) {
//        
//    } errorBlock:^(NSError *error) {
//        
//    }];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"rf" ofType:@"jpg"];
    NSURL* fileURL  = [NSURL fileURLWithPath:filePath];
    
    [_twitter postStatusUpdate:@"asasas fsfs df sdfsd  fsf s sdf 4" inReplyToStatusID:nil mediaURL:fileURL placeID:nil latitude:nil longitude:nil uploadProgressBlock:^(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite) {
        
    } successBlock:^(NSDictionary *status) {
        
    } errorBlock:^(NSError *error) {
        
    }];
}

- (void)setupGooglePlusLogin {
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.delegate = self;
    signIn.shouldFetchGooglePlusUser = YES;
    //signIn.shouldFetchGoogleUserEmail = YES;  // Uncomment to get the user's email
    
    // You previously set kClientId in the "Initialize the Google+ client" step
    signIn.clientID = kClientId;
    
    // Uncomment one of these two statements for the scope you chose in the previous step
    signIn.scopes = @[ kGTLAuthScopePlusLogin, @"profile"];  // "https://www.googleapis.com/auth/plus.login" scope
    //signIn.scopes = @[ @"profile" ];            // "profile" scope
    
    // Optional: declare signIn.actions, see "app activities"
    signIn.delegate = self;
    
    GPPSignIn* sharedIns = [GPPSignIn sharedInstance];
    
    if ([sharedIns hasAuthInKeychain]) {
        [[GPPSignIn sharedInstance] trySilentAuthentication];
    } else {
        NSLog(@"Logged in the Google plus for meantime");
    }
    
    self.googlePlusSignInButton.hidden = [sharedIns hasAuthInKeychain];
    self.signOutButton.hidden = !self.googlePlusSignInButton.hidden;
    self.googlePlusShareButton.hidden = self.signOutButton.hidden;
}

#pragma Google Plus share method 

- (IBAction)googlePlusShareButtonPressed:(id)sender {
    if ([[GPPSignIn sharedInstance] hasAuthInKeychain]) {
        [GPPShare sharedInstance].delegate = self;
        id<GPPNativeShareBuilder> shareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
        [shareBuilder setPrefillText:@"This is Airline info app which will allow you to track airline info"];
        //[shareBuilder setCallToActionButtonWithLabel:@"SAVE" URL:[NSURL URLWithString:@"https://www.google.com"] deepLinkID:nil];
        
        [shareBuilder setURLToShare:[NSURL URLWithString:@"https://www.google.com"]];
//        [shareBuilder setCallToActionButtonWithLabel:@"RSVP"
//                                                 URL:[NSURL URLWithString:@"https://www.google.com"]
//                                          deepLinkID:@"rsvp=4815162342"];
        
         #warning You cannot both attach image and set URL to share. Only one of those action is allowed by Google standard.
        
        #warning make sure setURLToShare and setCallToActionButtonWithLabel are called together.
        
        //UIImage* rfImage = [UIImage imageNamed:@"rf.jpg"];
        //[shareBuilder attachImage:rfImage];
        
//        NSString *fileName = @"samplevideo";
//        NSString *extension = @"mov";
//        NSURL *filePath = [[NSBundle mainBundle] URLForResource:fileName withExtension:extension];
//        [shareBuilder attachVideoURL:filePath];
        
        [shareBuilder open];
    } else {
        NSLog(@"Please sign in before continuing");
    }
}

#pragma Delegate method for Google sharing. This callback will be called after sharing is completed. It might or might not be successful.

- (void)finishedSharingWithError:(NSError *)error {
    NSString *text;
    if (!error) {
        text = @"Success";
    } else if (error.code == kGPPErrorShareboxCanceled) {
        text = @"Canceled";
    } else {
        text = [NSString stringWithFormat:@"Error (%@)", [error localizedDescription]];
    }
    NSLog(@"Status: %@", text);
}

#pragma Methods for disconnecting app authorizations from Google+
- (void)disconnect {
    [[GPPSignIn sharedInstance] disconnect];
}

- (void)didDisconnectWithError:(NSError *)error {
    if (error) {
        NSLog(@"Received error %@", error);
    } else {
        // The user is signed out and disconnected.
        // Clean up user data as specified by the Google+ terms.
    }
}

#pragma Google Plus sign in delegate methods.

- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error {
    NSLog(@"Received error %@ and auth object %@",error, auth);
    
    GTLServicePlus* plusService = [[GTLServicePlus alloc] init];
    plusService.retryEnabled = YES;
    [plusService setAuthorizer:auth];
    
    GPPSignIn* sharedIns = [GPPSignIn sharedInstance];
    self.googlePlusSignInButton.hidden = [sharedIns hasAuthInKeychain];
    self.signOutButton.hidden = !self.googlePlusSignInButton.hidden;
    self.googlePlusShareButton.hidden = self.signOutButton.hidden;
    
    if ([sharedIns hasAuthInKeychain]) {
        NSLog(@"User Signed in");
    } else {
        NSLog(@"User Signed out");
    }
    
    GTLQueryPlus *query = [GTLQueryPlus queryForPeopleGetWithUserId:@"me"];
    
    [plusService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                GTLPlusPerson *person,
                                NSError *error) {
                if (error) {
                    GTMLoggerError(@"Error: %@", error);
                } else {
                    NSString *description = [NSString stringWithFormat: @"%@\n%@", person.displayName, person.aboutMe];
                    NSLog(@"Person Description %@", description);
                }
            }];
}

#pragma Google Plus Sign out button
- (IBAction)didTapSignOut:(id)sender {
    [[GPPSignIn sharedInstance] signOut];
    self.googlePlusSignInButton.hidden = NO;
    self.signOutButton.hidden = YES;
    self.googlePlusShareButton.hidden = YES;
}

- (void)setupFacebookSharing {
    
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:@"https://developers.facebook.com"];
    content.contentTitle = @"Sample sharing on Facebook";
    content.contentDescription = @"Sharing Description for sample project";
    content.imageURL = [NSURL URLWithString:@"http://logodesignerblog.com/wp-content/uploads/2009/01/fedex2.gif"];
    
    self.facebookShareButton = [[FBSDKShareButton alloc] init];
    self.facebookShareButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.facebookShareButton.shareContent = content;
    [self.view addSubview:self.facebookShareButton];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_facebookShareButton]-20-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_facebookShareButton)]];
}

- (void)setupFacebookLogin {
    
    self.facebookAccessToken = [FBSDKAccessToken currentAccessToken];
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    
    if (self.facebookAccessToken) {
        NSLog(@"User is already logged in");
        NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
        [parameters setValue:@"id, name, email, gender, languages" forKey:@"fields"];
        
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters] startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            NSLog(@"Fetched User %@", result);
        }];
    } else {
        NSLog(@"User is not logged in the app");
    }
    
    FBSDKProfile* profile = [FBSDKProfile currentProfile];
    NSLog(@"First name %@ and Last name %@", profile.firstName, profile.lastName);
    
    self.facebookLoginButton = [[FBSDKLoginButton alloc] init];
    self.facebookLoginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    self.facebookLoginButton.delegate = self;
    id topLayout = self.topLayoutGuide;
    self.facebookLoginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.facebookLoginButton];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_facebookLoginButton]-20-|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(_facebookLoginButton)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayout]-20-[_facebookLoginButton(44)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(topLayout, _facebookLoginButton)]];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:FBSDKAccessTokenDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSLog(@"User Login status changed");
        self.facebookAccessToken = [FBSDKAccessToken currentAccessToken];
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

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    
}

- (IBAction)facebookSharingButtonPressed:(id)sender {
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

- (IBAction)postTapped:(id)sender{
    [self performTwitterStatusUpdate];
}

// Redundant Methods from the app.
- (IBAction)manualLoginFacebookButtonPressed:(id)sender {
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    
    if (!self.facebookAccessToken) {
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

@end
