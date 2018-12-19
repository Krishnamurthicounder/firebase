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

#import <Foundation/Foundation.h>

#import <GoogleDataLogger/GDLLogBackend.h>
#import <GoogleDataLogger/GDLLogScorer.h>

NS_ASSUME_NONNULL_BEGIN

/** Manages the registration of log targets with the logging SDK. */
@interface GDLRegistrar : NSObject

/** Creates and/or returns the singleton instance.
 *
 * @return The singleton instance of this class.
 */
+ (instancetype)sharedInstance;

/** Registers a backend implementation with the GoogleDataLogger infrastructure.
 *
 * @param backend The backend object to register.
 * @param logTarget The logTarget this backend object will be responsible for.
 */
- (void)registerBackend:(id<GDLLogBackend>)backend forLogTarget:(NSInteger)logTarget;

/** Registers a log scorer implementation with the GoogleDataLogger infrastructure.
 *
 * @param scorer The scorer object to register.
 * @param logTarget The logTarget this scorer objet will be responsible for.
 */
- (void)registerLogScorer:(id<GDLLogScorer>)scorer forLogTarget:(NSInteger)logTarget;

@end

NS_ASSUME_NONNULL_END
