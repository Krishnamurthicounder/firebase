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

#import "FIROAuthCredential.h"

#import "FIRAuthCredential_Internal.h"
#import "FIRAuthExceptionUtils.h"
#import "FIROAuthCredential_Internal.h"
#import "FIRVerifyAssertionRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface FIROAuthCredential ()

- (nullable instancetype)initWithProvider:(NSString *)provider NS_UNAVAILABLE;

@end

@implementation FIROAuthCredential

- (nullable instancetype)initWithProvider:(NSString *)provider {
  [FIRAuthExceptionUtils raiseMethodNotImplementedExceptionWithReason:
      @"Please call the designated initializer."];
  return nil;
}

- (instancetype)initWithProviderID:(NSString *)providerID
                           IDToken:(nullable NSString *)IDToken
                       accessToken:(nullable NSString *)accessToken
                      pendingToken:(nullable NSString *)pendingToken
                            secret:(nullable NSString *)secret {
  self = [super initWithProvider:providerID];
  if (self) {
    _IDToken = IDToken;
    _accessToken = accessToken;
    _pendingToken = pendingToken;
    _secret = secret;
  }
  return self;
}

- (instancetype)initWithProviderID:(NSString *)providerID
                         sessionID:(NSString *)sessionID
            OAuthResponseURLString:(NSString *)OAuthResponseURLString {
  self =
      [self initWithProviderID:providerID IDToken:nil accessToken:nil pendingToken:nil secret:nil];
  if (self) {
    _OAuthResponseURLString = OAuthResponseURLString;
    _sessionID = sessionID;
  }
  return self;
}

- (void)prepareVerifyAssertionRequest:(FIRVerifyAssertionRequest *)request {
  request.providerIDToken = _IDToken;
  request.providerAccessToken = _accessToken;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSString *IDToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"IDToken"];
  NSString *accessToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"accessToken"];
  NSString *pendingToken = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"pendingToken"];
  NSString *secret = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"secret"];
  self = [self initWithProviderID:self.provider
                          IDToken:IDToken
                      accessToken:accessToken
                     pendingToken:pendingToken
                           secret:secret];
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.IDToken forKey:@"IDToken"];
  [aCoder encodeObject:self.accessToken forKey:@"accessToken"];
  [aCoder encodeObject:self.pendingToken forKey:@"pendingToken"];
  [aCoder encodeObject:self.secret forKey:@"secret"];
}

@end

NS_ASSUME_NONNULL_END
