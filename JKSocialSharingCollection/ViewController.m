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

#import <OAuthConsumer/OAuthConsumer.h>
#import <OAToken.h>
#import <OAConsumer.h>
#import <TwitterKit/TWTRComposer.h>
#import <TwitterKit/TWTRLogInButton.h>
#import <Twitter/Twitter.h>
#import <TwitterKit/Twitter.h>
#import <TwitterKit/TWTRTweetView.h>
#import <STTwitter.h>

static NSString * const kClientId = @"638736319834-d0cfsnhu923iotabns3d8ptpuqlq0fhc.apps.googleusercontent.com";

static NSString *client_id = @"XDHVqzmAg23XZ4OAeAna3GosK";
static NSString *secret = @"bB4lKv2qlVbvTmQp6qvzEWwOmUgkFip5f97eSGzpHDZ9O0ZUrw";
static NSString *callback = @"http://codegerms.com/callback";

@interface ViewController ()<FBSDKLoginButtonDelegate, FBSDKSharingDelegate, GPPSignInDelegate, GPPShareDelegate>

@property (strong, nonatomic) FBSDKLoginButton *loginButton;
@property (strong, nonatomic) FBSDKAccessToken* accessToken1;
@property (weak, nonatomic) IBOutlet UIButton *manualLoginButton;
@property (strong, nonatomic) FBSDKShareButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *manualSharingButton;
@property (strong, nonatomic) GPPSignInButton *googlePlusSignInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;
@property (weak, nonatomic) IBOutlet UIButton *googlePlusShareButton;

@property (nonatomic,strong) OAConsumer* consumer;
@property (nonatomic,strong) OAToken* requestToken;
@property (nonatomic,strong) OAToken* accessToken;
@property (nonatomic, retain) IBOutlet UIWebView *webview;


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
    [self setupOAuthRequest];
}

- (void)setupOAuthRequest {
    self.consumer = [[OAConsumer alloc] initWithKey:client_id secret:secret];
    NSURL* requestTokenUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    OAMutableURLRequest* requestTokenRequest = [[OAMutableURLRequest alloc] initWithURL:requestTokenUrl
                                                                               consumer:self.consumer
                                                                                  token:nil
                                                                                  realm:nil
                                                                      signatureProvider:nil];
    OARequestParameter* callbackParam = [[OARequestParameter alloc] initWithName:@"oauth_callback" value:callback];
    [requestTokenRequest setHTTPMethod:@"POST"];
    [requestTokenRequest setParameters:[NSArray arrayWithObject:callbackParam]];
    OADataFetcher* dataFetcher = [[OADataFetcher alloc] init];
    [dataFetcher fetchDataWithRequest:requestTokenRequest
                             delegate:self
                    didFinishSelector:@selector(didReceiveRequestToken:data:)
                      didFailSelector:@selector(didFailOAuth:error:)];
}

#pragma Twitter OAuth delegate methods after request
- (void)didReceiveRequestToken:(OAServiceTicket*)ticket data:(NSData*)data {
    NSString* httpBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:httpBody];
    
    NSURL* authorizeUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];
    OAMutableURLRequest* authorizeRequest = [[OAMutableURLRequest alloc] initWithURL:authorizeUrl
                                                                            consumer:nil
                                                                               token:nil
                                                                               realm:nil
                                                                   signatureProvider:nil];
    NSString* oauthToken = self.requestToken.key;
    OARequestParameter* oauthTokenParam = [[OARequestParameter alloc] initWithName:@"oauth_token" value:oauthToken];
    [authorizeRequest setParameters:[NSArray arrayWithObject:oauthTokenParam]];
    
    [self.webview loadRequest:authorizeRequest];
}

#pragma WebView delegate methods
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    //  [indicator startAnimating];
    NSString *temp = [NSString stringWithFormat:@"%@",request];
    //  BOOL result = [[temp lowercaseString] hasPrefix:@"http://codegerms.com/callback"];
    // if (result) {
    NSRange textRange = [[temp lowercaseString] rangeOfString:[@"http://codegerms.com/callback" lowercaseString]];
    
    if(textRange.location != NSNotFound){
        
        // Extract oauth_verifier from URL query
        NSString* verifier = nil;
        NSArray* urlParams = [[[request URL] query] componentsSeparatedByString:@"&"];
        for (NSString* param in urlParams) {
            NSArray* keyValue = [param componentsSeparatedByString:@"="];
            NSString* key = [keyValue objectAtIndex:0];
            if ([key isEqualToString:@"oauth_verifier"]) {
                verifier = [keyValue objectAtIndex:1];
                break;
            }
        }
        
        if (verifier) {
            NSURL* accessTokenUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
            OAMutableURLRequest* accessTokenRequest = [[OAMutableURLRequest alloc] initWithURL:accessTokenUrl consumer:self.consumer token:self.requestToken realm:nil signatureProvider:nil];
            OARequestParameter* verifierParam = [[OARequestParameter alloc] initWithName:@"oauth_verifier" value:verifier];
            [accessTokenRequest setHTTPMethod:@"POST"];
            [accessTokenRequest setParameters:[NSArray arrayWithObject:verifierParam]];
            OADataFetcher* dataFetcher = [[OADataFetcher alloc] init];
            [dataFetcher fetchDataWithRequest:accessTokenRequest
                                     delegate:self
                            didFinishSelector:@selector(didReceiveAccessToken:data:)
                              didFailSelector:@selector(didFailOAuth:error:)];
        } else {
            // ERROR!
        }
        
        [webView removeFromSuperview];
        
        return NO;
    }
    
    return YES;
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    // ERROR!
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    // [indicator stopAnimating];
}

