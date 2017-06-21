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

#import <Foundation/Foundation.h>


#import "FIRAuthRPCRequest.h"
#import "FIRIdentityToolkitRequest.h"

@class FIRActionCodeSettings;

NS_ASSUME_NONNULL_BEGIN

/** @enum FIRGetOOBConfirmationCodeRequestType
    @brief Types of OOB Confirmation Code requests.
 */
typedef NS_ENUM(NSInteger, FIRGetOOBConfirmationCodeRequestType) {
  /** @var FIRGetOOBConfirmationCodeRequestTypePasswordReset
      @brief Requests a password reset code.
   */
  FIRGetOOBConfirmationCodeRequestTypePasswordReset,

  /** @var FIRGetOOBConfirmationCodeRequestTypeVerifyEmail
      @brief Requests an email verification code.
   */
  FIRGetOOBConfirmationCodeRequestTypeVerifyEmail,
};

/** @enum FIRGetOOBConfirmationCodeRequest
    @brief Represents the parameters for the getOOBConfirmationCode endpoint.
 */
@interface FIRGetOOBConfirmationCodeRequest : FIRIdentityToolkitRequest <FIRAuthRPCRequest>

/** @property requestType
    @brief The types of OOB Confirmation Code to request.
 */
@property(nonatomic, assign, readonly) FIRGetOOBConfirmationCodeRequestType requestType;

/** @property email
    @brief The email of the user.
    @remarks For password reset.
 */
@property(nonatomic, copy, nullable, readonly) NSString *email;

/** @property accessToken
    @brief The STS Access Token of the authenticated user.
    @remarks For email change.
 */
@property(nonatomic, copy, nullable, readonly) NSString *accessToken;

/** @property continueURL
    @brief This URL represents the state/Continue URL in the form of a universal link.
 */
@property(nonatomic, copy, nullable, readonly) NSString *continueURL;

/** @property iOSBundleID
    @brief The iOS bundle Identifier, if available.
 */
@property(nonatomic, copy, nullable, readonly) NSString *iOSBundleID;

/** @property iOSAppStoreID
    @brief The iOS app store identifier, if available.
 */
@property(nonatomic, copy, nullable, readonly) NSString *iOSAppStoreID;

/** @property androidPackageName
    @brief The Android package name, if available.
 */
@property(nonatomic, copy, nullable, readonly) NSString *androidPackageName;

/** @property androidMinimumVersion
    @brief The minimum Android version supported, if available.
 */
@property(nonatomic, copy, nullable, readonly) NSString *androidMinimumVersion;

/** @property androidInstallIfNotAvailable
    @brief Indicates whether or not the Android app should be installed if not already available.
 */
@property(nonatomic, assign, readonly) BOOL androidInstallApp;

/** @property handleCodeInApp
    @brief Indicates whether or not the action code link will open the app directly or after being
        redirected from a Firebase owned web widget.
 */
@property(assign, nonatomic) BOOL handleCodeInApp;

/** @fn passwordResetRequestWithEmail:APIKey:
    @brief Creates a password reset request.
    @param email The user's email address.
    @param APIKey The client's API Key.
    @return A password reset request.
 */
+ (nullable FIRGetOOBConfirmationCodeRequest *)
    passwordResetRequestWithEmail:(NSString *)email
               actionCodeSettings:(nullable FIRActionCodeSettings *)actionCodeSettings
                           APIKey:(NSString *)APIKey;

/** @fn verifyEmailRequestWithAccessToken:APIKey:
    @brief Creates a password reset request.
    @param accessToken The user's STS Access Token.
    @param APIKey The client's API Key.
    @return A password reset request.
 */
+ (nullable FIRGetOOBConfirmationCodeRequest *)
    verifyEmailRequestWithAccessToken:(NSString *)accessToken
                   actionCodeSettings:(nullable FIRActionCodeSettings *)actionCodeSettings
                               APIKey:(NSString *)APIKey;

/** @fn init
    @brief Please use a factory method.
 */
- (nullable instancetype)initWithEndpoint:(NSString *)endpoint
                                   APIKey:(NSString *)APIKey NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
