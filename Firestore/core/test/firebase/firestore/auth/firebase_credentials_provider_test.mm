/*
 * Copyright 2018 Google
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

#include "Firestore/core/src/firebase/firestore/auth/firebase_credentials_provider_apple.h"

#import <FirebaseAuthInterop/FIRAuthInterop.h>
#import <FirebaseCore/FIRApp.h>
#import <FirebaseCore/FIRAppInternal.h>
#import <FirebaseCore/FIRComponent.h>
#import <FirebaseCore/FIRComponentContainerInternal.h>
#import <FirebaseCore/FIROptionsInternal.h>

#include "Firestore/core/src/firebase/firestore/util/statusor.h"
#include "Firestore/core/src/firebase/firestore/util/string_apple.h"
#include "Firestore/core/test/firebase/firestore/testutil/app_testing.h"

#include "gtest/gtest.h"

/// Testing interface for ComponentContainer (required for Auth).
@interface FIRComponentContainer ()
// The extra long type information in components causes clang-format to wrap in
// a weird way, turn for the declaration.
// clang-format off
/// Exposed for testing, create a container directly with components and a dummy
/// app.
- (instancetype)initWithApp:(FIRApp*)app
                 components:(NSDictionary<NSString*,
                             FIRComponentCreationBlock>*)components;
// clang-format on
@end

/// A fake class to handle Auth interaction.
@interface FSTAuthFake : NSObject<FIRAuthInterop>
@property(nonatomic, nullable, strong, readonly) NSString* token;
@property(nonatomic, nullable, strong, readonly) NSString* uid;
@property(nonatomic, readonly) BOOL forceRefreshTriggered;
- (instancetype)initWithToken:(nullable NSString*)token
                          uid:(nullable NSString*)uid NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@implementation FSTAuthFake

- (instancetype)initWithToken:(nullable NSString*)token
                          uid:(nullable NSString*)uid {
  self = [super init];
  if (self) {
    _token = [token copy];
    _uid = [uid copy];
    _forceRefreshTriggered = NO;
  }
  return self;
}

// FIRAuthInterop conformance.

- (nullable NSString*)getUserID {
  return self.uid;
}

- (void)getTokenForcingRefresh:(BOOL)forceRefresh
                  withCallback:(nonnull FIRTokenCallback)callback {
  _forceRefreshTriggered = forceRefresh;
  callback(self.token, nil);
}

@end

namespace firebase {
namespace firestore {
namespace auth {

TEST(FirebaseCredentialsProviderTest, GetTokenUnauthenticated) {
  FIRApp* app = testutil::AppForUnitTesting();
  FSTAuthFake* auth = [[FSTAuthFake alloc] initWithToken:nil uid:nil];
  FirebaseCredentialsProvider credentials_provider(app, auth);
  credentials_provider.GetToken([](util::StatusOr<Token> result) {
    EXPECT_TRUE(result.ok());
    const Token& token = result.ValueOrDie();
    EXPECT_ANY_THROW(token.token());
    const User& user = token.user();
    EXPECT_EQ("", user.uid());
    EXPECT_FALSE(user.is_authenticated());
  });
}

TEST(FirebaseCredentialsProviderTest, GetToken) {
  FIRApp* app = testutil::AppForUnitTesting();
  FSTAuthFake* auth =
      [[FSTAuthFake alloc] initWithToken:@"token for fake uid" uid:@"fake uid"];
  FirebaseCredentialsProvider credentials_provider(app, auth);
  credentials_provider.GetToken([](util::StatusOr<Token> result) {
    EXPECT_TRUE(result.ok());
    const Token& token = result.ValueOrDie();
    EXPECT_EQ("token for fake uid", token.token());
    const User& user = token.user();
    EXPECT_EQ("fake uid", user.uid());
    EXPECT_TRUE(user.is_authenticated());
  });
}

TEST(FirebaseCredentialsProviderTest, SetListener) {
  FIRApp* app = testutil::AppForUnitTesting();
  FSTAuthFake* auth =
      [[FSTAuthFake alloc] initWithToken:@"default token" uid:@"fake uid"];
  FirebaseCredentialsProvider credentials_provider(app, auth);
  credentials_provider.SetUserChangeListener([](User user) {
    EXPECT_EQ("fake uid", user.uid());
    EXPECT_TRUE(user.is_authenticated());
  });

  credentials_provider.SetUserChangeListener(nullptr);
}

TEST(FirebaseCredentialsProviderTest, InvalidateToken) {
  FIRApp* app = testutil::AppForUnitTesting();
  FSTAuthFake* auth =
      [[FSTAuthFake alloc] initWithToken:@"token for fake uid" uid:@"fake uid"];
  FirebaseCredentialsProvider credentials_provider(app, auth);
  credentials_provider.InvalidateToken();
  credentials_provider.GetToken([&auth](util::StatusOr<Token> result) {
    EXPECT_TRUE(result.ok());
    EXPECT_TRUE(auth.forceRefreshTriggered);
    const Token& token = result.ValueOrDie();
    EXPECT_EQ("token for fake uid", token.token());
    EXPECT_EQ("fake uid", token.user().uid());
  });
}

}  // namespace auth
}  // namespace firestore
}  // namespace firebase
