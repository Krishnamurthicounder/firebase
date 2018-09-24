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

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_UTIL_FILESYSTEM_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_UTIL_FILESYSTEM_H_

#include <memory>

#include "Firestore/core/src/firebase/firestore/util/path.h"
#include "Firestore/core/src/firebase/firestore/util/status.h"

namespace firebase {
namespace firestore {
namespace util {

// High-level routines for the manipulating the filesystem. All filesystems
// are required to implement these routines.

/**
 * Answers the question "is this path a directory? The path is not required to
 * have a trailing slash.
 *
 * Typical return codes include:
 *   * Ok - The path exists and is a directory.
 *   * FailedPrecondition - Some component of the path is not a directory. This
 *     does not necessarily imply that the path exists and is a file.
 *   * NotFound - The path does not exist
 *   * PermissionDenied - Insufficient permissions to access the path.
 */
Status IsDirectory(const Path& path);

/**
 * Recursively creates all the directories in the path name if they don't
 * exist.
 *
 * @return Ok if the directory was created or already existed.
 */
Status RecursivelyCreateDir(const Path& path);

/**
 * Recursively deletes the contents of the given pathname. If the pathname is
 * a file, deletes just that file. The the pathname is a directory, deletes
 * everything within the directory.
 *
 * @return Ok if the directory was deleted or did not exist.
 */
Status RecursivelyDelete(const Path& path);

/**
 * Recursively deletes the contents of the given pathname that is known to be
 * a directory.
 *
 * @return Ok if the directory was deleted or did not exist. Returns a
 *     system-defined error if the path exists but is not a directory.
 *
 */
Status RecursivelyDeleteDir(const Path& path);

/**
 * Returns system-defined best directory in which to create temporary files.
 * Typical return values are like `/tmp` on UNIX systems. Clients should create
 * randomly named directories or files within this location to avoid collisions.
 * Absent any changes that might affect the underlying calls, the value returned
 * from TempDir will be stable over time.
 *
 * Note: the returned path is just where the system thinks temporary files
 * should be stored, but TempDir does not actually guarantee that this path
 * exists.
 */
Path TempDir();

/**
 * Implements an iterator over the contents of a directory. Initializes to the
 * first entry in the directory.
 */
class DirectoryIterator {
 public:
  /**
   * `path` should outlive the iterator.
   */
  explicit DirectoryIterator(const Path& path);
  ~DirectoryIterator();

  DirectoryIterator(const DirectoryIterator& other) = delete;

  DirectoryIterator& operator=(const DirectoryIterator& other) = delete;

  /**
   * Advances the iterator.
   */
  void Next();

  /**
   * Returns true if `Next()` and `file()` can be called on the iterator.
   * If `Valid() == false && status().ok()`, then iteration has finished.
   */
  bool Valid();

  /**
   * Return the full path of the current entry pointed to by the iterator.
   */
  Path file();

  /**
   * Returns the last error encountered by the iterator, or OK.
   */
  Status status() {
    return status_;
  }

 private:
  // Internal method to move to the next directory entry
  void Advance();

  Status status_;
  // Use a forward-declared struct to enable a portable header.
  struct Rep;
  std::unique_ptr<Rep> rep_;
  const Path& parent_;
};

}  // namespace util
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_UTIL_FILESYSTEM_H_
