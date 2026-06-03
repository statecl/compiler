# Environment Base Images

Multi-distribution Docker base images for building and testing C++ projects.
Includes pre-compiled dependencies (Boost, FlatBuffers) and full toolchain per image.

Repo: https://gitlab.state.cl/org/compiler
Registry: `registry.state.cl/org/compiler` (GitLab) / `ghcr.io/statecl/environment` (GitHub)

## Available Images

| Distro | Base | Toolchain | Static Linking | Sanitizers |
|--------|------|-----------|---------------|------------|
| alpine | `alpine:3.21.3` | GCC + Clang | ✅ | ❌ |
| debian | `debian:bookworm-20250512` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| ubuntu | `ubuntu:24.04` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |
| fedora | `fedora:41` | GCC + Clang | ❌ | ✅ ASAN, TSAN, UBSAN |

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
| `sha-{shortsha}-{variant}-{distro}` | `sha-a1b2c3d-release-debian` | Per-commit, multi-arch |
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
```

## CI Matrix

Each merge to `master` or `v*` tag triggers **34 parallel builds**:

- Alpine: release, debug × amd64, arm64 = 4
- Debian/Ubuntu/Fedora: release, debug, asan, tsan, ubsan × amd64, arm64 = 30
- **Total: 34** per CI system (GitLab CI + GitHub Actions)

## Multi-Arch

All images are built for `linux/amd64` and `linux/arm64` (native on arm64 runners,
via QEMU where native unavailable). Per-platform digests are merged into
multi-arch OCI manifests at the merge stage.

## Repository Structure

```
environment/
├── alpine/Dockerfile       # Alpine 3.21.3, musl, static
├── debian/Dockerfile       # Debian Bookworm, glibc
├── ubuntu/Dockerfile       # Ubuntu 24.04, glibc
├── fedora/Dockerfile       # Fedora 41, glibc
├── scripts/
│   ├── build-flatbuffers.sh  # Shared FlatBuffers build
│   └── build-boost.sh        # Shared Boost build
├── Dockerfile              # Backward compat (Alpine, root)
├── .gitlab-ci.yml
├── .github/workflows/publish.yml
└── README.md
```
