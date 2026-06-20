FROM debian:bookworm-20260610 AS base

ARG BUILD_VARIANT=Release
ARG SANITIZER=off

# Prevent debconf from prompting
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    ccache \
    cmake \
    git \
    wget \
    curl \
    ca-certificates \
    pkg-config \
    zip \
    unzip \
    tzdata \
    libtool \
    automake \
    m4 \
    libssl-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libprotobuf-dev \
    python3 \
    doxygen \
    graphviz \
    rsync \
    gcovr \
    lcov \
    autoconf \
    libnghttp2-dev \
    linux-libc-dev \
    && rm -rf /var/lib/apt/lists/*

RUN if [ "$BUILD_VARIANT" = "Debug" ] || [ "$SANITIZER" != "off" ]; then \
    apt-get update && apt-get install -y --no-install-recommends \
        gdb \
        && rm -rf /var/lib/apt/lists/*; \
    fi

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime && echo "UTC" > /etc/timezone

COPY scripts/build-flatbuffers.sh /tmp/build-flatbuffers.sh
RUN FLATBUFFERS_VERSION=v23.5.26 \
    BUILD_VARIANT=$BUILD_VARIANT \
    SANITIZER=$SANITIZER \
    /tmp/build-flatbuffers.sh

COPY scripts/build-boost.sh /tmp/build-boost.sh
RUN BOOST_VERSION=1.91.0 \
    BUILD_VARIANT=$BUILD_VARIANT \
    SANITIZER=$SANITIZER \
    /tmp/build-boost.sh

COPY scripts/build-fmt.sh /tmp/build-fmt.sh
RUN FMT_VERSION=11.0.2 \
    BUILD_VARIANT=$BUILD_VARIANT \
    SANITIZER=$SANITIZER \
    /tmp/build-fmt.sh

COPY scripts/build-googletest.sh /tmp/build-googletest.sh
RUN GTEST_VERSION=03597a01ee50ed33e9dfd640b249b4be3799d395 \
    BUILD_VARIANT=$BUILD_VARIANT \
    SANITIZER=$SANITIZER \
    /tmp/build-googletest.sh

COPY scripts/build-re2.sh /tmp/build-re2.sh
RUN RE2_VERSION=2024-07-02 \
    BUILD_VARIANT=$BUILD_VARIANT \
    SANITIZER=$SANITIZER \
    /tmp/build-re2.sh && \
    ldconfig

WORKDIR /src
