// Copyright 2021 Google LLC
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

#if compiler(>=5.5) && canImport(_Concurrency)
  @available(iOS 15, tvOS 15, macOS 12, watchOS 8, *)
  public extension StorageReference {
    /// Asynchronously downloads the object at the StorageReference to a Data object in memory.
    /// A Data object of the provided max size will be allocated, so ensure that the device has
    /// enough free memory to complete the download. For downloading large files, the `write`
    /// API may be a better option.
    ///
    /// - Parameters:
    ///   - size: The maximum size in bytes to download. If the download exceeds this size,
    ///           the task will be cancelled and an error will be thrown.
    /// - Returns: Data object.
    func data(maxSize: Int64) async throws -> Data {
      return try await withCheckedThrowingContinuation { continuation in
        // TODO: Use task to handle progress and cancellation.
        _ = self.getData(maxSize: maxSize) { result in
          continuation.resume(with: result)
        }
      }
    }

    /// Asynchronously uploads data to the currently specified StorageReference.
    /// This is not recommended for large files, and one should instead upload a file from disk
    /// from the Firebase Console.
    ///
    /// - Parameters:
    ///   - uploadData: The Data to upload.
    ///   - metadata: Optional StorageMetadata containing additional information (MIME type, etc.)
    ///              about the object being uploaded.
    /// - Returns: StorageMetadata with additional information about the object being uploaded.
    func putDataAsync(_ uploadData: Data,
                      metadata: StorageMetadata? = nil) async throws -> StorageMetadata {
      return try await withCheckedThrowingContinuation { continuation in
        // TODO: Use task to handle progress and cancellation.
        _ = self.putData(uploadData, metadata: metadata) { result in
          continuation.resume(with: result)
        }
      }
    }

    /// Asynchronously uploads a file to the currently specified StorageReference.
    ///
    /// - Parameters:
    ///   - url: A URL representing the system file path of the object to be uploaded.
    ///   - metadata: Optional StorageMetadata containing additional information (MIME type, etc.)
    ///              about the object being uploaded.
    /// - Returns: StorageMetadata with additional information about the object being uploaded.
    func putFileAsync(from url: URL,
                      metadata: StorageMetadata? = nil) async throws -> StorageMetadata {
      return try await withCheckedThrowingContinuation { continuation in
        // TODO: Use task to handle progress and cancellation.
        _ = self.putFile(from: url, metadata: metadata) { result in
          continuation.resume(with: result)
        }
      }
    }

    /// Asynchronously downloads the object at the current path to a specified system filepath.
    ///
    /// - Parameters:
    ///   - fileUrl: A URL representing the system file path of the object to be uploaded.
    /// - Returns: URL pointing to the file path of the downloaded file.
    func writeAsync(toFile fileURL: URL) async throws -> URL {
      return try await withCheckedThrowingContinuation { continuation in
        // TODO: Use task to handle progress and cancellation.
        _ = self.write(toFile: fileURL) { result in
          continuation.resume(with: result)
        }
      }
    }

    /// List up to `maxResults` items (files) and prefixes (folders) under this StorageReference.
    ///
    /// "/" is treated as a path delimiter. Firebase Storage does not support unsupported object
    /// paths that end with "/" or contain two consecutive "/"s. All invalid objects in GCS will be
    /// filtered.
    ///
    /// Only available for projects using Firebase Rules Version 2.
    ///
    /// - Parameters:
    ///   - maxResults The maximum number of results to return in a single page. Must be
    ///                greater than 0 and at most 1000.
    /// - Returns:
    ///   - completion A `Result` enum with either the list or an `Error`.
    func list(maxResults: Int64) async throws -> StorageListResult {
      typealias ListContinuation = CheckedContinuation<StorageListResult, Error>
      return try await withCheckedThrowingContinuation { (continuation: ListContinuation) in
        self.list(maxResults: maxResults) { result in
          continuation.resume(with: result)
        }
      }
    }

    /// List up to `maxResults` items (files) and prefixes (folders) under this StorageReference.
    ///
    /// "/" is treated as a path delimiter. Firebase Storage does not support unsupported object
    /// paths that end with "/" or contain two consecutive "/"s. All invalid objects in GCS will be
    /// filtered.
    ///
    /// Only available for projects using Firebase Rules Version 2.
    ///
    /// - Parameters:
    ///   - maxResults The maximum number of results to return in a single page. Must be
    ///                greater than 0 and at most 1000.
    ///   - pageToken A page token from a previous call to list.
    /// - Returns:
    ///   - completion A `Result` enum with either the list or an `Error`.
    func list(maxResults: Int64, pageToken: String) async throws -> StorageListResult {
      typealias ListContinuation = CheckedContinuation<StorageListResult, Error>
      return try await withCheckedThrowingContinuation { (continuation: ListContinuation) in
        self.list(maxResults: maxResults, pageToken: pageToken) { result in
          continuation.resume(with: result)
        }
      }
    }
  }

#endif
