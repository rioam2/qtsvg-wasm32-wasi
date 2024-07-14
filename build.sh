#!/usr/bin/env bash

set -e
set -o xtrace

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$script_dir/build"
qtbase_dir="$build_dir/qtbase"

# Shallow clone qtbase to temporary folder
if [ ! -d "$qtbase_dir" ] ; then
    mkdir -p "$qtbase_dir"
    git clone \
        https://github.com/rioam2/qtbase-wasm32-wasi.git \
        --branch 6.6.1#wasi \
        --single-branch \
        --depth=1 \
        "$qtbase_dir"
else
    pushd "$qtbase_dir"
    git pull
    popd
fi

# Build qtbase
pushd "$qtbase_dir"
./build.sh
popd

qtbase_build_dir="$qtbase_dir/build/wasm32-wasi-install"

cmake . \
    -B ./build/wasm32-wasi \
    -G Ninja \
    `# Build configuration` \
    -DCMAKE_BUILD_TYPE=Release \
    -DQT_QMAKE_TARGET_MKSPEC=linux-clang-libc++-32 \
    -DCMAKE_TOOLCHAIN_FILE="$script_dir/cmake/wasi/wasi-sdk.toolchain.cmake" \
    -DQt6_DIR="$qtbase_build_dir/lib/cmake/Qt6" \
    -DQt6BuildInternals_DIR="$qtbase_build_dir/lib/cmake/Qt6BuildInternals" \
    -DQt6BundledFreetype_DIR="$qtbase_build_dir/lib/cmake/Qt6BundledFreetype" \
    -DQt6BundledLibpng_DIR="$qtbase_build_dir/lib/cmake/Qt6BundledLibpng" \
    -DQt6BundledPcre2_DIR="$qtbase_build_dir/lib/cmake/Qt6BundledPcre2" \
    -DQt6BundledZLIB_DIR="$qtbase_build_dir/lib/cmake/Qt6BundledZLIB" \
    -DQt6Core_DIR="$qtbase_build_dir/lib/cmake/Qt6Core" \
    -DQt6Gui_DIR="$qtbase_build_dir/lib/cmake/Qt6Gui" \
    -DQt6ZlibPrivate_DIR="$qtbase_build_dir/lib/cmake/Qt6ZlibPrivate"

cmake --build ./build/wasm32-wasi --parallel
cmake --install ./build/wasm32-wasi --prefix "./build/wasm32-wasi-install"

rm -f ./build/wasm32-wasi/qtsvg-6.1.1.a && \
    llvm-ar qcsL ./build/wasm32-wasi/qtsvg-6.1.1.a \
    $(find ./build/wasm32-wasi-install -type f -name "*.obj" -o -name "*.a" | tr '\n' ' ')
