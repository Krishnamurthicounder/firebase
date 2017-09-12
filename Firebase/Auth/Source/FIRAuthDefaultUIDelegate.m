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

#import "FIRAuthDefaultUIDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FIRAuthDefaultUIDelegate {
  /** @var _viewController
      @brief The presenting view controller.
   */
  UIViewController *_viewController;
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
  self = [super init];
  if (self) {
    _viewController = viewController;
  }
  return self;
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent
                     animated:(BOOL)flag
                   completion:(nullable void (^)(void))completion {
  [_viewController presentViewController:viewControllerToPresent
                                animated:flag
                              completion:completion];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(nullable void (^)(void))completion {
  [_viewController dismissViewControllerAnimated:flag completion:completion];
}

+ (id<FIRAuthUIDelegate>)defaultUIDelegate {
  UIViewController *topViewController =
      [UIApplication sharedApplication].keyWindow.rootViewController;
  while (true){
    if (topViewController.presentedViewController) {
      topViewController = topViewController.presentedViewController;
    } else if ([topViewController isKindOfClass:[UINavigationController class]]) {
      UINavigationController *nav = (UINavigationController *)topViewController;
      topViewController = nav.topViewController;
    } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
      UITabBarController *tab = (UITabBarController *)topViewController;
      topViewController = tab.selectedViewController;
    } else {
      break;
    }
  }
  return [[FIRAuthDefaultUIDelegate alloc] initWithViewController:topViewController];
}

@end

NS_ASSUME_NONNULL_END
