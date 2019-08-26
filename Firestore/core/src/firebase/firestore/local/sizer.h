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

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_LOCAL_SIZER_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_LOCAL_SIZER_H_

#include <cstddef>

namespace firebase {
namespace firestore {
namespace model {

class MaybeDocument;

}  // namespace model
namespace local {

class QueryData;

/**
 * Estimates the stored size of documents and queries.
 */
class Sizer {
 public:
  virtual ~Sizer() = default;

  /**
   * Calculates the size of the given maybe_doc in bytes. Note that even
   * NoDocuments have an associated size.
   */
  virtual size_t CalculateByteSize(
      const model::MaybeDocument& maybe_doc) const = 0;

  /**
   * Calculates the size of the given query_data in bytes.
   */
  virtual size_t CalculateByteSize(const QueryData& query_data) const = 0;
};

}  // namespace local
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_LOCAL_SIZER_H_
