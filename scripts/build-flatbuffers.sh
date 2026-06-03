#!/bin/bash
set -euo pipefail

FLATBUFFERS_VERSION="${FLATBUFFERS_VERSION:-v23.5.26}"
BUILD_VARIANT="${BUILD_VARIANT:-Release}"
SANITIZER="${SANITIZER:-off}"

SHARED=OFF
CMAKE_BUILD_TYPE="$BUILD_VARIANT"

if [ "$SANITIZER" != "off" ]; then
    CMAKE_BUILD_TYPE="Debug"
    SHARED=ON
    case "$SANITIZER" in
        asan)  SANITIZER_FLAGS="-fsanitize=address -fno-omit-frame-pointer" ;;
        tsan)  SANITIZER_FLAGS="-fsanitize=thread" ;;
        ubsan) SANITIZER_FLAGS="-fsanitize=undefined" ;;
        *)     echo "Unknown sanitizer: $SANITIZER"; exit 1 ;;
    esac
elif [ "$BUILD_VARIANT" = "Debug" ]; then
    SHARED=ON
fi

git clone --depth 1 --branch "$FLATBUFFERS_VERSION" https://github.com/google/flatbuffers.git /tmp/flatbuffers
cd /tmp/flatbuffers

CMAKE_ARGS=(
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    -DFLATBUFFERS_BUILD_TESTS=OFF
    -DFLATBUFFERS_BUILD_SHAREDLIB="$SHARED"
)

if [ "$SANITIZER" != "off" ]; then
    CMAKE_ARGS+=(
        -DCMAKE_CXX_FLAGS="$SANITIZER_FLAGS -g -O1"
        -DCMAKE_EXE_LINKER_FLAGS="$SANITIZER_FLAGS"
        -DCMAKE_SHARED_LINKER_FLAGS="$SANITIZER_FLAGS"
    )
fi

cmake -S . -B build "${CMAKE_ARGS[@]}"
cmake --build build --target install --parallel "$(nproc)"
rm -rf /tmp/flatbuffers
