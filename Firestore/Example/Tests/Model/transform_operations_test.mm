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

#include "Firestore/core/src/firebase/firestore/model/transform_operations.h"

#include "Firestore/core/src/firebase/firestore/model/field_value.h"
#include "Firestore/core/test/firebase/firestore/testutil/testutil.h"
#include "gtest/gtest.h"

namespace firebase {
namespace firestore {
namespace model {

using testutil::Value;

using Type = TransformOperation::Type;

TEST(TransformOperationsTest, ServerTimestamp) {
  ServerTimestampTransform transform = ServerTimestampTransform::Get();
  EXPECT_EQ(Type::ServerTimestamp, transform.type());

  ServerTimestampTransform another = ServerTimestampTransform::Get();
  NumericIncrementTransform other(Value(1));
  EXPECT_EQ(transform, another);
  EXPECT_NE(transform, other);
}

// TODO(mikelehen): Add ArrayTransform test once it no longer depends on
// FSTFieldValue and can be exposed to C++ code.

}  // namespace model
}  // namespace firestore
}  // namespace firebase
