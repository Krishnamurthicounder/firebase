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

#ifndef FIRESTORE_CORE_TEST_FIREBASE_FIRESTORE_TESTUTIL_ASYNC_TESTING_H_
#define FIRESTORE_CORE_TEST_FIREBASE_FIRESTORE_TESTUTIL_ASYNC_TESTING_H_

#include <chrono>  // NOLINT(build/c++11)
#include <functional>
#include <future>  // NOLINT(build/c++11)
#include <memory>
#include <thread>  // NOLINT(build/c++11)

#include "gtest/gtest.h"

namespace firebase {
namespace firestore {
namespace util {

class AsyncQueue;
class Executor;

}  // namespace util

namespace testutil {

/**
 * Creates an AsyncQueue suitable for testing, based on the default executor
 * for the current platform.
 *
 * @param name A simple name for the kind of executor this is (e.g. "user" for
 *     executors that emulate delivery of user events or "worker" for executors
 *     that back AsyncQueues.)
 */
std::unique_ptr<util::Executor> ExecutorForTesting(const char* name);

/**
 * Creates an AsyncQueue suitable for testing, based on the default executor
 * for the current platform.
 */
std::shared_ptr<util::AsyncQueue> AsyncQueueForTesting();

constexpr auto kTimeout = std::chrono::seconds(5);

/**
 * An expected outcome of an asynchronous test.
 */
class Expectation {
 public:
  Expectation();

  /** Marks this expectation as fulfilled. */
  void Fulfill();

  /**
   * Returns a callback function, that when invoked, fullfills the expectation.
   *
   * The returned function has a lifetime that's independent of the Expectation
   * that created it.
   */
  std::function<void()> AsCallback() const;

  /**
   * Returns a `future` that represents the completion of this Expectation.
   */
  std::future<void> get_future() const;

 private:
  std::shared_ptr<std::promise<void>> promise_;
};

/**
 * A mixin that supplies utilities for safely writing asynchronous tests.
 */
class AsyncTest {
 public:
  AsyncTest()
      : trace_("Test case name",
               1,
               testing::Message() << testing::UnitTest::GetInstance()
                                         ->current_test_info()
                                         ->name()) {
  }

  std::future<void> Async(std::function<void()> action);

  /**
   * Waits for the future to become ready.
   *
   * Fails the current test if the timeout occurs.
   */
  void Await(const std::future<void>& future,
             std::chrono::milliseconds timeout = kTimeout);

  /**
   * Waits for the promise to become ready. The future associated with the
   * promise is consumed via `promise.get_future()`.
   *
   * Fails the current test if the timeout occurs.
   */
  void Await(std::promise<void>& promise,  // NOLINT(runtime/references)
             std::chrono::milliseconds timeout = kTimeout);

  /**
   * Waits for the expectation to become fulfilled.
   *
   * Fails the current test if the timeout occurs.
   */
  void Await(const Expectation& expectation,
             std::chrono::milliseconds timeout = kTimeout);

  /**
   * Sleeps the current thread for the given number of milliseconds.
   */
  void SleepFor(int millis);

 private:
  testing::ScopedTrace trace_;
};

}  // namespace testutil
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_TEST_FIREBASE_FIRESTORE_TESTUTIL_ASYNC_TESTING_H_
