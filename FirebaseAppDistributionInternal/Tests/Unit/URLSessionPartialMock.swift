// Copyright 2023 Google LLC
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

// Create a partial mock by subclassing the URLSessionDataTask.
class URLSessionDataTaskMock: URLSessionDataTask {
  private let closure: () -> Void

  init(closure: @escaping () -> Void) {
    self.closure = closure
  }

  override func resume() {
    closure()
  }
}

class URLSessionMock: URLSession {
  typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
  
  private let mockReleases = [
    "releases" : [
      [
        "displayVersion" : "1.0.0",
        "buildVersion" : "111",
        "releaseNotes" : "This is a release",
        "downloadURL" : "http://faketyfakefake.download"
      ],
      [
        "latest" : true,
        "displayVersion" : "1.0.1",
        "buildVersion" : "112",
        "releaseNotes" : "This is a release too",
        "downloadURL" : "http://faketyfakefake.download"
      ]
    ]
  ];

  // Properties to control what gets returned to the URLSession callback.
  // error could also be added here.
  var data: Data?
  var response: URLResponse?

  override func dataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
    let data = try! JSONSerialization.data(withJSONObject: mockReleases)
    let response = HTTPURLResponse(url: request.url!,
                                   statusCode: 200,
                                   httpVersion: nil,
                                   headerFields: nil)
    return URLSessionDataTaskMock {
      completionHandler(data, response, nil)
    }
  }
}
