/*
 * Copyright 2020 Google
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

import XCTest
import FirebaseCore
import FirebaseAppAttestation

class AppAttestationTests: XCTestCase {
  func testExample() {
    AppAttestation.setAttestationProviderFactory(self)
    FirebaseApp.configure()

    AppAttestation.setAttestationProviderFactory(self, forAppName: "AppName")
    let firebaseOptions = FirebaseOptions(contentsOfFile: "path")!
    FirebaseApp.configure(name: "AppName", options: firebaseOptions)

    let defaultAppAttestation = AppAttestation.appAttestation()

    guard
      let app = FirebaseApp.app(name: "AppName"),
      let secondAppAttestation = AppAttestation.appAttestation(app: app)
    else {
      return
    }

    defaultAppAttestation.getToken(completion: { result, error in
      guard let result = result else {
        print("Error: \(String(describing: error))")
        return
      }

      print("Token: \(result.token)")
    })
  }
}

class DummyAttestationProvider: NSObject, AppAttestationProvider {
  func getToken(completion handler: @escaping AppAttestationTokenHandler) {
    handler(AppAttestationToken(token: "token", expirationDate: .distantFuture), nil)
  }
}

extension AppAttestationTests: AppAttestationProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppAttestationProvider? {
    return DummyAttestationProvider()
  }
}
