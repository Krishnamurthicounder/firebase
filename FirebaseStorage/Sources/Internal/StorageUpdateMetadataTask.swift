/// Copyright 2022 Google LLC
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

import Foundation

import FirebaseStorageInternal
#if COCOAPODS
  import GTMSessionFetcher
#else
  import GTMSessionFetcherCore
#endif

/**
 * Task which provides the ability to delete an object in Firebase Storage.
 */
internal class StorageUpdateMetadataTask: StorageTask, StorageTaskManagement {
  private var fetcher: GTMSessionFetcher?
  private var fetcherCompletion: ((Data?, NSError?) -> Void)?
  private var completion: ((_ metadata: StorageMetadata?, _: Error?) -> Void)?
  private var updateMetadata: FIRIMPLStorageMetadata

  internal init(reference: FIRIMPLStorageReference,
                fetcherService: GTMSessionFetcherService,
                queue: DispatchQueue,
                metadata: FIRIMPLStorageMetadata,
                completion: ((_: StorageMetadata?, _: Error?) -> Void)?) {
    self.updateMetadata = metadata
    super.init(reference: reference, service: fetcherService, queue: queue)
    self.completion = completion
  }

  deinit {
    self.fetcher?.stopFetching()
  }

  /**
   * Prepares a task and begins execution.
   */
  internal func enqueue() {
    weak var weakSelf = self
    DispatchQueue.global(qos: .background).async {
      guard let strongSelf = weakSelf else {
        return
      }
      var request = strongSelf.baseRequest
      let updateDictionary = strongSelf.updateMetadata.updatedMetadata()
      let updateData = try? JSONSerialization.data(withJSONObject: updateDictionary)
      request.httpMethod = "PATCH"
      request.timeoutInterval = strongSelf.reference.storage.maxOperationRetryTime
      request.httpBody = updateData
      request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
      if let count = updateData?.count {
        request.setValue("\(count)", forHTTPHeaderField: "Content-Length")
      }

      let callback = strongSelf.completion
      strongSelf.completion = nil

      let fetcher = strongSelf.fetcherService.fetcher(with: request)
      fetcher.comment = "GetMetadataTask"
      strongSelf.fetcher = fetcher

      strongSelf.fetcherCompletion = { (data: Data?, error: NSError?) in
        var metadata: StorageMetadata? = nil
        if (error != nil) {
          if self.error == nil {
          // TODO:
          // self.error = [FIRStorageErrors errorWithServerError:error reference:self.reference];
          }
        } else {
          if let data = data ,
             let responseDictionary = try? JSONSerialization
            .jsonObject(with: data) as? [String: Any] {
            metadata = StorageMetadata(dictionary: responseDictionary)
            metadata?.impl.type = .file
          } else {
            // TODO
            // self.error = [FIRStorageErrors errorWithInvalidRequest:data];
          }
        }
        if let callback = callback {
          callback(metadata, self.error)
        }
        self.fetcherCompletion = nil
      }
      
      fetcher.comment = "UpdateMetadataTask"

      strongSelf.fetcher?.beginFetch { data, error in
        let strongSelf = weakSelf
        if let fetcherCompletion = strongSelf?.fetcherCompletion {
          fetcherCompletion(data, error as? NSError)
        }
      }
    }
  }
}
