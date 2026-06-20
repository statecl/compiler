#!/bin/bash
set -euo pipefail

RE2_VERSION="${RE2_VERSION:-2025-11-05}"
ABSEIL_VERSION="${ABSEIL_VERSION:-20250127.2}"
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

# Build Abseil (RE2 dependency) - without sanitizer flags to avoid
# constexpr issues in Abseil with GCC + UBSan (hash_policy_traits.h)
ABSEIL_BUILD_TYPE="$CMAKE_BUILD_TYPE"
ABSEIL_SHARED="$SHARED"
if [ "$SANITIZER" != "off" ]; then
    ABSEIL_BUILD_TYPE="Debug"
    ABSEIL_SHARED=ON
fi
git clone --depth 1 --branch "$ABSEIL_VERSION" https://github.com/abseil/abseil-cpp.git /tmp/abseil
cd /tmp/abseil
cmake -S . -B build \
    -DCMAKE_BUILD_TYPE="$ABSEIL_BUILD_TYPE" \
    -DBUILD_SHARED_LIBS="$ABSEIL_SHARED" \
    -DABSL_BUILD_TESTING=OFF \
    -DABSL_USE_GOOGLETEST_HEAD=OFF
cmake --build build --target install --parallel 2
cd /
rm -rf /tmp/abseil
ldconfig 2>/dev/null || true  # Update linker cache for Abseil shared libs

# Build RE2 (without sanitizer flags to avoid
# constexpr issues in Abseil with GCC + UBSan (hash_policy_traits.h))
git clone --depth 1 --branch "$RE2_VERSION" https://github.com/google/re2.git /tmp/re2
cd /tmp/re2

CMAKE_ARGS=(
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    -DRE2_BUILD_TESTING=OFF
    -DBUILD_SHARED_LIBS="$SHARED"
)

cmake -S . -B build "${CMAKE_ARGS[@]}"
cmake --build build --target install --parallel 2
cd /
rm -rf /tmp/re2
