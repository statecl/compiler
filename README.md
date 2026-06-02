# Environment Base Image

This repository contains the `Dockerfile` for the base environment used by the Service project.
It includes all necessary system dependencies and pre-compiled libraries (Boost, spdlog, fmt, flatbuffers, etc.) to speed up the main build process.

Repo: https://gitlab.state.cl/org/compiler
Registry: registry.state.cl

## Multi-Arch Support
This image is built for both `linux/amd64` (via QEMU) and `linux/arm64` (native) using GitLab CI on arm64 runners.

## Build variant for dependencies
The image now builds **one variant per image** controlled by `BUILD_VARIANT`.

- Default: `Release`
- Supported values: `Release` / `Debug`
- Install paths remain unchanged (system default used by each project install step).

### Behavior by variant
- `Release`: static linking flags are kept.
- `Debug`: static linking is disabled (shared linking enabled where relevant).

Example:

```bash
# Release image (default)
docker build -t registry.state.cl/org/compiler:release .

# Debug image for ASAN/TSAN pipelines
docker build \
  --build-arg BUILD_VARIANT=Debug \
  -t registry.state.cl/org/compiler:debug .
```

## Image
The image is published to: `registry.state.cl/org/compiler`

## How to use
```dockerfile
FROM registry.state.cl/org/compiler:latest
```


