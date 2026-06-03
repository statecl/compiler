FROM debian:bookworm-20250512 AS base

ARG BUILD_VARIANT=Release
ARG SANITIZER=off

# Prevent debconf from prompting
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
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
RUN BOOST_VERSION=1.90.0 \
    BUILD_VARIANT=$BUILD_VARIANT \
    SANITIZER=$SANITIZER \
    /tmp/build-boost.sh

WORKDIR /src
