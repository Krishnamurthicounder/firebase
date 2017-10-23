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

#import <XCTest/XCTest.h>

#import <Firestore/FIRFirestoreSettings.h>

#import "Auth/FSTEmptyCredentialsProvider.h"
#import "Core/FSTDatabaseInfo.h"
#import "FSTHelpers.h"
#import "FSTIntegrationTestCase.h"
#import "Model/FSTDatabaseID.h"
#import "Remote/FSTDatastore.h"
#import "Util/FSTAssert.h"
#import "Util/FSTDispatchQueue.h"

/** Exposes otherwise private methods for testing. */
@interface FSTStream (Testing)
- (void)writesFinishedWithError:(NSError *_Nullable)error;
@end

/**
 * Implements FSTWatchStreamDelegate and FSTWriteStreamDelegate and supports waiting on callbacks
 * via `fulfillOnCallback`.
 */
@interface FSTStreamStatusDelegate : NSObject <FSTWatchStreamDelegate, FSTWriteStreamDelegate>

- (instancetype)initFrom:(XCTestCase *)testCase
              usingQueue:(FSTDispatchQueue *)dispatchQueue NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@property(nonatomic, readonly) NSMutableArray<NSString *> *states;
@property(atomic, readwrite) BOOL invokeCallbacks;
@property(nonatomic, weak) XCTestExpectation *expectation;
@property(nonatomic, weak, readonly) FSTStream *stream;
@property(nonatomic, weak, readonly) XCTestCase *testCase;
@property(nonatomic, weak, readonly) FSTDispatchQueue *dispatchQueue;

@end

@implementation FSTStreamStatusDelegate

- (instancetype)initFrom:(XCTestCase *)testCase usingQueue:(FSTDispatchQueue *)dispatchQueue {
  if (self = [super init]) {
    _testCase = testCase;
    _dispatchQueue = dispatchQueue;
    _states = [NSMutableArray new];
  }

  return self;
}

- (void)watchStreamDidOpen {
  [_states addObject:@"watchStreamDidOpen"];
  [_expectation fulfill];
  _expectation = nil;
}

- (void)writeStreamDidOpen {
  [_states addObject:@"writeStreamDidOpen"];
  [_expectation fulfill];
  _expectation = nil;
}

- (void)writeStreamDidCompleteHandshake {
  [_states addObject:@"writeStreamDidCompleteHandshake"];
  [_expectation fulfill];
  _expectation = nil;
}

- (void)writeStreamDidClose:(NSError *_Nullable)error {
  [_states addObject:@"writeStreamDidClose"];
  [_expectation fulfill];
  _expectation = nil;
}

- (void)watchStreamDidClose:(NSError *_Nullable)error {
  [_states addObject:@"watchStreamDidClose"];
  [_expectation fulfill];
  _expectation = nil;
}

- (void)watchStreamDidChange:(FSTWatchChange *)change
             snapshotVersion:(FSTSnapshotVersion *)snapshotVersion {
  [_states addObject:@"watchStreamDidChange"];
  [_expectation fulfill];
  _expectation = nil;
}

- (void)writeStreamDidReceiveResponseWithVersion:(FSTSnapshotVersion *)commitVersion
                                 mutationResults:(NSArray<FSTMutationResult *> *)results {
  [_states addObject:@"writeStreamDidReceiveResponseWithVersion"];
  [_expectation fulfill];
  _expectation = nil;
}

/**
 * Executes 'block' using the provided FSTDispatchQueue and waits for any callback on this delegate
 * to be called.
 */
- (void)awaitNotificationFromBlock:(void (^)(void))block {
  FSTAssert(_expectation == nil, @"Previous expectation still active");
  XCTestExpectation *expectation =
      [self.testCase expectationWithDescription:@"awaitCallbackInBlock"];
  _expectation = expectation;
  [self.dispatchQueue dispatchAsync:block];
  [self.testCase awaitExpectations];
}

@end

@interface FSTStreamTests : XCTestCase

@end

@implementation FSTStreamTests {
  dispatch_queue_t _testQueue;
  FSTDatabaseInfo *_databaseInfo;
  FSTEmptyCredentialsProvider *_credentials;
  FSTStreamStatusDelegate *_delegate;
  FSTDispatchQueue *_workerDispatchQueue;

  /** Single mutation to send to the write stream. */
  NSArray<FSTMutation *> *_mutations;
}

