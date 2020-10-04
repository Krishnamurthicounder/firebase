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

import Foundation
import FirebaseDatabase

extension Database.Decoder {
    public static var defaultDecoder: () -> Database.Decoder = {
        .init()
    }
}

extension DataSnapshot {
  /// Retrieves the value of a snapshot and converts it to an instance of
  /// caller-specified type.
  /// Throws `Database.DecodingError.valueDoesNotExist`
  /// if the document does not exist.
  ///
  /// See `Database.Decoder` for more details about the decoding process.
  ///
  /// - Parameters
  ///   - type: The type to convert the document fields to.
  ///   - decoder: The decoder to use to convert the document. Defaults to use
  ///              default decoder.
  public func data<T: Decodable>(as type: T.Type,
                                 decoder: Database.Decoder = Database.Decoder.defaultDecoder()) throws -> T {
    guard let value = value else {
      throw Database.DecodingError.valueDoesNotExist(path: self.ref.url, type: T.self)
    }
    return try decoder.decode(T.self, from: value)
  }
}
