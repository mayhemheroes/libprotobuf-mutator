# Copyright 2017 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set(EXPAT_TARGET external.expat)
set(EXPAT_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/${EXPAT_TARGET})
set(EXPAT_SRC_DIR ${EXPAT_INSTALL_DIR}/src/${EXPAT_TARGET}/expat)

set(EXPAT_INCLUDE_DIRS ${EXPAT_INSTALL_DIR}/include/)
include_directories(${EXPAT_INCLUDE_DIRS})

list(APPEND EXPAT_LIBRARIES expat)

foreach(lib IN LISTS EXPAT_LIBRARIES)
  list(APPEND EXPAT_BUILD_BYPRODUCTS ${EXPAT_INSTALL_DIR}/lib/lib${lib}.a)

  add_library(${lib} STATIC IMPORTED)
  set_property(TARGET ${lib} PROPERTY IMPORTED_LOCATION
               ${EXPAT_INSTALL_DIR}/lib/lib${lib}.a)
  add_dependencies(${lib} ${EXPAT_TARGET})
endforeach(lib)

set(EXPAT_C_COMPILER "${CMAKE_C_COMPILER}")
set(EXPAT_CXX_COMPILER "${CMAKE_CXX_COMPILER}")
if(DEFINED CMAKE_C_COMPILER_LAUNCHER AND DEFINED CMAKE_CXX_COMPILER_LAUNCHER)
  set(EXPAT_C_COMPILER "${CMAKE_C_COMPILER_LAUNCHER} ${EXPAT_C_COMPILER}")
  set(EXPAT_CXX_COMPILER "${CMAKE_CXX_COMPILER_LAUNCHER} ${EXPAT_CXX_COMPILER}")
endif()

# NOTE: Fuzzer "expat_example" is being used for actual fuzzing in OSS-Fuzz.
#       We want a rock-solid build by default (hence the pinning to a
#       specific version) but also be fuzzing the very latest in OSS-Fuzz.
if (LIB_PROTO_MUTATOR_EXAMPLES_USE_LATEST)
  set(EXPAT_GIT_TAG "master")
else()
  set(EXPAT_GIT_TAG "R_2_6_4")
endif()

include (ExternalProject)
ExternalProject_Add(${EXPAT_TARGET}
    PREFIX ${EXPAT_TARGET}
    GIT_REPOSITORY https://github.com/libexpat/libexpat
    GIT_TAG ${EXPAT_GIT_TAG}
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND cd ${EXPAT_SRC_DIR} && ./buildconf.sh  && ./configure
                                                    --prefix=${EXPAT_INSTALL_DIR}
                                                    --without-xmlwf
                                                    "CC=${EXPAT_C_COMPILER}"
                                                    "CXX=${EXPAT_CXX_COMPILER}"
                                                    "CFLAGS=${EXPAT_CFLAGS} -w -DXML_POOR_ENTROPY"
                                                    "CXXFLAGS=${EXPAT_CXXFLAGS} -w -DXML_POOR_ENTROPY"
    BUILD_COMMAND cd ${EXPAT_SRC_DIR} &&  make -j ${CPU_COUNT}
    INSTALL_COMMAND cd ${EXPAT_SRC_DIR} &&  make install
    BUILD_BYPRODUCTS ${EXPAT_BUILD_BYPRODUCTS}
)
