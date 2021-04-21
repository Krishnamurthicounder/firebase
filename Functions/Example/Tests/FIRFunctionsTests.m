// Copyright 2017 Google
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

#import <XCTest/XCTest.h>

#import "Functions/FirebaseFunctions/FIRFunctions+Internal.h"
#import "Functions/FirebaseFunctions/Public/FirebaseFunctions/FIRFunctions.h"

#import "SharedTestUtilities/AppCheckFake/FIRAppCheckFake.h"
#import "SharedTestUtilities/AppCheckFake/FIRAppCheckTokenResultFake.h"

#if SWIFT_PACKAGE
@import GTMSessionFetcherCore;
#else
#import <GTMSessionFetcher/GTMSessionFetcherService.h>
#endif

@interface FIRFunctions (Test)

@property(nonatomic, readonly) NSString *emulatorOrigin;

- (instancetype)initWithProjectID:(NSString *)projectID
                           region:(NSString *)region
                     customDomain:(nullable NSString *)customDomain
                             auth:(nullable id<FIRAuthInterop>)auth
                        messaging:(nullable id<FIRMessagingInterop>)messaging
                         appCheck:(nullable id<FIRAppCheckInterop>)appCheck
                   fetcherService:(GTMSessionFetcherService *)fetcherService;

@end

@interface FIRFunctionsTests : XCTestCase

@end

@implementation FIRFunctionsTests {
  FIRFunctions *_functions;
  FIRFunctions *_functionsCustomDomain;

  GTMSessionFetcherService *_fetcherService;
  FIRAppCheckFake *_appCheckFake;
}

- (void)setUp {
  [super setUp];
  _fetcherService = [[GTMSessionFetcherService alloc] init];
  _appCheckFake = [[FIRAppCheckFake alloc] init];

  _functions = [[FIRFunctions alloc] initWithProjectID:@"my-project"
                                                region:@"my-region"
                                          customDomain:nil
                                                  auth:nil
                                             messaging:nil
                                              appCheck:_appCheckFake
                                        fetcherService:_fetcherService];

  _functionsCustomDomain = [[FIRFunctions alloc] initWithProjectID:@"my-project"
                                                            region:@"my-region"
                                                      customDomain:@"https://mydomain.com"
                                                              auth:nil
                                                         messaging:nil
                                                          appCheck:nil
                                                    fetcherService:_fetcherService];
}

- (void)tearDown {
  _functionsCustomDomain = nil;
  _functions = nil;
  _fetcherService = nil;
  [super tearDown];
}

- (void)testURLWithName {
  NSString *url = [_functions URLWithName:@"my-endpoint"];
  XCTAssertEqualObjects(@"https://my-region-my-project.cloudfunctions.net/my-endpoint", url);
}

- (void)testRegionWithEmulator {
  [_functionsCustomDomain useEmulatorWithHost:@"localhost" port:5005];
  NSLog(@"%@", _functionsCustomDomain.emulatorOrigin);
  NSString *url = [_functionsCustomDomain URLWithName:@"my-endpoint"];
  XCTAssertEqualObjects(@"http://localhost:5005/my-project/my-region/my-endpoint", url);
}

- (void)testRegionWithEmulatorWithScheme {
  [_functionsCustomDomain useEmulatorWithHost:@"http://localhost" port:5005];
  NSLog(@"%@", _functionsCustomDomain.emulatorOrigin);
  NSString *url = [_functionsCustomDomain URLWithName:@"my-endpoint"];
  XCTAssertEqualObjects(@"http://localhost:5005/my-project/my-region/my-endpoint", url);
}

- (void)testCustomDomain {
  NSString *url = [_functionsCustomDomain URLWithName:@"my-endpoint"];
  XCTAssertEqualObjects(@"https://mydomain.com/my-endpoint", url);
}

- (void)testCustomDomainWithEmulator {
  [_functionsCustomDomain useEmulatorWithHost:@"localhost" port:5005];
  NSString *url = [_functionsCustomDomain URLWithName:@"my-endpoint"];
  XCTAssertEqualObjects(@"http://localhost:5005/my-project/my-region/my-endpoint", url);
}

- (void)testSetEmulatorSettings {
  [_functions useEmulatorWithHost:@"localhost" port:1000];
  XCTAssertEqualObjects(@"http://localhost:1000", _functions.emulatorOrigin);
}

#pragma mark - App Check integration

- (void)testCallFunctionWhenAppCheckIsInstalled {
  _appCheckFake.tokenResult = [[FIRAppCheckTokenResultFake alloc] initWithToken:@"valid_token"
                                                                          error:nil];

  NSError *networkError = [NSError errorWithDomain:@"testCallFunctionWhenAppCheckIsInstalled"
                                              code:-1
                                          userInfo:nil];

  XCTestExpectation *httpRequestExpectation =
      [self expectationWithDescription:@"HTTPRequestExpectation"];
  __weak __auto_type weakSelf = self;
  _fetcherService.testBlock = ^(GTMSessionFetcher *_Nonnull fetcherToTest,
                                GTMSessionFetcherTestResponse _Nonnull testResponse) {
    // Fixes retain cycle warning for Xcode 11 and earlier.
    // __unused to avoid warning in Xcode 12+.
    __unused __auto_type self = weakSelf;
    [httpRequestExpectation fulfill];

    NSString *appCheckTokenHeader =
        [fetcherToTest.request valueForHTTPHeaderField:@"X-Firebase-AppCheck"];
    XCTAssertEqualObjects(appCheckTokenHeader, @"valid_token");

    testResponse(nil, nil, networkError);
  };

  XCTestExpectation *completionExpectation =
      [self expectationWithDescription:@"completionExpectation"];
  [_functions callFunction:@"fake_func"
                withObject:nil
                   timeout:10
                completion:^(FIRHTTPSCallableResult *_Nullable result, NSError *_Nullable error) {
                  XCTAssertEqualObjects(error, networkError);
                  [completionExpectation fulfill];
                }];

  [self waitForExpectations:@[ httpRequestExpectation, completionExpectation ] timeout:1.5];
}

- (void)testCallFunctionWhenAppCheckIsNotInstalled {
  NSError *networkError = [NSError errorWithDomain:@"testCallFunctionWhenAppCheckIsInstalled"
                                              code:-1
                                          userInfo:nil];

  XCTestExpectation *httpRequestExpectation =
      [self expectationWithDescription:@"HTTPRequestExpectation"];
  
  __weak __auto_type weakSelf = self;
  _fetcherService.testBlock = ^(GTMSessionFetcher *_Nonnull fetcherToTest,
                                GTMSessionFetcherTestResponse _Nonnull testResponse) {
    // Fixes retain cycle warning for Xcode 11 and earlier.
    // __unused to avoid warning in Xcode 12+.
    __unused __auto_type self = weakSelf;
    [httpRequestExpectation fulfill];

    NSString *appCheckTokenHeader =
        [fetcherToTest.request valueForHTTPHeaderField:@"X-Firebase-AppCheck"];
    XCTAssertNil(appCheckTokenHeader);

    testResponse(nil, nil, networkError);
  };

  XCTestExpectation *completionExpectation =
      [self expectationWithDescription:@"completionExpectation"];
  [_functionsCustomDomain
      callFunction:@"fake_func"
        withObject:nil
           timeout:10
        completion:^(FIRHTTPSCallableResult *_Nullable result, NSError *_Nullable error) {
          XCTAssertEqualObjects(error, networkError);
          [completionExpectation fulfill];
        }];

  [self waitForExpectations:@[ httpRequestExpectation, completionExpectation ] timeout:1.5];
}

@end
