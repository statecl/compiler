#!/bin/bash
set -euo pipefail

FMT_VERSION="${FMT_VERSION:-11.0.2}"
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

git clone --depth 1 --branch "$FMT_VERSION" https://github.com/fmtlib/fmt.git /tmp/fmt
cd /tmp/fmt

CMAKE_ARGS=(
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    -DFMT_TEST=OFF
    -DFMT_DOC=OFF
    -DBUILD_SHARED_LIBS="$SHARED"
)

if [ "$SANITIZER" != "off" ]; then
    CMAKE_ARGS+=(
        -DCMAKE_CXX_FLAGS="$SANITIZER_FLAGS -g -O1"
        -DCMAKE_EXE_LINKER_FLAGS="$SANITIZER_FLAGS"
        -DCMAKE_SHARED_LINKER_FLAGS="$SANITIZER_FLAGS"
    )
fi

cmake -S . -B build "${CMAKE_ARGS[@]}"
cmake --build build --target install --parallel 2
rm -rf /tmp/fmt
