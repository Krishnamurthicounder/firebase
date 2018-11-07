# Copyright 2018 Google
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

# Adds cheap tests for various compilers, and any global compiler setup
# required across all dependencies.

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  set(CXX_CLANG TRUE)
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  set(CXX_GNU TRUE)
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  # Disable the C++11 ABI introduced in GCC 5 for compatibility with Firebase
  # C++, which is still compiled with GCC 4.
  #
  # Note that this is set here rather than in compiler_setup.cmake so that it
  # applies to all subdirectory builds, including all external dependencies.
  #
  # TODO(b/119137881): Remove this when Firebase C++ built with GCC 5.
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_GLIBCXX_USE_CXX11_ABI=0")
endif()
