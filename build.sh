#!/bin/bash

export OPENSSL_STATIC=1
export OPENSSL_DIR=/usr/local/opt/openssl
if [ ! -d "$OPENSSL_DIR" ]; then
    echo "OpenSSL not found at expected location. Try: brew install openssl"
    exit 1
fi
if ! which ninja; then
    echo "ninja not found. Try: brew install ninja"
    exit 1
fi
if ! which cmake; then
    echo "cmake not found. Try: brew install cmake"
    exit 1
fi

WORKING_DIR="$(pwd)/build"
mkdir -p "$WORKING_DIR"

cd "$WORKING_DIR"
if [ ! -d "$WORKING_DIR/llvm-project" ]; then
    git clone --depth 1 --branch "$LLVM_BRANCH" https://github.com/apple/llvm-project.git
fi
cd "$WORKING_DIR/llvm-project"
git reset --hard
git clean -f
git checkout -f "$LLVM_BRANCH"
git apply ../../patches/llvm-system-libs.patch
cd ..

mkdir -p llvm-build
cd llvm-build
cmake "$WORKING_DIR/llvm-project/llvm" -DCMAKE_INSTALL_PREFIX="$WORKING_DIR/llvm-root" -DCMAKE_BUILD_TYPE=Release -DLLVM_INSTALL_UTILS=ON -DLLVM_TARGETS_TO_BUILD='X86;ARM;AArch64' -G Ninja
ninja
ninja install

cd "$WORKING_DIR"
if [ ! -d "$WORKING_DIR/rust" ]; then
    git clone https://github.com/rust-lang/rust.git
fi
cd rust
git reset --hard
git clean -f
git checkout -f "$RUST_COMMIT"
cd ..
mkdir -p rust-build
cd rust-build
../rust/configure --llvm-config="$WORKING_DIR/llvm-root/bin/llvm-config" --target=$BUILD_TARGET --enable-extended --tools=cargo --release-channel=nightly
export CFLAGS_${BUILD_TARGET//-/_}=-fembed-bitcode
python "$WORKING_DIR/rust/x.py" build --stage 2 -v 

echo "rust-bitcode build.sh finished"
