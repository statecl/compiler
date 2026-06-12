# Environment Base Images

Multi-distribution Docker base images for building and testing C++ projects.
Includes pre-compiled dependencies (Boost, FlatBuffers) and full toolchain per image.

**Registry:** `ghcr.io/statecl/compiler`

---

## Available Images

All images include GCC + Clang, CMake, Boost 1.91.0, FlatBuffers v23.5.26,
ccache (except Oracle Linux, Amazon Linux), and full documentation tooling.

| Distro | Base Image | libc | Static | Sanitizers |
|--------|-----------|------|--------|------------|
| alpine | `alpine:3.24.0` | musl | ✅ | ❌ |
| debian | `debian:bookworm-20260610` | glibc | ❌ | ASAN, TSAN, UBSAN |
| ubuntu | `ubuntu:noble-20260509.1` | glibc | ❌ | ASAN, TSAN, UBSAN |
| fedora | `fedora:45` | glibc | ❌ | ASAN, TSAN, UBSAN |
| rocky | `rockylinux:9.3` | glibc | ❌ | ASAN, TSAN, UBSAN |
| alma | `almalinux:10.2` | glibc | ❌ | ASAN, TSAN, UBSAN |
| oracle | `oraclelinux:10` | glibc | ❌ | ASAN, TSAN, UBSAN |
| amazon | `amazonlinux:2023.11.20260526.0` | glibc | ❌ | ASAN, TSAN, UBSAN |

> Alpine is the only image with static linking and musl libc.
> All glibc-based images support sanitizers; Alpine does not.

---

## Build Variants

| Variant | Flags | Alpine | glibc |
|---------|-------|--------|-------|
| `release` | `-O2 -DNDEBUG`, static link (Alpine), shared (glibc) | ✅ | ✅ |
| `debug` | `-O0 -g`, shared link | ✅ | ✅ |
| `debug-asan` | `-O1 -g -fsanitize=address` | ❌ | ✅ |
| `debug-tsan` | `-O1 -g -fsanitize=thread` | ❌ | ✅ |
| `debug-ubsan` | `-O1 -g -fsanitize=undefined` | ❌ | ✅ |

Sanitizer variants instrument all dependencies (Boost + FlatBuffers + runtime).

---

## Build Args

| Arg | Default | Values | Description |
|-----|---------|--------|-------------|
| `BUILD_VARIANT` | `Release` | `Release`, `Debug` | Optimisation level and debug symbols |
| `SANITIZER` | `off` | `off`, `asan`, `tsan`, `ubsan` | Sanitizer to enable (ignored on Alpine) |

---

## Usage

```dockerfile
FROM ghcr.io/statecl/compiler:latest-release-debian
# or
FROM ghcr.io/statecl/compiler:latest-debug-asan-ubuntu
```

### Tag Pattern

`{tag}-{variant}-{distro}[-{arch}]`

| Tag | Example | Description |
|-----|---------|-------------|
| `latest-{variant}-{distro}` | `latest-release-alpine` | Latest master, multi-arch |
| `v{version}-{variant}-{distro}` | `v1.2.3-debug-asan-fedora` | Versioned release, multi-arch |
| `latest-{variant}-{distro}-{arch}` | `latest-release-ubuntu-arm64` | Single-arch |
| `v{version}-{variant}-{distro}-{arch}` | `v1.2.3-release-alpine-amd64` | Versioned single-arch |

---

## Building Locally

```bash
# Alpine (static, no sanitizers)
docker build -f alpine/Dockerfile \
  --build-arg BUILD_VARIANT=Release \
  -t myimage:release-alpine .

# Debian / Ubuntu (apt-based)
docker build -f ubuntu/Dockerfile \
  --build-arg BUILD_VARIANT=Debug \
  --build-arg SANITIZER=asan \
  -t myimage:debug-asan-ubuntu .

# Fedora / Rocky / Alma (dnf-based, with ccache)
docker build -f fedora/Dockerfile \
  --build-arg BUILD_VARIANT=Release \
  -t myimage:release-fedora .

# Oracle Linux (dnf, no ccache)
docker build -f oracle/Dockerfile \
  --build-arg BUILD_VARIANT=Debug \
  --build-arg SANITIZER=tsan \
  -t myimage:debug-tsan-oracle .

# Amazon Linux (dnf, no ccache)
docker build -f amazon/Dockerfile \
  --build-arg BUILD_VARIANT=Release \
  -t myimage:release-amazon .
```

---

## CI / CD

### GitLab CI

Pipeline on `master` push or `v*` tag trigger:

```
build:amd64  →  Alpine (2 variants) + glibc (7 distros × 5 variants)  = 37 jobs
build:arm64  →  Alpine (2 variants) + glibc (7 distros × 5 variants)  = 37 jobs
                 ─────────────────────────────────────────────────────────────
Total: 74 parallel builds
```

### GitHub Actions

Same matrix via `.github/workflows/ci.yml`, publishes to `ghcr.io`.

### Dependabot

`.github/dependabot.yml` checks for new base image tags every Monday.
PRs are created automatically when a newer version is available.

---

## Multi-Arch

All images are built for `linux/amd64` and `linux/arm64`:
- Native builds on arm64 runners
- QEMU emulation where native is unavailable
- Per-platform digests are merged into multi-arch OCI manifests

---

## Repository Structure

```
environment/
├── alpine/Dockerfile       # Alpine 3.24.0, musl, static
├── debian/Dockerfile       # Debian Bookworm 20260610, glibc
├── ubuntu/Dockerfile       # Ubuntu Noble 24.04, glibc
├── fedora/Dockerfile       # Fedora 45, glibc
├── rocky/Dockerfile        # Rocky Linux 9.3, glibc
├── alma/Dockerfile         # AlmaLinux 10.2, glibc
├── oracle/Dockerfile       # Oracle Linux 10, glibc
├── amazon/Dockerfile       # Amazon Linux 2023.11, glibc
├── scripts/
│   ├── build-flatbuffers.sh  # Shared FlatBuffers build
│   └── build-boost.sh        # Shared Boost build
├── .github/
│   ├── dependabot.yml        # Base image version checks
│   └── workflows/ci.yml      # GitHub Actions CI
├── .gitlab-ci.yml            # GitLab CI
├── Dockerfile                # Backward compat alias (Alpine)
└── README.md
```

## Quick Reference

| Feature | Alpine | Debian/Ubuntu | Fedora/Rocky/Alma | Oracle | Amazon |
|---------|--------|---------------|-------------------|--------|--------|
| Package manager | `apk` | `apt` | `dnf` | `dnf` | `dnf` |
| ccache | ✅ | ✅ | ✅ | ❌ | ❌ |
| gcovr / lcov | ✅ | ✅ | ✅ | ❌ | ❌ |
| Static linking | ✅ | ❌ | ❌ | ❌ | ❌ |
| Sanitizers | ❌ | ✅ | ✅ | ✅ | ✅ |
