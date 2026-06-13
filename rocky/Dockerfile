FROM rockylinux:9.3 AS base

ARG BUILD_VARIANT=Release
ARG SANITIZER=off

RUN dnf install -y epel-release && \
    dnf config-manager --set-enabled crb && \
    dnf install -y \
        gcc \
        gcc-c++ \
        gcc-toolset-12-gcc \
        gcc-toolset-12-gcc-c++ \
        gcc-toolset-12-libasan-devel \
        gcc-toolset-12-libubsan-devel \
        gcc-toolset-12-libtsan-devel \
    clang \
    ccache \
    cmake \
    git \
        wget \
        ca-certificates \
        pkgconfig \
        zip \
        unzip \
        tzdata \
        libtool \
        automake \
        m4 \
        openssl-devel \
        zlib-devel \
        libcurl-devel \
        protobuf-devel \
        python3 \
        doxygen \
        graphviz \
        rsync \
        lcov \
        autoconf \
        libnghttp2-devel \
        kernel-headers \
        libasan \
        libtsan \
        libubsan \
    && dnf clean all

ENV CC=/opt/rh/gcc-toolset-12/root/usr/bin/gcc
ENV CXX=/opt/rh/gcc-toolset-12/root/usr/bin/g++

RUN if [ "$BUILD_VARIANT" = "Debug" ] || [ "$SANITIZER" != "off" ]; then \
    dnf install -y gdb && dnf clean all; \
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

WORKDIR /src
