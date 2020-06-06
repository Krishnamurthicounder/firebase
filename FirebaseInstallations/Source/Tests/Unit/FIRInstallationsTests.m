/*
 * Copyright 2019 Google
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

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "FirebaseCore/Sources/Private/FirebaseCoreInternal.h"
#import "FBLPromise+Testing.h"
#import "FIRInstallations+Tests.h"
#import "FIRInstallationsErrorUtil+Tests.h"
#import "FIRInstallationsItem+Tests.h"

#import "FIRInstallations.h"
#import "FIRInstallationsAuthTokenResultInternal.h"
#import "FIRInstallationsErrorUtil.h"
#import "FIRInstallationsHTTPError.h"
#import "FIRInstallationsIDController.h"
#import "FIRInstallationsStoredAuthToken.h"

@interface FIRInstallationsTests : XCTestCase
@property(nonatomic) FIRInstallations *installations;
@property(nonatomic) id mockIDController;
@property(nonatomic) FIROptions *appOptions;
@end

@implementation FIRInstallationsTests

- (void)setUp {
  [super setUp];

  self.appOptions = [[FIROptions alloc] initWithGoogleAppID:@"GoogleAppID"
                                                GCMSenderID:@"GCMSenderID"];
  self.appOptions.APIKey = @"APIKey";
  self.appOptions.projectID = @"ProjectID";

  self.mockIDController = OCMClassMock([FIRInstallationsIDController class]);
  self.installations = [[FIRInstallations alloc] initWithAppOptions:self.appOptions
                                                            appName:@"appName"
                                          installationsIDController:self.mockIDController
                                                  prefetchAuthToken:NO];
}

- (void)tearDown {
  self.installations = nil;
  self.mockIDController = nil;
  [super tearDown];
}

- (void)testDefaultInstallationWhenNoDefaultAppThenIsNil {
  XCTAssertThrows([FIRInstallations installations]);
}

- (void)testInstallationIDSuccess {
  // Stub get installation.
  FIRInstallationsItem *installation = [FIRInstallationsItem createUnregisteredInstallationItem];
  OCMExpect([self.mockIDController getInstallationItem])
      .andReturn([FBLPromise resolvedWith:installation]);

  XCTestExpectation *idExpectation = [self expectationWithDescription:@"InstallationIDSuccess"];
  [self.installations
      installationIDWithCompletion:^(NSString *_Nullable identifier, NSError *_Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(identifier);
        XCTAssertEqualObjects(identifier, installation.firebaseInstallationID);

        [idExpectation fulfill];
      }];

  [self waitForExpectations:@[ idExpectation ] timeout:0.5];

  OCMVerifyAll(self.mockIDController);
}

- (void)testInstallationIDError {
  // Stub get installation.
  FBLPromise *errorPromise = [FBLPromise pendingPromise];
  NSError *privateError = [NSError errorWithDomain:@"TestsError" code:-1 userInfo:nil];
  [errorPromise reject:privateError];

  OCMExpect([self.mockIDController getInstallationItem]).andReturn(errorPromise);

  XCTestExpectation *idExpectation = [self expectationWithDescription:@"InstallationIDSuccess"];
  [self.installations
      installationIDWithCompletion:^(NSString *_Nullable identifier, NSError *_Nullable error) {
        XCTAssertNil(identifier);
        XCTAssertNotNil(error);

        XCTAssertEqualObjects(error.domain, kFirebaseInstallationsErrorDomain);
        XCTAssertEqualObjects(error.userInfo[NSUnderlyingErrorKey], errorPromise.error);

        [idExpectation fulfill];
      }];

  [self waitForExpectations:@[ idExpectation ] timeout:0.5];

  OCMVerifyAll(self.mockIDController);
}

- (void)testAuthTokenSuccess {
  FIRInstallationsItem *installationWithToken =
      [FIRInstallationsItem createRegisteredInstallationItemWithAppID:self.appOptions.googleAppID
                                                              appName:@"appName"];
  installationWithToken.authToken.token = @"token";
  installationWithToken.authToken.expirationDate = [NSDate dateWithTimeIntervalSinceNow:1000];
  OCMExpect([self.mockIDController getAuthTokenForcingRefresh:NO])
      .andReturn([FBLPromise resolvedWith:installationWithToken]);

  XCTestExpectation *tokenExpectation = [self expectationWithDescription:@"AuthTokenSuccess"];
  [self.installations
      authTokenWithCompletion:^(FIRInstallationsAuthTokenResult *_Nullable tokenResult,
                                NSError *_Nullable error) {
        XCTAssertNotNil(tokenResult);
        XCTAssertGreaterThan(tokenResult.authToken.length, 0);
        XCTAssertTrue([tokenResult.expirationDate laterDate:[NSDate date]]);
        XCTAssertNil(error);

        [tokenExpectation fulfill];
      }];

  [self waitForExpectations:@[ tokenExpectation ] timeout:0.5];

  OCMVerifyAll(self.mockIDController);
}

- (void)testAuthTokenError {
  FBLPromise *errorPromise = [FBLPromise pendingPromise];
  [errorPromise reject:[FIRInstallationsErrorUtil
                           APIErrorWithHTTPCode:FIRInstallationsHTTPCodesServerInternalError]];
  OCMExpect([self.mockIDController getAuthTokenForcingRefresh:NO]).andReturn(errorPromise);

  XCTestExpectation *tokenExpectation = [self expectationWithDescription:@"AuthTokenSuccess"];
  [self.installations
      authTokenWithCompletion:^(FIRInstallationsAuthTokenResult *_Nullable tokenResult,
                                NSError *_Nullable error) {
        XCTAssertNil(tokenResult);
        XCTAssertEqualObjects(error, errorPromise.error);

        [tokenExpectation fulfill];
      }];

  [self waitForExpectations:@[ tokenExpectation ] timeout:0.5];

  OCMVerifyAll(self.mockIDController);
}

- (void)testAuthTokenForcingRefreshSuccess {
  FIRInstallationsItem *installationWithToken =
      [FIRInstallationsItem createRegisteredInstallationItemWithAppID:self.appOptions.googleAppID
                                                              appName:@"appName"];
  installationWithToken.authToken.token = @"token";
  installationWithToken.authToken.expirationDate = [NSDate dateWithTimeIntervalSinceNow:1000];
  OCMExpect([self.mockIDController getAuthTokenForcingRefresh:YES])
      .andReturn([FBLPromise resolvedWith:installationWithToken]);

  XCTestExpectation *tokenExpectation = [self expectationWithDescription:@"AuthTokenSuccess"];
  [self.installations
      authTokenForcingRefresh:YES
                   completion:^(FIRInstallationsAuthTokenResult *_Nullable tokenResult,
                                NSError *_Nullable error) {
                     XCTAssertNil(error);
                     XCTAssertNotNil(tokenResult);
                     XCTAssertEqualObjects(tokenResult.authToken,
                                           installationWithToken.authToken.token);
                     XCTAssertEqualObjects(tokenResult.expirationDate,
                                           installationWithToken.authToken.expirationDate);
                     [tokenExpectation fulfill];
                   }];

  [self waitForExpectations:@[ tokenExpectation ] timeout:0.5];

  OCMVerifyAll(self.mockIDController);
}

- (void)testAuthTokenForcingRefreshError {
  FBLPromise *errorPromise = [FBLPromise pendingPromise];
  [errorPromise reject:[FIRInstallationsErrorUtil
                           APIErrorWithHTTPCode:FIRInstallationsHTTPCodesServerInternalError]];
  OCMExpect([self.mockIDController getAuthTokenForcingRefresh:YES]).andReturn(errorPromise);

  XCTestExpectation *tokenExpectation = [self expectationWithDescription:@"AuthTokenSuccess"];
  [self.installations
      authTokenForcingRefresh:YES
                   completion:^(FIRInstallationsAuthTokenResult *_Nullable tokenResult,
                                NSError *_Nullable error) {
                     XCTAssertNil(tokenResult);
                     XCTAssertEqualObjects(error, errorPromise.error);

                     [tokenExpectation fulfill];
                   }];

  [self waitForExpectations:@[ tokenExpectation ] timeout:0.5];

  OCMVerifyAll(self.mockIDController);
}

- (void)testDeleteSuccess {
  OCMExpect([self.mockIDController deleteInstallation])
      .andReturn([FBLPromise resolvedWith:[NSNull null]]);

  XCTestExpectation *deleteExpectation = [self expectationWithDescription:@"DeleteSuccess"];
  [self.installations deleteWithCompletion:^(NSError *_Nullable error) {
    XCTAssertNil(error);
    [deleteExpectation fulfill];
  }];

  [self waitForExpectations:@[ deleteExpectation ] timeout:0.5];
}

- (void)testDeleteError {
  FBLPromise *errorPromise = [FBLPromise pendingPromise];
  NSError *APIError =
      [FIRInstallationsErrorUtil APIErrorWithHTTPCode:FIRInstallationsHTTPCodesServerInternalError];
  [errorPromise reject:APIError];
  OCMExpect([self.mockIDController deleteInstallation]).andReturn(errorPromise);

  XCTestExpectation *deleteExpectation = [self expectationWithDescription:@"deleteExpectation"];
  [self.installations deleteWithCompletion:^(NSError *_Nullable error) {
    XCTAssertEqualObjects(error, APIError);
    [deleteExpectation fulfill];
  }];

  [self waitForExpectations:@[ deleteExpectation ] timeout:0.5];
}

#pragma mark - Invalid Firebase configuration

- (void)testInitWhenProjectIDMissingThenNoThrow {
  FIROptions *options = [self.appOptions copy];
  options.projectID = nil;
  XCTAssertNoThrow([self createInstallationsWithAppOptions:options appName:@"missingProjectID"]);

  options.projectID = @"";
  XCTAssertNoThrow([self createInstallationsWithAppOptions:options appName:@"emptyProjectID"]);
}

- (void)testInitWhenAPIKeyMissingThenThrows {
  FIROptions *options = [self.appOptions copy];
  options.APIKey = nil;
  XCTAssertThrows([self createInstallationsWithAppOptions:options appName:@"missingAPIKey"]);

  options.APIKey = @"";
  XCTAssertThrows([self createInstallationsWithAppOptions:options appName:@"emptyAPIKey"]);
}

- (void)testInitWhenGoogleAppIDMissingThenThrows {
  FIROptions *options = [self.appOptions copy];
  options.googleAppID = @"";
  XCTAssertThrows([self createInstallationsWithAppOptions:options appName:@"emptyGoogleAppID"]);
}

- (void)testInitWhenGCMSenderIDMissingThenThrows {
  FIROptions *options = [self.appOptions copy];
  options.GCMSenderID = @"";
  XCTAssertNoThrow([self createInstallationsWithAppOptions:options appName:@"emptyGCMSenderID"]);
}

- (void)testInitWhenProjectIDAndGCMSenderIDMissingThenNoThrow {
  FIROptions *options = [self.appOptions copy];
  options.GCMSenderID = @"";

  options.projectID = nil;
  XCTAssertThrows([self createInstallationsWithAppOptions:options appName:@"missingProjectID"]);

  options.projectID = @"";
  XCTAssertThrows([self createInstallationsWithAppOptions:options appName:@"emptyProjectID"]);
}

- (void)testInitWhenAppNameMissingThenThrows {
  FIROptions *options = [self.appOptions copy];
  XCTAssertThrows([self createInstallationsWithAppOptions:options appName:@""]);
  XCTAssertThrows([self createInstallationsWithAppOptions:options appName:nil]);
}

- (void)testInitWhenAppOptionsMissingThenThrows {
  XCTAssertThrows([self createInstallationsWithAppOptions:nil appName:@"missingOptions"]);
}

#pragma mark - Helpers

- (FIRInstallations *)createInstallationsWithAppOptions:(FIROptions *)options
                                                appName:(NSString *)appName {
  id mockIDController = OCMClassMock([FIRInstallationsIDController class]);
  return [[FIRInstallations alloc] initWithAppOptions:options
                                              appName:appName
                            installationsIDController:mockIDController
                                    prefetchAuthToken:NO];
}

@end
