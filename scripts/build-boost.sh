#!/bin/bash
set -euo pipefail

BOOST_VERSION="${BOOST_VERSION:-1.92.0}"
BUILD_VARIANT="${BUILD_VARIANT:-Release}"
SANITIZER="${SANITIZER:-off}"

# Boost.Build (bootstrap.sh / b2) ignora CC/CXX.  Ponemos el directorio
# del compilador al inicio del PATH para que encuentre g++ correcto.
if [ -n "${CXX:-}" ]; then
    CXX_DIR="$(dirname "$CXX" 2>/dev/null)"
    if [ "$CXX_DIR" != "." ] && [ -d "$CXX_DIR" ] && [[ ":$PATH:" != *":$CXX_DIR:"* ]]; then
        export PATH="$CXX_DIR:$PATH"
    fi
fi

BOOST_LIBS="--with-json --with-program_options --with-charconv"
BOOST_VERSION_DASH="${BOOST_VERSION//./_}"
BOOST_URL="https://archives.boost.io/release/1.92.0/source/boost_$BOOST_VERSION_DASH.tar.gz"

wget -q "$BOOST_URL"
tar -xf "boost_$BOOST_VERSION_DASH.tar.gz"
if [ -d "boost_$BOOST_VERSION_DASH" ]; then
    BOOST_DIR="boost_$BOOST_VERSION_DASH"
else
    BOOST_DIR=$(ls -d boost_*/)
fi
cd "$BOOST_DIR"
sh bootstrap.sh

# shellcheck disable=SC2086
if [ "$SANITIZER" != "off" ]; then
    case "$SANITIZER" in
        asan)  SANITIZER_FLAGS="-fsanitize=address -fno-omit-frame-pointer" ;;
        tsan)  SANITIZER_FLAGS="-fsanitize=thread" ;;
        ubsan) SANITIZER_FLAGS="-fsanitize=undefined" ;;
        *)     echo "Unknown sanitizer: $SANITIZER"; exit 1 ;;
    esac
    ./b2 install \
        $BOOST_LIBS \
        variant=release \
        debug-symbols=on \
        link=shared runtime-link=shared \
        cxxflags="$SANITIZER_FLAGS -g -O1" \
        linkflags="$SANITIZER_FLAGS" \
        -j2
elif [ "$BUILD_VARIANT" = "Debug" ]; then
    ./b2 install \
        $BOOST_LIBS \
        variant=debug debug-symbols=on link=shared runtime-link=shared \
        -j2
else
    # cxxflags=-fPIC is what Boost.Build needs for the static flavour: unlike the
    # cmake scripts, there is no CMAKE_POSITION_INDEPENDENT_CODE to set, and b2
    # compiles a link=static target without -fPIC by default. The two branches
    # above use link=shared, where PIC is implied, so this is the only place in
    # this script that needs it.
    ./b2 install \
        $BOOST_LIBS \
        variant=release debug-symbols=off link=static runtime-link=static optimization=speed \
        cxxflags=-fPIC \
        -j2
fi

cd ..
rm -rf "$BOOST_DIR" "boost_$BOOST_VERSION_DASH.tar.gz"
