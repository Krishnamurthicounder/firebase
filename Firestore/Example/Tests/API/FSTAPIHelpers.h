/*
 * Copyright 2017 Google
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

#import <Foundation/Foundation.h>

#import "FirebaseFirestore/FIRCollectionReference.h"
#import "FirebaseFirestore/FIRDocumentSnapshot.h"
#import "FirebaseFirestore/FIRFirestore.h"
#import "FirebaseFirestore/FIRQuerySnapshot.h"

#import "Firestore/Example/Tests/Util/FSTHelpers.h"

NS_ASSUME_NONNULL_BEGIN

#if __cplusplus
extern "C" {
#endif

/** A convenience method for creating dummy singleton FIRFirestore for tests. */
FIRFirestore *FSTTestFirestore();

/** A convenience method for creating a doc snapshot for tests. */
FIRDocumentSnapshot *FSTTestDocSnapshot(NSString *path,
                                        FSTTestSnapshotVersion version,
                                        NSDictionary<NSString *, id> *data,
                                        BOOL hasMutations,
                                        BOOL fromCache);

/** A convenience method for creating a collection reference from a path string. */
FIRCollectionReference *FSTTestCollectionRef(NSString *path);

/** A convenience method for creating a document reference from a path string. */
FIRDocumentReference *FSTTestDocRef(NSString *path);

/**
 * A convenience method for creating a particular query snapshot for tests.
 *
 * @param path To be used in constructing the query.
 * @param oldDocs Provides data to construct the query snapshot in the past. It maps each key to a
 * document. The key is the document's path relative to the query path.
 * @param DocsToAdd Specifies data to be added into the query snapshot as of now. It maps each key
 * to a document. The key is the document's path relative to the query path.
 * @param hasPendingWrites Whether the query snapshot has pending writes to the server.
 * @param fromCache Whether the query snapshot is cache result.
 * @returns A query snapshot that consists of both sets of documents.
 */
FIRQuerySnapshot *FSTTestQuerySnapshot(
    NSString *path,
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *oldDocs,
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *DocsToAdd,
    BOOL hasPendingWrites,
    BOOL fromCache);

#if __cplusplus
}  // extern "C"
#endif

NS_ASSUME_NONNULL_END
