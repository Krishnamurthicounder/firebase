/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SettingsViewController.h"

#import <objc/runtime.h>

#import "FIRApp.h"
#import "FIROptions.h"
#import "FirebaseAuth.h"
#import "StaticContentTableViewManager.h"

#if INTERNAL_GOOGLE3_BUILD
#import "googlemac/iPhone/InstanceID/Firebase/Lib/Source/FIRInstanceID+Internal.h"
#else
@interface FIRInstanceID : NSObject
+ (void)notifyTokenRefresh;
@end
#endif

/** @var kIdentityToolkitRequestClassName
    @brief The class name of Identity Toolkit requests.
 */
static NSString *const kIdentityToolkitRequestClassName = @"FIRIdentityToolkitRequest";

/** @var kSecureTokenRequestClassName
    @brief The class name of Secure Token Service requests.
 */
static NSString *const kSecureTokenRequestClassName = @"FIRSecureTokenRequest";

/** @var kIdentityToolkitSandboxHost
    @brief The host of Identity Toolkit sandbox server.
 */
static NSString *const kIdentityToolkitSandboxHost = @"www-googleapis-staging.sandbox.google.com";

/** @var kSecureTokenSandboxHost
    @brief The host of Secure Token Service sandbox server.
 */
static NSString *const kSecureTokenSandboxHost = @"staging-securetoken.sandbox.googleapis.com";

/** @var kGoogleServiceInfoPlists
    @brief a C-array of plist file base names of Google service info to initialize FIRApp.
 */
static NSString *const kGoogleServiceInfoPlists[] = {
  @"GoogleService-Info",
  @"GoogleService-Info_multi"
};

/** @var gAPIEndpoints
    @brief List of API Hosts by request class name.
 */
static NSDictionary<NSString *, NSArray<NSString *> *> *gAPIHosts;

/** @var gFirebaseAppOptions
    @brief List of FIROptions.
 */
static NSArray<FIROptions *> *gFirebaseAppOptions;

/** @protocol RequestClass
    @brief A de-facto protocol followed by request class objects to access its API host.
 */
@protocol RequestClass <NSObject>
- (NSString *)host;
- (void)setHost:(NSString *)host;
@end

/** @category FIROptions(ProjectID)
    @brief A category to FIROption to add the project ID property.
 */
@interface FIROptions (ProjectID)

/** @property projectID
    @brief The Firebase project ID.
 */
@property(nonatomic, copy) NSString *projectID;

@end

@implementation FIROptions (ProjectID)

- (NSString *)projectID {
  return objc_getAssociatedObject(self, @selector(projectID));
}

- (void)setProjectID:(NSString *)projectID {
  objc_setAssociatedObject(self, @selector(projectID), projectID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

/** @fn versionString
    @brief Constructs a version string to display.
    @param string The version in string form.
    @param number The version in number form.
 */
static NSString *versionString(const unsigned char *string, const double number) {
  return [NSString stringWithFormat:@"\"%s\" (%g)", string, number];
}

/** @fn requestHost
    @brief Retrieves the API host for the request class.
    @param requestClassName The name of the request class.
 */
static NSString *APIHost(NSString *requestClassName) {
  return [(id<RequestClass>)NSClassFromString(requestClassName) host];
}

@implementation SettingsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setUpAPIHosts];
  [self setUpFirebaseAppOptions];
  [self loadTableView];
}

- (IBAction)done:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setUpAPIHosts {
  if (gAPIHosts) {
    return;
  }
  gAPIHosts = @{
    kIdentityToolkitRequestClassName : @[
      APIHost(kIdentityToolkitRequestClassName),
      kIdentityToolkitSandboxHost,
    ],
    kSecureTokenRequestClassName : @[
      APIHost(kSecureTokenRequestClassName),
      kSecureTokenSandboxHost,
    ],
  };
}