- (void)didReceiveAccessToken:(OAServiceTicket*)ticket data:(NSData*)data {
    NSString* httpBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:httpBody];
    // WebServiceSocket *connection = [[WebServiceSocket alloc] init];
    //  connection.delegate = self;
    NSString *pdata = [NSString stringWithFormat:@"type=2&token=%@&secret=%@&login=%@", self.accessToken.key, self.accessToken.secret, @"1"];
    NSLog(@"Access token key %@ and Secret %@", self.accessToken.key, self.accessToken.secret);
    
    //codegerms.com
    
    if (self.accessToken) {
        NSURL* userdatarequestu = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
        OAMutableURLRequest* requestTokenRequest = [[OAMutableURLRequest alloc] initWithURL:userdatarequestu
                                                                                   consumer:self.consumer
                                                                                      token:self.accessToken
                                                                                      realm:nil
                                                                          signatureProvider:nil];
        
        [requestTokenRequest setHTTPMethod:@"GET"];
        OADataFetcher* dataFetcher = [[OADataFetcher alloc] init];
        [dataFetcher fetchDataWithRequest:requestTokenRequest
                                 delegate:self
                        didFinishSelector:@selector(didReceiveuserdata:data:)
                          didFailSelector:@selector(didFailOdatah:error:)];    } else {
            // ERROR!
        }
    
}

- (void)didReceiveuserdata:(OAServiceTicket*)ticket data:(NSData*)data {
    NSString* httpBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
}

- (void)didFailOAuth:(OAServiceTicket*)ticket error:(NSError*)error {
    // ERROR!
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
                    // Retrieve the display name and "about me" text
                
                    NSString *description = [NSString stringWithFormat:
                                             @"%@\n%@", person.displayName,
                                             person.aboutMe];
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
    
    self.accessToken1 = [FBSDKAccessToken currentAccessToken];
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    
    
    if (self.accessToken1) {
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
        self.accessToken1 = [FBSDKAccessToken currentAccessToken];
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
    
    if (!self.accessToken1) {
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

- (IBAction)postTapped:(id)sender{
    //OAToken *token = [[OAToken alloc] initWithKey:client_id secret:secret]; //Set user Oauth access token and secrate key
    
    //OAConsumer *consumer = [[OAConsumer alloc] initWithKey:@"36319586-tFS9rtvlJFsPVhN9TLjenbiUQlEDC7H7fOsD5fE8d" secret:@"zXo7icqyYxvna8mL4AuQZ62QELIPN44wrmNzrV9iPNZbb"]; // Application cosumer token and secrate key
    
//    NSLog(@"Access token key %@ and Secret %@", self.accessToken.key, self.accessToken.secret);
//    
//    // Url for upload pictures
//    NSURL *finalURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
//                       
//                       OAMutableURLRequest *theRequest = [[OAMutableURLRequest alloc] initWithURL:finalURL
//                                                                                         consumer:self.consumer
//                                                                                            token:self.accessToken
//                                                                                            realm: nil
//                                                                                signatureProvider:nil];
//	
//    //[theRequest setParameters:@[[OARequestParameter requestParameter:@"status" value:@"asd asd as d a"]]];
//    
//                       [theRequest setHTTPMethod:@"POST"];
//                       [theRequest setTimeoutInterval:120];
//                       [theRequest setHTTPShouldHandleCookies:NO];
//                       
//                       // Set headers for client information, for tracking purposes at Twitter.(This is optional)
//                       [theRequest setValue:@"TestIphone" forHTTPHeaderField:@"X-Twitter-Client"];
//                       [theRequest setValue:@"1.0" forHTTPHeaderField:@"X-Twitter-Client-Version"];
//                       //[theRequest setValue:@"http://www.TestIphone.com/" forHTTPHeaderField:@"X-Twitter-Client-URL"];
//                       
//                       NSString *boundary = @"--Hi all, First Share"; // example taken and implemented.
//                       NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
//                       [theRequest setValue:contentType forHTTPHeaderField:@"content-type"];
//                       
//                       NSMutableData *body = [NSMutableData data];
//                       
//                       [body appendData:[[NSString stringWithFormat:@"--%@\r\n\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//    
//    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"status\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//    [body appendData:[[NSString stringWithFormat:@"%@",@"s dsa d asd a d 2324234"] dataUsingEncoding:NSUTF8StringEncoding]];
//    
//                       [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//                       [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//                       [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media[]\"; filename=\"rf.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//                       [body appendData:[[NSString stringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//                       [body appendData:[NSData dataWithData:UIImageJPEGRepresentation([UIImage imageNamed:@"rf.jpg"], 0.5)]];
//                       [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
//                       [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
//
//    
//                       [theRequest prepare];
//                       
//                       NSString *oAuthHeader = [theRequest valueForHTTPHeaderField:@"Authorization"];
//                       [theRequest setHTTPBody:body];
//    
//    
//    
//                       NSHTTPURLResponse *response = nil;
//                       NSError *error = nil;
//                       
//                       NSData *responseData = [NSURLConnection sendSynchronousRequest:theRequest
//                                                                    returningResponse:&response                            
//                                                                                error:&error];
//                       NSString *responseString = [[NSString alloc] initWithData:responseData                                
//                                                                        encoding:NSUTF8StringEncoding];
//    
    
    STTwitterAPI *twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:self.consumer.key consumerSecret:self.consumer.secret oauthToken:self.requestToken.key oauthTokenSecret:self.requestToken.secret];
    
    [twitter postStatusUpdate:@"test"
            inReplyToStatusID:nil
                     latitude:nil
                    longitude:nil
                      placeID:nil
           displayCoordinates:nil
                     trimUser:nil
                 successBlock:^(NSDictionary *status) {
                     // ...
                 } errorBlock:^(NSError *error) {
                     // ...
                 }];
}

@end
