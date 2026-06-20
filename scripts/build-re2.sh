#!/bin/bash
set -euo pipefail

RE2_VERSION="${RE2_VERSION:-2024-07-02}"
ABSEIL_VERSION="${ABSEIL_VERSION:-20240722.2}"
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

SANITIZER_CMAKE=()
if [ "$SANITIZER" != "off" ]; then
    SANITIZER_CMAKE+=(
        -DCMAKE_CXX_FLAGS="$SANITIZER_FLAGS -g -O1"
        -DCMAKE_EXE_LINKER_FLAGS="$SANITIZER_FLAGS"
        -DCMAKE_SHARED_LINKER_FLAGS="$SANITIZER_FLAGS"
    )
fi

# Build Abseil (RE2 dependency)
git clone --depth 1 --branch "$ABSEIL_VERSION" https://github.com/abseil/abseil-cpp.git /tmp/abseil
cd /tmp/abseil
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
    -DBUILD_SHARED_LIBS="$SHARED" \
    -DABSL_BUILD_TESTING=OFF \
    -DABSL_USE_GOOGLETEST_HEAD=OFF \
    "${SANITIZER_CMAKE[@]}"
cmake --build build --target install --parallel 2
rm -rf /tmp/abseil

# Build RE2
git clone --depth 1 --branch "$RE2_VERSION" https://github.com/google/re2.git /tmp/re2
cd /tmp/re2

CMAKE_ARGS=(
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    -DRE2_BUILD_TESTING=OFF
    -DBUILD_SHARED_LIBS="$SHARED"
    "${SANITIZER_CMAKE[@]}"
)

cmake -S . -B build "${CMAKE_ARGS[@]}"
cmake --build build --target install --parallel 2
rm -rf /tmp/re2
