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

#import "FirebaseStorageInternal/Tests/Unit/FIRStorageTestHelpers.h"

#import "SharedTestUtilities/FIRComponentTestUtilities.h"

NSString *const kGoogleHTTPErrorDomain = @"com.google.HTTPStatus";
NSString *const kHTTPVersion = @"HTTP/1.1";
NSString *const kUnauthenticatedResponseString =
    @"<html><body><p>User not authenticated. Authentication via Authorization header required. "
    @"Authorization Header does not match expected format of 'Authorization: Firebase "
    @"<JWT>'.</p></body></html>";
NSString *const kUnauthorizedResponseString =
    @"<html><body><p>User not authorized. Authentication via Authorization header required. "
    @"Authorization Header does not match expected format of 'Authorization: Firebase "
    @"<JWT>'.</p></body></html>";
NSString *const kNotFoundResponseString = @"<html><body><p>Object not found.</p></body></html>";
NSString *const kInvalidJSONResponseString = @"This is not a JSON object";
NSString *const kFIRStorageObjectURL =
    @"https://firebasestorage.googleapis.com:443/v0/b/bucket/o/object";
NSString *const kFIRStorageBucketURL = @"https://firebasestorage.googleapis.com:443/v0/b/bucket/o";
NSString *const kFIRStorageNotFoundURL =
    @"https://firebasestorage.googleapis.com:443/v0/b/bucket/o/i/dont/exist";
NSString *const kFIRStorageTestAuthToken = @"1234-5678-9012-3456-7890";
NSString *const kFIRStorageAppName = @"app";

@implementation FIRStorageTestHelpers

+ (FIRApp *)mockedApp {
  id mockApp = OCMClassMock([FIRApp class]);
  id mockOptions = OCMClassMock([FIROptions class]);
  OCMStub([mockOptions storageBucket]).andReturn(@"bucket");
  OCMStub([mockApp name]).andReturn(kFIRStorageAppName);
  OCMStub([(FIRApp *)mockApp options]).andReturn(mockOptions);
  return mockApp;
}

+ (NSURL *)objectURL {
  return [NSURL URLWithString:kFIRStorageObjectURL];
}

+ (NSURL *)bucketURL {
  return [NSURL URLWithString:kFIRStorageBucketURL];
}

+ (NSURL *)notFoundURL {
  return [NSURL URLWithString:kFIRStorageNotFoundURL];
}

#pragma mark - Private methods

+ (GTMSessionFetcherTestBlock)blockForData:(nullable NSData *)data
                                       URL:(nullable NSString *)url
                                statusCode:(NSInteger)code {
  GTMSessionFetcherTestBlock block =
      ^(GTMSessionFetcher *fetcher, GTMSessionFetcherTestResponse response) {
        if (url) {
          XCTAssertEqualObjects(url, [fetcher.request.URL absoluteString]);
        }
        NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:fetcher.request.URL
                                                                      statusCode:code
                                                                     HTTPVersion:kHTTPVersion
                                                                    headerFields:nil];
        NSError *error;
        if (code >= 400) {
          NSDictionary *userInfo;
          if (data) {
            userInfo = @{@"data" : data};
          }
          error = [NSError errorWithDomain:kGoogleHTTPErrorDomain code:code userInfo:userInfo];
        }

        response(httpResponse, data, error);
      };
  return block;
}

+ (void)waitForExpectation:(id)test {
  [test waitForExpectationsWithTimeout:kExpectationTimeoutSeconds
                               handler:^(NSError *_Nullable error) {
                                 if (error) {
                                   NSLog(@"Error: %@", error);
                                 }
                               }];
}

@end
