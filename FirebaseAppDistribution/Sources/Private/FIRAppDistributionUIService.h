// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <AuthenticationServices/AuthenticationServices.h>
#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>
#import <UIKit/UIKit.h>
#import "FIRAppDistribution+Private.h"

NS_ASSUME_NONNULL_BEGIN
/// An instance of this class provides UI elements required for the App Distribution tester
/// authentication flow as an AppDelegate interceptor.
@interface FIRAppDistributionUIService : NSObject <UIApplicationDelegate,
                                                   ASWebAuthenticationPresentationContextProviding,
                                                   SFSafariViewControllerDelegate>

/// Returns the FIRAppDistributionAppDelegatorInterceptor singleton.
/// Always register just this singleton as the app delegate interceptor. This instance is
/// retained. The App Delegate Swizzler only retains weak references and so this is needed.
+ (instancetype)sharedInstance;

typedef void (^AppDistributionRegistrationFlowCompletion)(NSError *_Nullable error);

@property(nullable, nonatomic) UIViewController *safariHostingViewController;

@property(nullable, nonatomic) UIWindow *window;

@property(nullable, nonatomic) AppDistributionRegistrationFlowCompletion registrationFlowCompletion;

- (void)appDistributionRegistrationFlow:(NSURL *)URL
                         withCompletion:(AppDistributionRegistrationFlowCompletion)completion;

- (void)showUIAlert:(UIAlertController *)alertController;

- (void)initializeUIState;

- (void)resetUIState;
@end

NS_ASSUME_NONNULL_END
