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

#import <GoogleDataLogger/GDLClock.h>
#import <GoogleDataLogger/GDLLogTargets.h>

NS_ASSUME_NONNULL_BEGIN

/** A convenient typedef to define the block to be called upon completion of an upload to the
 * backend.
 *
 * target: The log target that was uploading.
 * nextUploadAttemptUTC: The desired next upload attempt time.
 * uploadError: Populated with any upload error. If non-nil, a retry will be attempted.
 */
typedef void (^GDLUploaderCompletionBlock)(GDLLogTarget target,
                                           GDLClock *nextUploadAttemptUTC,
                                           NSError *_Nullable uploadError);

/** This protocol defines the common interface for logging backend implementations. */
@protocol GDLLogUploader <NSObject>

@required

/** Uploads logs to the backend using this specific backend's chosen format.
 *
 * @param logFiles The set of log files to upload.
 * @param onComplete A block to invoke upon completing the upload. Has two arguments:
 *   - successfulUploads: The set of filenames uploaded successfully.
 *   - unsuccessfulUploads: The set of filenames not uploaded successfully.
 */
- (void)uploadLogs:(NSSet<NSURL *> *)logFiles onComplete:(GDLUploaderCompletionBlock)onComplete;

@end

NS_ASSUME_NONNULL_END