- (void)setUpFirebaseAppOptions {
  if (gFirebaseAppOptions) {
    return;
  }
  int numberOfOptions = sizeof(kGoogleServiceInfoPlists) / sizeof(*kGoogleServiceInfoPlists);
  NSMutableArray *appOptions = [[NSMutableArray alloc] initWithCapacity:numberOfOptions];
  for (int i = 0; i < numberOfOptions; i++) {
    NSString *plistFileName = kGoogleServiceInfoPlists[i];
    NSString *plistFilePath = [[NSBundle mainBundle] pathForResource:plistFileName
                                                              ofType:@"plist"];
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithContentsOfFile:plistFilePath];
    FIROptions *options = [[FIROptions alloc]
        initWithGoogleAppID:optionsDictionary[@"GOOGLE_APP_ID"]
                   bundleID:optionsDictionary[@"BUNDLE_ID"]
                GCMSenderID:optionsDictionary[@"GCM_SENDER_ID"]
                     APIKey:optionsDictionary[@"API_KEY"]
                   clientID:optionsDictionary[@"CLIENT_ID"]
                 trackingID:optionsDictionary[@"TRACKING_ID"]
            androidClientID:optionsDictionary[@"ANDROID_CLIENT_ID"]
                databaseURL:optionsDictionary[@"DATABASE_URL"]
              storageBucket:optionsDictionary[@"STORAGE_BUCKET"]
          deepLinkURLScheme:nil];
    options.projectID = optionsDictionary[@"PROJECT_ID"];
    [appOptions addObject:options];
  }
  gFirebaseAppOptions = [appOptions copy];
}

- (void)loadTableView {
  __weak typeof(self) weakSelf = self;
  _tableViewManager.contents = [StaticContentTableViewContent contentWithSections:@[
    [StaticContentTableViewSection sectionWithTitle:@"Versions" cells:@[
      [StaticContentTableViewCell cellWithTitle:@"FirebaseAuth"
                                          value:versionString(
          FirebaseAuthVersionString, FirebaseAuthVersionNumber)],
    ]],
    [StaticContentTableViewSection sectionWithTitle:@"Client Identity" cells:@[
      [StaticContentTableViewCell cellWithTitle:@"Project"
                                          value:[self currentProjectID]
                                         action:^{
        [weakSelf toggleClientProject];
      }],
    ]],
    [StaticContentTableViewSection sectionWithTitle:@"API Hosts" cells:@[
      [StaticContentTableViewCell cellWithTitle:@"Identity Toolkit"
                                          value:APIHost(kIdentityToolkitRequestClassName)
                                         action:^{
        [weakSelf toggleAPIHostWithRequestClassName:kIdentityToolkitRequestClassName];
      }],
      [StaticContentTableViewCell cellWithTitle:@"Secure Token"
                                          value:APIHost(kSecureTokenRequestClassName)
                                         action:^{
        [weakSelf toggleAPIHostWithRequestClassName:kSecureTokenRequestClassName];
      }],
    ]],
  ]];
}

/** @fn toggleAPIHostWithRequestClassName:
    @brief Toggles the host name of the server that handles RPCs.
    @param requestClassName The name of the RPC request class.
 */
- (void)toggleAPIHostWithRequestClassName:(NSString *)requestClassName {
  NSString *currentHost = APIHost(requestClassName);
  NSArray<NSString *> *allHosts = gAPIHosts[requestClassName];
  NSString *newHost = allHosts[([allHosts indexOfObject:currentHost] + 1) % allHosts.count];
  [(id<RequestClass>)NSClassFromString(requestClassName) setHost:newHost];
  [self loadTableView];
}

/** @fn currentProjectID
    @brief Returns the the current Firebase project ID.
 */
- (NSString *)currentProjectID {
  NSString *APIKey = [FIRApp defaultApp].options.APIKey;
  for (FIROptions *options in gFirebaseAppOptions) {
    if ([options.APIKey isEqualToString:APIKey]) {
      return options.projectID;
    }
  }
  return nil;
}

/** @fn toggleClientProject
    @brief Toggles the Firebase/Google project this client presents by recreating the default
        FIRApp instance with different options.
 */
- (void)toggleClientProject {
  NSString *APIKey = [FIRApp defaultApp].options.APIKey;
  for (NSUInteger i = 0 ; i < gFirebaseAppOptions.count; i++) {
    FIROptions *options = gFirebaseAppOptions[i];
    if ([options.APIKey isEqualToString:APIKey]) {
      __weak typeof(self) weakSelf = self;
      [[FIRApp defaultApp] deleteApp:^(BOOL success) {
        if (success) {
          [FIRInstanceID notifyTokenRefresh];  // b/28967043
          dispatch_async(dispatch_get_main_queue(), ^() {
            FIROptions *options = gFirebaseAppOptions[(i + 1) % gFirebaseAppOptions.count];
            [FIRApp configureWithOptions:options];
            [weakSelf loadTableView];
          });
        }
      }];
      return;
    }
  }
}

@end
