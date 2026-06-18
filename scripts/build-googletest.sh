#!/bin/bash
set -euo pipefail

GTEST_VERSION="${GTEST_VERSION:-03597a01ee50ed33e9dfd640b249b4be3799d395}"
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

wget -q "https://github.com/google/googletest/archive/$GTEST_VERSION.zip" -O /tmp/googletest.zip
cd /tmp
unzip -q googletest.zip
mv "googletest-$GTEST_VERSION" googletest
cd googletest

CMAKE_ARGS=(
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    -DBUILD_GMOCK=ON
    -DBUILD_SHARED_LIBS="$SHARED"
    -DINSTALL_GTEST=ON
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
rm -rf /tmp/googletest /tmp/googletest.zip
