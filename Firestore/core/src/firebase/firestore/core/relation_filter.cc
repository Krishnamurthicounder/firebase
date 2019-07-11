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

#include "Firestore/core/src/firebase/firestore/core/relation_filter.h"

#include <utility>
#include <vector>

#include "absl/algorithm/container.h"
#include "absl/strings/str_cat.h"
#include "absl/types/optional.h"

namespace firebase {
namespace firestore {
namespace core {

using model::FieldPath;
using model::FieldValue;

namespace {

const char* Describe(Filter::Operator op) {
  switch (op) {
    case Filter::Operator::LessThan:
      return "<";
    case Filter::Operator::LessThanOrEqual:
      return "<=";
    case Filter::Operator::Equal:
      return "==";
    case Filter::Operator::GreaterThanOrEqual:
      return ">=";
    case Filter::Operator::GreaterThan:
      return ">";
    case Filter::Operator::ArrayContains:
      return "array_contains";
  }

  UNREACHABLE();
}

}  // namespace

RelationFilter::RelationFilter(FieldPath field,
                               Operator op,
                               FieldValue value_rhs)
    : field_(std::move(field)), op_(op), value_rhs_(std::move(value_rhs)) {
}

const FieldPath& RelationFilter::field() const {
  return field_;
}

bool RelationFilter::Matches(const model::Document& doc) const {
  if (field_.IsKeyFieldPath()) {
    // TODO(rsgowman): Port this case
    abort();
  } else {
    absl::optional<FieldValue> doc_field_value = doc.field(field_);
    return doc_field_value && MatchesValue(doc_field_value.value());
  }
}

bool RelationFilter::MatchesValue(const FieldValue& other) const {
  if (op_ == Filter::Operator::ArrayContains) {
    if (other.type() != FieldValue::Type::Array) return false;

    const std::vector<FieldValue>& contents = other.array_value();
    return absl::c_linear_search(contents, value_rhs_);
  } else {
    // Only compare types with matching backend order (such as double and int).
    return FieldValue::Comparable(other.type(), value_rhs_.type()) &&
           MatchesComparison(other);
  }
}

bool RelationFilter::MatchesComparison(const FieldValue& other) const {
  switch (op_) {
    case Operator::LessThan:
      return other < value_rhs_;
    case Operator::LessThanOrEqual:
      return other <= value_rhs_;
    case Operator::Equal:
      return other == value_rhs_;
    case Operator::GreaterThan:
      return other > value_rhs_;
    case Operator::GreaterThanOrEqual:
      return other >= value_rhs_;
    case Operator::ArrayContains:
      HARD_FAIL("Should have been handled in MatchesValue()");
  }
  UNREACHABLE();
}

std::string RelationFilter::CanonicalId() const {
  return absl::StrCat(field_.CanonicalString(), Describe(op_),
                      value_rhs_.ToString());
}

bool RelationFilter::Equals(const Filter& other) const {
  if (other.type() != Type::kRelationFilter) return false;

  const auto& other_filter = static_cast<const RelationFilter&>(other);
  return op_ == other_filter.op_ && field_ == other_filter.field_ &&
         value_rhs_ == other_filter.value_rhs_;
}

}  // namespace core
}  // namespace firestore
}  // namespace firebase
