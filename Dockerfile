FROM alpine:3.21 AS base

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

# Build libunwind (Static)
RUN git clone https://github.com/libunwind/libunwind.git /tmp/libunwind && \
    cd /tmp/libunwind && \
    autoreconf -i && \
    ./configure --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/libunwind

# Build spdlog (v1.16.0)
RUN git clone https://github.com/gabime/spdlog.git /tmp/spdlog && \
    cd /tmp/spdlog && \
    git checkout tags/v1.16.0 && \
    if [ "$BUILD_VARIANT" = "Debug" ]; then SHARED=ON; else SHARED=OFF; fi && \
    cmake -S . -B build \
        -DCMAKE_BUILD_TYPE="$BUILD_VARIANT" \
        -DSPDLOG_BUILD_SHARED="$SHARED" \
        -DSPDLOG_FMT_EXTERNAL=OFF && \
    cmake --build build --target install --parallel $(nproc) && \
    rm -rf /tmp/spdlog

# Build fmt (12.1.0)
RUN git clone https://github.com/fmtlib/fmt.git /tmp/fmt && \
    cd /tmp/fmt && \
    git checkout tags/12.1.0 && \
    if [ "$BUILD_VARIANT" = "Debug" ]; then SHARED=ON; else SHARED=OFF; fi && \
    cmake -S . -B build \
        -DCMAKE_BUILD_TYPE="$BUILD_VARIANT" \
        -DBUILD_SHARED_LIBS="$SHARED" \
        -DFMT_DOC=OFF \
        -DFMT_TEST=OFF \
        -DFMT_FUZZ=OFF \
        -DFMT_CUDA_TEST=OFF && \
    cmake --build build --target install --parallel $(nproc) && \
    rm -rf /tmp/fmt

# Build libbcrypt
RUN git clone https://github.com/Zen0x7/libbcrypt.git /tmp/bcrypt && \
    cd /tmp/bcrypt && \
    if [ "$BUILD_VARIANT" = "Debug" ]; then SHARED=ON; else SHARED=OFF; fi && \
    cmake -S . -B build \
        -DCMAKE_BUILD_TYPE="$BUILD_VARIANT" \
        -DBUILD_SHARED_LIBS="$SHARED" && \
    cmake --build build --target install --parallel $(nproc) && \
    rm -rf /tmp/bcrypt

# Build FlatBuffers (v23.5.26)
RUN git clone https://github.com/google/flatbuffers.git /tmp/flatbuffers && \
    cd /tmp/flatbuffers && \
    git checkout tags/v23.5.26 && \
    if [ "$BUILD_VARIANT" = "Debug" ]; then SHARED=ON; else SHARED=OFF; fi && \
    cmake -S . -B build \
        -DCMAKE_BUILD_TYPE="$BUILD_VARIANT" \
        -DFLATBUFFERS_BUILD_TESTS=OFF \
        -DFLATBUFFERS_BUILD_SHAREDLIB="$SHARED" && \
    cmake --build build --target install --parallel $(nproc) && \
    rm -rf /tmp/flatbuffers

# Build Boost 1.90.0
ARG BOOST_VERSION="1.90.0"
RUN BOOST_VERSION_DASH=$(echo $BOOST_VERSION | sed 's/\./_/g') && \
    wget https://archives.boost.io/release/$BOOST_VERSION/source/boost_$BOOST_VERSION_DASH.tar.gz && \
    tar -xf boost_$BOOST_VERSION_DASH.tar.gz && \
    cd boost_$BOOST_VERSION_DASH && \
    sh bootstrap.sh --with-libraries=all && \
    if [ "$BUILD_VARIANT" = "Debug" ]; then \
        ./b2 install variant=debug debug-symbols=on link=shared runtime-link=shared --without-python -j$(nproc); \
    else \
        ./b2 install variant=release debug-symbols=off link=static runtime-link=static optimization=speed --without-python -j$(nproc); \
    fi && \
    cd .. && \
    rm -rf boost_$BOOST_VERSION_DASH boost_$BOOST_VERSION_DASH.tar.gz

WORKDIR /src
