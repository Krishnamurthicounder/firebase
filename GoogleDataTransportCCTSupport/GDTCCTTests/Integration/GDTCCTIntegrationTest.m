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

#import <GoogleDataTransport/GDTCOREvent.h>
#import <GoogleDataTransport/GDTCOREventDataObject.h>
#import <GoogleDataTransport/GDTCORTransport.h>

#import <SystemConfiguration/SCNetworkReachability.h>

#import "GDTCCTLibrary/Private/GDTCCTPrioritizer.h"
#import "GDTCCTLibrary/Private/GDTCCTUploader.h"

typedef void (^GDTCCTIntegrationTestBlock)(NSURLSessionUploadTask *_Nullable);

@interface GDTCCTTestDataObject : NSObject <GDTCOREventDataObject>

@end

@implementation GDTCCTTestDataObject

- (NSData *)transportBytes {
  // Return some random event data corresponding to mapping ID 1018.
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSArray *dataFiles = @[
    @"message-32347456.dat", @"message-35458880.dat", @"message-39882816.dat",
    @"message-40043840.dat", @"message-40657984.dat"
  ];
  NSURL *fileURL = [testBundle URLForResource:dataFiles[arc4random_uniform(5)] withExtension:nil];
  return [NSData dataWithContentsOfURL:fileURL];
}

@end

@interface GDTCCTIntegrationTest : XCTestCase

/** If YES, the network conditions were good enough to allow running integration tests. */
@property(nonatomic) BOOL okToRunTest;

/** If YES, allow the recursive generating of events. */
@property(nonatomic) BOOL generateEvents;

/** The total number of events generated for this test. */
@property(nonatomic) NSInteger totalEventsGenerated;

/** The transporter used by the test. */
@property(nonatomic) GDTCORTransport *transport;

/** The local notification listener, to be removed after each test. */
@property(nonatomic, strong) id<NSObject> uploadObserver;

@end

@implementation GDTCCTIntegrationTest

- (void)setUp {
  // Don't recursively generate events by default.
  self.generateEvents = NO;
  SCNetworkReachabilityRef reachabilityRef =
      SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(), "https://google.com");
  SCNetworkReachabilityFlags flags;
  Boolean success = SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
  if (success) {
    self.okToRunTest =
        (flags & kSCNetworkReachabilityFlagsReachable) == kSCNetworkReachabilityFlagsReachable;
    self.transport = [[GDTCORTransport alloc] initWithMappingID:@"1018"
                                                   transformers:nil
                                                         target:kGDTCORTargetCCT];
  }
}

- (void)tearDown {
  if (self.uploadObserver) {
    [[NSNotificationCenter defaultCenter] removeObserver:self.uploadObserver];
  }

  [super tearDown];
}

/** Generates an event and sends it through the transport infrastructure. */
- (void)generateEventWithQoSTier:(GDTCOREventQoS)qosTier {
  GDTCOREvent *event = [self.transport eventForTransport];
  event.dataObject = [[GDTCCTTestDataObject alloc] init];
  event.qosTier = qosTier;
  [self.transport sendDataEvent:event];
  self.totalEventsGenerated += 1;
  NSLog(@"EVENT GENERATED: %ld total now", (long)self.totalEventsGenerated);
}

/** Generates events recursively at random intervals between 0 and 5 seconds. */
- (void)recursivelyGenerateEvent {
  if (self.generateEvents) {
    [self generateEventWithQoSTier:GDTCOREventQosDefault];
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(arc4random_uniform(6) * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          [self recursivelyGenerateEvent];
        });
  }
}

/** Tests sending data to CCT with a high priority event if network conditions are good. */
- (void)testSendingDataToCCT {
  if (!self.okToRunTest) {
    NSLog(@"Skipping the integration test, as the network conditions weren't good enough.");
    return;
  }

  // Send a number of events across multiple queues in order to ensure the threading is working as
  // expected.
  dispatch_queue_t queue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_queue_t queue2 = dispatch_queue_create("com.gdtcct.test", DISPATCH_QUEUE_SERIAL);
  for (int i = 0; i < 12; i++) {
    int result = i % 3;
    if (result == 0) {
      [self generateEventWithQoSTier:GDTCOREventQosDefault];
    } else if (result == 1) {
      dispatch_async(queue1, ^{
        [self generateEventWithQoSTier:GDTCOREventQosDefault];
      });
    } else if (result == 2) {
      dispatch_async(queue2, ^{
        [self generateEventWithQoSTier:GDTCOREventQosDefault];
      });
    }
  }

  // Add a notification expectation for the right number of events sent by the uploader.
  XCTestExpectation *eventCountsMatchExpectation = [self
      expectationWithDescription:@"Events uploaded should equal the amount that were generated."];
  self.uploadObserver =
      [self uploadNotificationObserverWithExpectation:eventCountsMatchExpectation];

  // Send a high priority event to flush events.
  [self generateEventWithQoSTier:GDTCOREventQoSFast];

  // Validate all events were sent.
  [self waitForExpectations:@[ eventCountsMatchExpectation ] timeout:60.0];
}

- (void)testRunsWithoutCrashing {
  // Just run for a minute whilst generating events.
  NSInteger secondsToRun = 65;
  self.generateEvents = YES;

  XCTestExpectation *eventCountsMatchExpectation = [self
      expectationWithDescription:@"Events uploaded should equal the amount that were generated."];
  self.uploadObserver =
      [self uploadNotificationObserverWithExpectation:eventCountsMatchExpectation];

  [self recursivelyGenerateEvent];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(secondsToRun * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   self.generateEvents = NO;

                   // Send a high priority event to flush other events.
                   [self generateEventWithQoSTier:GDTCOREventQoSFast];

                   [self waitForExpectations:@[ eventCountsMatchExpectation ] timeout:60.0];
                 });
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:secondsToRun + 5]];
}

- (id<NSObject>)uploadNotificationObserverWithExpectation:(XCTestExpectation *)expectation {
  // Keep track of how many events have been sent over the course of the test.
  __block NSInteger eventsSent = 0;
  return [[NSNotificationCenter defaultCenter]
      addObserverForName:GDTCCTUploadCompleteNotification
                  object:nil
                   queue:nil
              usingBlock:^(NSNotification *_Nonnull note) {
                NSNumber *eventsUploaded = note.object;
                if (![eventsUploaded isKindOfClass:[NSNumber class]]) {
                  XCTFail(@"Expected notification object of events uploaded, "
                          @"instead got a %@.",
                          [eventsUploaded class]);
                }

                eventsSent += eventsUploaded.integerValue;
                NSLog(@"Single upload event of %ld, combined for %ld/%ld total expected.",
                      (long)eventsUploaded.integerValue, (long)eventsSent,
                      (long)self.totalEventsGenerated);
                // Only fulfill the expectation once event generation is done and the numbers match.
                if (self.generateEvents == NO && eventsSent == self.totalEventsGenerated) {
                  [expectation fulfill];
                }
              }];
}

@end
