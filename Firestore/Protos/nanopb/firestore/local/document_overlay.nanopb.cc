/*
 * Copyright 2022 Google LLC
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

/* Automatically generated nanopb constant definitions */
/* Generated by nanopb-0.3.9.8 */

#include "document_overlay.nanopb.h"

#include "Firestore/core/src/nanopb/pretty_printing.h"

namespace firebase {
namespace firestore {

using nanopb::PrintEnumField;
using nanopb::PrintHeader;
using nanopb::PrintMessageField;
using nanopb::PrintPrimitiveField;
using nanopb::PrintTail;

/* @@protoc_insertion_point(includes) */
#if PB_PROTO_HEADER_VERSION != 30
#error Regenerate this file with the current version of nanopb generator.
#endif



const pb_field_t firestore_client_DocumentOverlay_fields[3] = {
    PB_FIELD(  1, INT32   , SINGULAR, STATIC  , FIRST, firestore_client_DocumentOverlay, largest_batch_id, largest_batch_id, 0),
    PB_FIELD(  2, MESSAGE , SINGULAR, STATIC  , OTHER, firestore_client_DocumentOverlay, overlay_mutation, largest_batch_id, &google_firestore_v1_Write_fields),
    PB_LAST_FIELD
};


/* Check that field information fits in pb_field_t */
#if !defined(PB_FIELD_32BIT)
/* If you get an error here, it means that you need to define PB_FIELD_32BIT
 * compile-time option. You can do that in pb.h or on compiler command line.
 *
 * The reason you need to do this is that some of your messages contain tag
 * numbers or field sizes that are larger than what can fit in 8 or 16 bit
 * field descriptors.
 */
PB_STATIC_ASSERT((pb_membersize(firestore_client_DocumentOverlay, overlay_mutation) < 65536), YOU_MUST_DEFINE_PB_FIELD_32BIT_FOR_MESSAGES_firestore_client_DocumentOverlay)
#endif

#if !defined(PB_FIELD_16BIT) && !defined(PB_FIELD_32BIT)
/* If you get an error here, it means that you need to define PB_FIELD_16BIT
 * compile-time option. You can do that in pb.h or on compiler command line.
 *
 * The reason you need to do this is that some of your messages contain tag
 * numbers or field sizes that are larger than what can fit in the default
 * 8 bit descriptors.
 */
PB_STATIC_ASSERT((pb_membersize(firestore_client_DocumentOverlay, overlay_mutation) < 256), YOU_MUST_DEFINE_PB_FIELD_16BIT_FOR_MESSAGES_firestore_client_DocumentOverlay)
#endif


std::string firestore_client_DocumentOverlay::ToString(int indent) const {
    std::string header = PrintHeader(indent, "DocumentOverlay", this);
    std::string result;

    result += PrintPrimitiveField("largest_batch_id: ",
        largest_batch_id, indent + 1, false);
    result += PrintMessageField("overlay_mutation ",
        overlay_mutation, indent + 1, false);

    std::string tail = PrintTail(indent);
    return header + result + tail;
}

}  // namespace firestore
}  // namespace firebase

/* @@protoc_insertion_point(eof) */
