FROM archlinux:latest AS base

ARG BUILD_VARIANT=Release
ARG SANITIZER=off

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        base-devel \
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
        openssl \
        zlib \
        protobuf \
        python \
        doxygen \
        graphviz \
        rsync \
        gcovr \
        lcov \
        libnghttp2 \
        linux-headers \
    && pacman -Scc --noconfirm

RUN if [ "$BUILD_VARIANT" = "Debug" ] || [ "$SANITIZER" != "off" ]; then \
    pacman -S --noconfirm gdb && pacman -Scc --noconfirm; \
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
