FROM alpine:3.24.1 AS base

ARG BUILD_VARIANT=Release

# System Dependencies (Merged from throttr and setup.sh)
RUN apk update && apk add --no-cache \
    alpine-sdk \
    cmake \
    git \
    wget \
    curl \
    bash \
    zip \
    unzip \
    tzdata \
    libtool \
    automake \
    m4 \
    re2c \
    supervisor \
    openssl-dev \
    openssl-libs-static \
    zlib-dev \
    zlib-static \
    zstd-static \
    libcurl \
    curl-dev \
    curl-static \
    protobuf-dev \
    python3 \
    doxygen \
    graphviz \
    rsync \
    gcovr \
    lcov \
    autoconf \
    nghttp2-dev \
    nghttp2-static \
    brotli-static \
    libidn2-static \
    libpsl-static \
    libunistring-static \
    linux-headers \
    ca-certificates

RUN if [ "$BUILD_VARIANT" = "Debug" ]; then \
    apk add --no-cache \
        gdb \
        gdb-dbg \
        elfutils \
        binutils; \
    fi

# Set Timezone
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime && echo "UTC" > /etc/timezone

# Build RE2
RUN git clone https://github.com/google/re2.git /tmp/re2 && \
    cd /tmp/re2 && \
    git checkout tags/2025-11-05 && \
    if [ "$BUILD_VARIANT" = "Debug" ]; then SHARED=ON; else SHARED=OFF; fi && \
    cmake -S . -B build \
        -DCMAKE_BUILD_TYPE="$BUILD_VARIANT" \
        -DRE2_BUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS="$SHARED" && \
    cmake --build build --target install --parallel 2 && \
    rm -rf /tmp/re2

# Build FlatBuffers (v23.5.26)
RUN git clone https://github.com/google/flatbuffers.git /tmp/flatbuffers && \
    cd /tmp/flatbuffers && \
    git checkout tags/v23.5.26 && \
    if [ "$BUILD_VARIANT" = "Debug" ]; then SHARED=ON; else SHARED=OFF; fi && \
    cmake -S . -B build \
        -DCMAKE_BUILD_TYPE="$BUILD_VARIANT" \
        -DFLATBUFFERS_BUILD_TESTS=OFF \
        -DFLATBUFFERS_BUILD_SHAREDLIB="$SHARED" && \
    cmake --build build --target install --parallel 2 && \
    rm -rf /tmp/flatbuffers

# Build Boost 1.91.0
ARG BOOST_VERSION="1.91.0"
RUN BOOST_VERSION_DASH=$(echo $BOOST_VERSION | sed 's/\./_/g') && \
    wget https://archives.boost.io/release/$BOOST_VERSION/source/boost_$BOOST_VERSION_DASH.tar.gz && \
    tar -xf boost_$BOOST_VERSION_DASH.tar.gz && \
    cd boost_$BOOST_VERSION_DASH && \
    sh bootstrap.sh && \
    if [ "$BUILD_VARIANT" = "Debug" ]; then \
        ./b2 install \
            --with-json --with-program_options --with-charconv \
            variant=debug debug-symbols=on link=shared runtime-link=shared \
            -j2; \
    else \
        ./b2 install \
            --with-json --with-program_options --with-charconv \
            variant=release debug-symbols=off link=static runtime-link=static optimization=speed \
            -j2; \
    fi && \
    cd .. && \
    rm -rf boost_$BOOST_VERSION_DASH boost_$BOOST_VERSION_DASH.tar.gz

WORKDIR /src
