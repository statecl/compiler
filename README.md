# Environment Base Images

Multi-distribution Docker base images for building and testing C++ projects.
Includes pre-compiled dependencies (Boost, FlatBuffers) and full toolchain per image.

Repo: https://gitlab.state.cl/org/compiler
Registry: `registry.state.cl/org/compiler` (GitLab)

## Available Images

| Distro | Base | Toolchain | Static Linking | Sanitizers |
|--------|------|-----------|---------------|------------|
| alpine | `alpine:latest` | GCC + Clang | ✅ | ❌ |
| debian | `debian:latest` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| ubuntu | `ubuntu:latest` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| fedora | `fedora:latest` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| rocky | `rockylinux:9` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| arch | `archlinux:latest` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |

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

# Fedora/Rocky (dnf-based)
docker build -f fedora/Dockerfile \
  --build-arg BUILD_VARIANT=Release \
  -t myimage:release-fedora .

# Arch (pacman-based)
docker build -f arch/Dockerfile \
  --build-arg BUILD_VARIANT=Debug \
  --build-arg SANITIZER=tsan \
  -t myimage:debug-tsan-arch .
```

## CI Matrix

Each merge to `master` or `v*` tag triggers **54 parallel builds**:

- Alpine: release, debug × amd64, arm64 = 4
- Debian/Ubuntu/Fedora/Rocky/Arch: release, debug, asan, tsan, ubsan × amd64, arm64 = 50
- **Total: 54**

## Multi-Arch

All images are built for `linux/amd64` and `linux/arm64` (native on arm64 runners,
via QEMU where native unavailable). Per-platform digests are merged into
multi-arch OCI manifests.

## Repository Structure

```
environment/
├── alpine/Dockerfile       # Alpine Linux, musl, static
├── debian/Dockerfile       # Debian Bookworm, glibc
├── ubuntu/Dockerfile       # Ubuntu latest, glibc
├── fedora/Dockerfile       # Fedora latest, glibc
├── rocky/Dockerfile        # Rocky Linux latest, glibc
├── arch/Dockerfile         # Arch Linux latest, glibc, rolling
├── scripts/
│   ├── build-flatbuffers.sh  # Shared FlatBuffers build
│   └── build-boost.sh        # Shared Boost build
├── Dockerfile              # Backward compat (Alpine, root)
├── .gitlab-ci.yml
└── README.md
```
