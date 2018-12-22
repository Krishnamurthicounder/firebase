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

#import <XCTest/XCTest.h>

#import <GoogleDataLogger/GDLLogEvent.h>

#import "GDLLogEvent_Private.h"
#import "GDLLogStorage.h"
#import "GDLLogStorage_Private.h"
#import "GDLRegistrar.h"
#import "GDLRegistrar_Private.h"

#import "GDLTestBackend.h"
#import "GDLTestPrioritizer.h"

#import "GDLLogStorage+Testing.h"
#import "GDLRegistrar+Testing.h"

static NSInteger logTarget = 1337;

@interface GDLLogStorageTest : XCTestCase

/** The test backend implementation. */
@property(nullable, nonatomic) GDLTestBackend *testBackend;

/** The test prioritizer implementation. */
@property(nullable, nonatomic) GDLTestPrioritizer *testPrioritizer;

@end

@implementation GDLLogStorageTest

- (void)setUp {
  self.testBackend = [[GDLTestBackend alloc] init];
  self.testPrioritizer = [[GDLTestPrioritizer alloc] init];
  [[GDLRegistrar sharedInstance] registerBackend:_testBackend forLogTarget:logTarget];
  [[GDLRegistrar sharedInstance] registerLogPrioritizer:_testPrioritizer forLogTarget:logTarget];
}

- (void)tearDown {
  // Destroy these objects before the next test begins.
  self.testBackend = nil;
  self.testPrioritizer = nil;
  [[GDLRegistrar sharedInstance] reset];
  [[GDLLogStorage sharedInstance] reset];
}

/** Tests the singleton pattern. */
- (void)testInit {
  XCTAssertEqual([GDLLogStorage sharedInstance], [GDLLogStorage sharedInstance]);
}

/** Tests storing a log. */
- (void)testStoreLog {
  NSUInteger logHash;
  // logEvent is autoreleased, and the pool needs to drain.
  @autoreleasepool {
    GDLLogEvent *logEvent = [[GDLLogEvent alloc] initWithLogMapID:@"404" logTarget:logTarget];
    logEvent.extensionBytes = [@"testString" dataUsingEncoding:NSUTF8StringEncoding];
    logHash = logEvent.hash;
    [[GDLLogStorage sharedInstance] storeLog:logEvent];
  }
  dispatch_sync([GDLLogStorage sharedInstance].storageQueue, ^{
    XCTAssertEqual([GDLLogStorage sharedInstance].logHashToLogFile.count, 1);
    XCTAssertEqual([GDLLogStorage sharedInstance].logTargetToLogFileSet[@(logTarget)].count, 1);
    NSURL *logFile = [GDLLogStorage sharedInstance].logHashToLogFile[@(logHash)];
    XCTAssertNotNil(logFile);
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:logFile.path]);
    NSError *error;
    XCTAssertTrue([[NSFileManager defaultManager] removeItemAtURL:logFile error:&error]);
    XCTAssertNil(error, @"There was an error deleting the logFile: %@", error);
  });
}

/** Tests removing a log. */
- (void)testRemoveLog {
  GDLLogEvent *logEvent = [[GDLLogEvent alloc] initWithLogMapID:@"404" logTarget:logTarget];
  logEvent.extensionBytes = [@"testString" dataUsingEncoding:NSUTF8StringEncoding];
  [[GDLLogStorage sharedInstance] storeLog:[logEvent copy]];
  __block NSURL *logFile;
  dispatch_sync([GDLLogStorage sharedInstance].storageQueue, ^{
    logFile = [GDLLogStorage sharedInstance].logHashToLogFile[@(logEvent.hash)];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:logFile.path]);
  });
  [[GDLLogStorage sharedInstance] removeLog:@(logEvent.hash) logTarget:@(logTarget)];
  dispatch_sync([GDLLogStorage sharedInstance].storageQueue, ^{
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:logFile.path]);
    XCTAssertEqual([GDLLogStorage sharedInstance].logHashToLogFile.count, 0);
    XCTAssertEqual([GDLLogStorage sharedInstance].logTargetToLogFileSet[@(logTarget)].count, 0);
  });
}

/** Tests enforcing that a log prioritizer does not retain a log in memory. */
- (void)testLogEventDeallocationIsEnforced {
 // TODO
}

/** Tests encoding and decoding the storage singleton correctly. */
- (void)testNSSecureCoding {
  // TODO
}

/** Tests logging a fast log causes an upload attempt. */
- (void)testQoSTierFast {
  // TODO
}

@end
