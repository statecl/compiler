FROM alpine:3.24.0 AS base

ARG BUILD_VARIANT=Release
ARG SANITIZER=off

RUN apk update && apk add --no-cache \
    alpine-sdk \
    clang \
    cmake \
    ccache \
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

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime && echo "UTC" > /etc/timezone

COPY scripts/build-flatbuffers.sh /tmp/build-flatbuffers.sh
RUN FLATBUFFERS_VERSION=v23.5.26 \
    BUILD_VARIANT=$BUILD_VARIANT \
    /tmp/build-flatbuffers.sh

COPY scripts/build-boost.sh /tmp/build-boost.sh
RUN BOOST_VERSION=1.92.0_b1 \
    BUILD_VARIANT=$BUILD_VARIANT \
    /tmp/build-boost.sh

COPY scripts/build-fmt.sh /tmp/build-fmt.sh
RUN FMT_VERSION=11.0.2 \
    BUILD_VARIANT=$BUILD_VARIANT \
    /tmp/build-fmt.sh

COPY scripts/build-googletest.sh /tmp/build-googletest.sh
RUN GTEST_VERSION=03597a01ee50ed33e9dfd640b249b4be3799d395 \
    BUILD_VARIANT=$BUILD_VARIANT \
    /tmp/build-googletest.sh

COPY scripts/build-re2.sh /tmp/build-re2.sh
RUN RE2_VERSION=2024-07-02 \
    BUILD_VARIANT=$BUILD_VARIANT \
    /tmp/build-re2.sh

WORKDIR /src
