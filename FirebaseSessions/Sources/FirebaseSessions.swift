// Copyright 2022 Google LLC
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

import FirebaseCore
import FirebaseInstallations

// Avoids exposing internal FirebaseCore APIs to Swift users.
@_implementationOnly import FirebaseCoreExtension

@objc(FIRSessionsProvider)
protocol SessionsProvider {
  @objc static func sessions() -> Void
}

@objc(FIRSessions) final class Sessions: NSObject, Library, SessionsProvider {
  // MARK: - Private Variables

  /// The Firebase App ID associated with Sessions.
  private let appID: String

  /// Top-level Classes in the Sessions SDK
  private let coordinator: Coordinator
  private let initiator: Initiator
  private let identifiers: Identifiers

  // MARK: - Initializers

  required convenience init(appID: String, installationIDProvider: InstallationIDProvider) {
    let identifiers = Identifiers(installationIDProvider: installationIDProvider)
    let coordinator = Coordinator(identifiers: identifiers)
    let initiator = Initiator()

    self.init(appID: appID,
              identifiers: identifiers,
              coordinator: coordinator,
              initiator: initiator)
  }

  init(appID: String, identifiers: Identifiers, coordinator: Coordinator, initiator: Initiator) {
    self.appID = appID

    self.identifiers = identifiers
    self.coordinator = coordinator
    self.initiator = initiator

    super.init()

    self.initiator.beginListening {
      self.identifiers.generateNewSessionID()
      self.coordinator.runMain()
    }
  }

  // MARK: - Library conformance

  static func componentsToRegister() -> [Component] {
    return [Component(SessionsProvider.self,
                      instantiationTiming: .alwaysEager,
                      dependencies: []) { container, isCacheable in
        // Sessions SDK only works for the default app
        guard let app = container.app, app.isDefaultApp else { return nil }
        isCacheable.pointee = true
        let installations = Installations.installations(app: app)
        return self.init(appID: app.options.googleAppID, installationIDProvider: installations)
      }]
  }

  // MARK: - SessionsProvider conformance

  static func sessions() {}
}
