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

#include "Firestore/core/src/firebase/firestore/api/collection_reference.h"

#import "Firestore/Source/Core/FSTQuery.h"

#include "Firestore/core/src/firebase/firestore/api/document_reference.h"
#include "Firestore/core/src/firebase/firestore/api/input_validation.h"
#include "Firestore/core/src/firebase/firestore/model/document_key.h"
#include "Firestore/core/src/firebase/firestore/model/resource_path.h"
#include "Firestore/core/src/firebase/firestore/util/autoid.h"
#include "Firestore/core/src/firebase/firestore/util/hashing.h"
#include "Firestore/core/src/firebase/firestore/util/string_apple.h"

namespace util = firebase::firestore::util;
using firebase::firestore::api::ThrowInvalidArgument;
using firebase::firestore::model::DocumentKey;
using firebase::firestore::model::ResourcePath;

namespace firebase {
namespace firestore {
namespace api {

namespace {

FSTQuery* MakeQuery(model::ResourcePath path) {
  if (path.size() % 2 != 1) {
    ThrowInvalidArgument("Invalid collection reference. Collection references must have an odd number of segments, but %s has %s", path.CanonicalString(), path.size());
  }

  return [FSTQuery queryWithPath:path];
}

}  // namespace

CollectionReference::CollectionReference(model::ResourcePath path, std::shared_ptr<Firestore> firestore)
    : Query(MakeQuery(path), std::move(firestore)) {
}

bool operator==(const CollectionReference& lhs, const CollectionReference& rhs) {
  return lhs.firestore() == rhs.firestore() && objc::Equals(lhs.query(), rhs.query());
}

size_t CollectionReference::Hash() const {
  return util::Hash(firestore().get(), query());
}

std::string CollectionReference::collection_id() const {
  return query().path.last_segment();
}

absl::optional<DocumentReference> CollectionReference::parent() const {
  const ResourcePath parentPath = query().path.PopLast();
  if (parentPath.empty()) {
    return absl::nullopt;
  } else {
    DocumentKey key{parentPath};
    return DocumentReference(std::move(key), firestore());
  }
}

std::string CollectionReference::path() const {
  return query().path.CanonicalString();
}

DocumentReference CollectionReference::Document(absl::string_view document_path) const {
  ResourcePath sub_path = ResourcePath::FromString(document_path);
  ResourcePath path = query().path.Append(sub_path);
  return DocumentReference(std::move(path), firestore());
}

DocumentReference CollectionReference::AddDocument(core::ParsedSetData&& data, util::StatusCallback callback) const {
  DocumentReference doc_ref = Document();
  doc_ref.SetData(std::move(data), callback);
  return doc_ref;
}

DocumentReference CollectionReference::Document() const {
  DocumentKey key(query().path.Append(util::CreateAutoId()));
  return DocumentReference(std::move(key), firestore());
}

}  // namespace api
}  // namespace firestore
}  // namespace firebase
