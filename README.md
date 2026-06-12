# Environment Base Images

Multi-distribution Docker base images for building and testing C++ projects.
Includes pre-compiled dependencies (Boost, FlatBuffers) and full toolchain per image.

Repo: https://gitlab.state.cl/org/compiler
Registry: `registry.state.cl/org/compiler` (GitLab)

## Available Images

| Distro | Base | Toolchain | Static Linking | Sanitizers |
|--------|------|-----------|---------------|------------|
| alpine | `alpine:3.24.0` | GCC + Clang | ✅ | ❌ |
| debian | `debian:bookworm-20260610` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| ubuntu | `ubuntu:noble-20260509.1` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| fedora | `fedora:45` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| rocky | `rockylinux:9.3` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| alma | `almalinux:10.2` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| oracle | `oraclelinux:10` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| amazon | `amazonlinux:2023.11.20260526.0` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |

## Build Variants

| Variant | Flags | Alpine | glibc |
|---------|-------|--------|-------|
| `release` | `-O2 -DNDEBUG`, static link | ✅ | ✅ |
| `debug` | `-O0 -g`, shared link | ✅ | ✅ |
| `debug-asan` | `-O1 -g -fsanitize=address` | ❌ | ✅ |
| `debug-tsan` | `-O1 -g -fsanitize=thread` | ❌ | ✅ |
| `debug-ubsan` | `-O1 -g -fsanitize=undefined` | ❌ | ✅ |

Sanitizer variants instrument all dependencies (Boost + FlatBuffers + runtime).

## Usage

```dockerfile
FROM registry.state.cl/org/compiler:latest-release-debian
# or
FROM registry.state.cl/org/compiler:latest-debug-asan-ubuntu
```

## Tags

Pattern: `{tag}-{variant}-{distro}[-{arch}]`

| Tag | Example | Description |
|-----|---------|-------------|
| `latest-{variant}-{distro}` | `latest-release-alpine` | Latest master, multi-arch |
| `v{version}-{variant}-{distro}` | `v1.2.3-debug-asan-fedora` | Versioned release, multi-arch |
| `latest-{variant}-{distro}-{arch}` | `latest-release-ubuntu-arm64` | Single-arch |
| `v{version}-{variant}-{distro}-{arch}` | `v1.2.3-release-alpine-amd64` | Versioned single-arch |

## Building Locally

```bash
# Alpine (static, no sanitizers)
docker build -f alpine/Dockerfile \
  --build-arg BUILD_VARIANT=Release \
  -t myimage:release-alpine .

# Debian with ASAN
docker build -f debian/Dockerfile \
  --build-arg BUILD_VARIANT=Debug \
  --build-arg SANITIZER=asan \
  -t myimage:debug-asan-debian .

# Fedora/Rocky/Alma (dnf-based)
docker build -f fedora/Dockerfile \
  --build-arg BUILD_VARIANT=Release \
  -t myimage:release-fedora .

# Oracle Linux
docker build -f oracle/Dockerfile \
  --build-arg BUILD_VARIANT=Release \
  -t myimage:release-oracle .

# Amazon Linux
docker build -f amazon/Dockerfile \
  --build-arg BUILD_VARIANT=Debug \
  --build-arg SANITIZER=tsan \
  -t myimage:debug-tsan-amazon .
```

## CI Matrix

Each merge to `master` or `v*` tag triggers **74 parallel builds**:

- Alpine: release, debug × amd64, arm64 = 4
- Debian/Ubuntu/Fedora/Rocky/Alma/Oracle/Amazon: release, debug, asan, tsan, ubsan × amd64, arm64 = 70
- **Total: 74**

## Multi-Arch

All images are built for `linux/amd64` and `linux/arm64` (native on arm64 runners,
via QEMU where native unavailable). Per-platform digests are merged into
multi-arch OCI manifests.

## Repository Structure

```
environment/
├── alpine/Dockerfile       # Alpine 3.24.0, musl, static
├── debian/Dockerfile       # Debian Bookworm 20260610, glibc
├── ubuntu/Dockerfile       # Ubuntu Noble 24.04, glibc
├── fedora/Dockerfile       # Fedora 45, glibc
├── rocky/Dockerfile        # Rocky Linux 9.3, glibc
├── alma/Dockerfile         # AlmaLinux 10.2, glibc
├── oracle/Dockerfile      # Oracle Linux 10, glibc
├── amazon/Dockerfile      # Amazon Linux 2023.11, glibc
├── scripts/
│   ├── build-flatbuffers.sh  # Shared FlatBuffers build
│   └── build-boost.sh        # Shared Boost build
├── Dockerfile              # Backward compat (Alpine, root)
├── .gitlab-ci.yml
└── README.md
```
