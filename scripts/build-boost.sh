#!/bin/bash
set -euo pipefail

BOOST_VERSION="${BOOST_VERSION:-1.91.0}"
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
BOOST_URL="https://archives.boost.io/release/$BOOST_VERSION/source/boost_$BOOST_VERSION_DASH.tar.gz"

wget -q "$BOOST_URL"
tar -xf "boost_$BOOST_VERSION_DASH.tar.gz"
cd "boost_$BOOST_VERSION_DASH"
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
    ./b2 install \
        $BOOST_LIBS \
        variant=release debug-symbols=off link=static runtime-link=static optimization=speed \
        -j2
fi

cd ..
rm -rf "boost_$BOOST_VERSION_DASH" "boost_$BOOST_VERSION_DASH.tar.gz"