- (void)setUp {
  [super setUp];

  _mutations = @[ FSTTestSetMutation(@"foo/bar", @{}) ];

  FIRFirestoreSettings *settings = [FSTIntegrationTestCase settings];
  FSTDatabaseID *databaseID =
      [FSTDatabaseID databaseIDWithProject:[FSTIntegrationTestCase projectID]
                                  database:kDefaultDatabaseID];

  _databaseInfo = [FSTDatabaseInfo databaseInfoWithDatabaseID:databaseID
                                               persistenceKey:@"test-key"
                                                         host:settings.host
                                                   sslEnabled:settings.sslEnabled];
  _testQueue = dispatch_queue_create("FSTStreamTestWorkerQueue", DISPATCH_QUEUE_SERIAL);
  _workerDispatchQueue = [FSTDispatchQueue queueWith:_testQueue];
  _credentials = [[FSTEmptyCredentialsProvider alloc] init];
}

- (FSTWriteStream *)setUpWriteStream {
  FSTDatastore *datastore = [[FSTDatastore alloc] initWithDatabaseInfo:_databaseInfo
                                                   workerDispatchQueue:_workerDispatchQueue
                                                           credentials:_credentials];

  _delegate = [[FSTStreamStatusDelegate alloc] initFrom:self usingQueue:_workerDispatchQueue];
  return [datastore createWriteStreamWithDelegate:_delegate];
}

- (FSTWatchStream *)setUpWatchStream {
  FSTDatastore *datastore = [[FSTDatastore alloc] initWithDatabaseInfo:_databaseInfo
                                                   workerDispatchQueue:_workerDispatchQueue
                                                           credentials:_credentials];

  _delegate = [[FSTStreamStatusDelegate alloc] initFrom:self usingQueue:_workerDispatchQueue];
  return [datastore createWatchStreamWithDelegate:_delegate];
}

/**
 * Drains the test queue and asserts that all the observed callbacks (up to this point) match
 * 'expectedStates'. Clears the list of observed callbacks on completion.
 */
- (void)verifyDelegateObservedStates:(NSArray<NSString *> *)expectedStates {
  // Drain queue
  dispatch_sync(_testQueue, ^{
                });

  XCTAssertEqualObjects(_delegate.states, expectedStates);
  [_delegate.states removeAllObjects];
}

/** Verifies that the watch stream does not issue an onClose callback after a call to stop(). */
- (void)testWatchStreamStopBeforeHandshake {
  FSTWatchStream *watchStream = [self setUpWatchStream];

  [_delegate awaitNotificationFromBlock:^{
    [watchStream start];
  }];

  // Stop must not call watchStreamDidClose because the full implementation of the delegate could
  // attempt to restart the stream in the event it had pending watches.
  [_workerDispatchQueue dispatchAsync:^{
    [watchStream stop];
  }];

  // Simulate a final callback from GRPC
  [watchStream writesFinishedWithError:nil];

  [self verifyDelegateObservedStates:@[ @"watchStreamDidOpen" ]];
}

/** Verifies that the write stream does not issue an onClose callback after a call to stop(). */
- (void)testWriteStreamStopBeforeHandshake {
  FSTWriteStream *writeStream = [self setUpWriteStream];

  [_delegate awaitNotificationFromBlock:^{
    [writeStream start];
  }];

  // Don't start the handshake.

  // Stop must not call watchStreamDidClose because the full implementation of the delegate could
  // attempt to restart the stream in the event it had pending watches.
  [_workerDispatchQueue dispatchAsync:^{
    [writeStream stop];
  }];

  // Simulate a final callback from GRPC
  [writeStream writesFinishedWithError:nil];

  [self verifyDelegateObservedStates:@[ @"writeStreamDidOpen" ]];
}

- (void)testWriteStreamStopAfterHandshake {
  FSTWriteStream *writeStream = [self setUpWriteStream];

  [_delegate awaitNotificationFromBlock:^{
    [writeStream start];
  }];

  // Writing before the handshake should throw
  dispatch_sync(_testQueue, ^{
    XCTAssertThrows([writeStream writeMutations:_mutations]);
  });

  [_delegate awaitNotificationFromBlock:^{
    [writeStream writeHandshake];
  }];

  // Now writes should succeed
  [_delegate awaitNotificationFromBlock:^{
    [writeStream writeMutations:_mutations];
  }];

  [_workerDispatchQueue dispatchAsync:^{
    [writeStream stop];
  }];

  [self verifyDelegateObservedStates:@[
    @"writeStreamDidOpen", @"writeStreamDidCompleteHandshake",
    @"writeStreamDidReceiveResponseWithVersion"
  ]];
}

@end
