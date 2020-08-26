#!/usr/bin/env bash

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# USAGE: test_archiving.sh pod platform outputPath
#
# Generates the project for the given CocoaPod and attempts to archive it to the provided
# path. The platform argument also supports "catalyst" which will archive an iOS app
# built for Mac Catalyst.

set -xeuo pipefail

echo "Running with arguments: $@"

pod="$1"
platform="$2"
output_path="$3"

# watchOS is unsupported - `pod gen` can't generate the test schemes.
case "$platform" in
  ios)
  scheme_name="App-iOS"
  ;;

  macos | catalyst)
  scheme_name="App-macOS"
  ;;

  tvos)
  scheme_name="App-tvOS"
  ;;

  # Fail for anything else, invalid input.
  *)
  exit 1;
  ;;
esac

if [ "$platform" = "catalyst" ]; then
    pod_gen_platform="ios"
else
    pod_gen_platform="$platform"
fi

bundle exec pod gen --local-sources=./ --sources=https://github.com/firebase/SpecsStaging.git,https://cdn.cocoapods.org/ \
  "$pod".podspec --platforms="$pod_gen_platform"

args=(
  # Run the `archive` command.
  "archive"
  # Write the archive to a given path.
  "-archivePath" "$output_path"
  # The generated workspace.
  "-workspace" "gen/$pod/$pod.xcworkspace"
  # Specify the generated App scheme.
  "-scheme" "$scheme_name"
  # Disable signing.
  "CODE_SIGN_IDENTITY=-" "CODE_SIGNING_REQUIRED=NO" "CODE_SIGNING_ALLOWED=NO"
)

if [ "$platform" = "catalyst" ]; then
    args+=(
      # Specify Catalyst.
      "ARCHS=x86_64h" "VALID_ARCHS=x86_64h" "SUPPORTS_MACCATALYST=YES"
      # Run on macOS.
      "-sdk" "macosx" "-destination platform=\"OS X\"" "TARGETED_DEVICE_FAMILY=2"
    )
fi

xcodebuild -version
xcodebuild "${args[@]}" | xcpretty
