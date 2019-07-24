// Copyright 2019 Google
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

#import "FirebaseSegmentation/Sources/Public/FIRSegmentation.h"
#import "FIRApp.h"

@interface SEGInitializationTests : XCTestCase

@end

@implementation SEGInitializationTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the
  // class.
  [FIRApp configure];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the
  // class.
}

- (void)testExample {
  FIRSegmentation *segmentation = [FIRSegmentation segmentation];
  XCTAssertNotNil(segmentation);
}

@end
