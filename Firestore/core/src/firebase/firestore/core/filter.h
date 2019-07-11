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

#ifndef FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_CORE_FILTER_H_
#define FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_CORE_FILTER_H_

#include <memory>
#include <string>

#include "Firestore/core/src/firebase/firestore/model/document.h"
#include "Firestore/core/src/firebase/firestore/model/field_path.h"
#include "Firestore/core/src/firebase/firestore/model/field_value.h"

namespace firebase {
namespace firestore {
namespace core {

/** Interface used for all query filters. All filters are immutable. */
class Filter {
 public:
  /**
   * Operator is a value relation operator that can be used to filter documents.
   * It is similar to NSPredicateOperatorType, but only has operators supported
   * by Firestore.
   */
  enum class Operator {
    LessThan,
    LessThanOrEqual,
    Equal,
    GreaterThanOrEqual,
    GreaterThan,
    ArrayContains,
  };

  // For lack of RTTI, all subclasses must identify themselves so that
  // comparisons properly take type into account.
  enum class Type {
    kRelationFilter,
    kNanFilter,
    kNullFilter,
  };

  /**
   * Creates a Filter instance for the provided path, operator, and value.
   *
   * Note that if the relational operator is Equal and the value is NullValue or
   * NaN, then this will return the appropriate NullFilter or NanFilter class
   * instead of a RelationFilter.
   */
  static std::shared_ptr<Filter> Create(model::FieldPath path,
                                        Operator op,
                                        model::FieldValue value_rhs);

  virtual ~Filter() = default;

  virtual Type type() const = 0;

  /** Returns the field the Filter operates over. */
  virtual const model::FieldPath& field() const = 0;

  /** Returns true if a document matches the filter. */
  virtual bool Matches(const model::Document& doc) const = 0;

  /** A unique ID identifying the filter; used when serializing queries. */
  virtual std::string CanonicalId() const = 0;

  friend bool operator==(const Filter& lhs, const Filter& rhs) {
    return lhs.Equals(rhs);
  }

 protected:
  virtual bool Equals(const Filter& other) const = 0;
};

inline bool operator!=(const Filter& lhs, const Filter& rhs) {
  return !(lhs == rhs);
}

}  // namespace core
}  // namespace firestore
}  // namespace firebase

#endif  // FIRESTORE_CORE_SRC_FIREBASE_FIRESTORE_CORE_FILTER_H_
