#!/bin/bash
set -euo pipefail

EDG_VERSION="${EDG_VERSION:-7.0}"
EDG_URL="${EDG_URL:-https://www.edg.com/edgcpfe_${EDG_VERSION}.tar.gz}"
EDG_PREFIX="${EDG_PREFIX:-/opt/edg}"
CXX="${CXX:-g++}"
CC="${CC:-gcc}"
JOBS="${JOBS:-2}"

GXX_PATH=$(command -v "$CXX")
GCC_PATH=$(command -v "$CC")

GCC_VERSION=$("$GXX_PATH" -dumpfullversion 2>/dev/null || "$GXX_PATH" -dumpversion)
IFS=. read -r GCC_MAJOR GCC_MINOR GCC_PATCH <<< "$GCC_VERSION"
GCC_MAJOR="${GCC_MAJOR:-0}"
GCC_MINOR="${GCC_MINOR:-0}"
GCC_PATCH="${GCC_PATCH:-0}"
GNU_VERSION=$(printf '%d%02d%02d' "$GCC_MAJOR" "$GCC_MINOR" "$GCC_PATCH")

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$EDG_URL" -o "$TMP_DIR/edgcpfe.tar.gz"
else
    wget -q "$EDG_URL" -O "$TMP_DIR/edgcpfe.tar.gz"
fi

mkdir -p "$TMP_DIR/src"
tar -xzf "$TMP_DIR/edgcpfe.tar.gz" -C "$TMP_DIR/src"
EDG_SRC=$(find "$TMP_DIR/src" -mindepth 1 -maxdepth 1 -type d -name 'release_*' | head -n 1)

cd "$EDG_SRC"
cp src/defines.h.linux src/defines.h
cp sample_edg_eccp_config/edg_eccp_config.linux edg_eccp_config
chmod u+w edg_eccp_config

(
    cd lib
    ../sample_edg_eccp_config/make_g++_incl_paths
    ../misc/make_predef_macro_table --gcc "$GCC_PATH" --g++ "$GXX_PATH"
)

{
    echo "GNU_VERSION=$GNU_VERSION"
    cat <<'EOF'
export EDG_LIB_ECCP_FLAGS="--g++ --gnu_version=$GNU_VERSION"
export EDG_CPFE_DEFAULT_OPTIONS="${EDG_CPFE_DEFAULT_OPTIONS:-} --g++ --gnu_version=$GNU_VERSION"
EDG_DEFAULT_INCLUDE_DIRS="$gpp_incl_paths:$EDG_BASE/include"
EDG_INCLDIR="$EDG_DEFAULT_INCLUDE_DIRS"
EDG_CINCLDIR="$EDG_DEFAULT_INCLUDE_DIRS:$EDG_GCC_DIR/include"
EOF
} >> edg_eccp_config

export EDG_BASE="$PWD"
make -j"$JOBS" \
    CXX="$GXX_PATH" \
    LDFLAGS="-std=c++14" \
    CXXFLAGS="-std=c++14 -x c++ -DIL_SHOULD_BE_WRITTEN_TO_FILE"

install -d "$EDG_PREFIX"
cp -a bin include lib edg_eccp_config "$EDG_PREFIX/"
chmod 0444 "$EDG_PREFIX/edg_eccp_config"

install -d /usr/local/bin
for file in "$EDG_PREFIX"/bin/* "$EDG_PREFIX"/lib/edg_prelink "$EDG_PREFIX"/lib/edg_decode "$EDG_PREFIX"/lib/edg_munch "$EDG_PREFIX"/lib/cfe_daemon_client; do
    ln -sf "$file" "/usr/local/bin/$(basename "$file")"
done

cd /
rm -rf "$TMP_DIR"
trap - EXIT
