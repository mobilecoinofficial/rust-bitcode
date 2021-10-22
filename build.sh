#!/bin/bash

usage()
{
    echo "usage: build.sh [-t architecture target] [-l llvm-swift-version] [-r rust-commit] [-n rust-branch-name] | [-h]"
    echo -e "  -t architecture target like: 'aarch64-apple-ios'"
    echo -e "  -l should match a version number in an `llvm-project` branch ie: 'swift-5.3.2-RELEASE'"
    echo -e "  -r commit hash in `rust` repo"
    echo -e "  -n name for commit hash like: 'nightly-2021-08-01'"
    echo "  -h    help"
}

##### Main

mode=""

# Check for valid number of aguments
if [[ $# -ne 8 ]]; then
  echo "Your command contains no arguments"
  usage
  exit
fi

# Check for valid options
while [ "$1" != "" ]; do
    case $1 in
        -t | --target )                   shift
                                          BUILD_TARGET=$1
                                          ;;
        -l | --llvm-swift-version )       shift
                                          LLVM_SWIFT_VERSION=$1
                                          ;;
        -r | --rust-commit )              shift
                                          RUST_COMMIT=$1
                                          ;;
        -n | --rust-commit-name )         shift
                                          RUST_COMMIT_NAME=$1
                                          ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

set -euxo

# 1. Select the best branch, tag or commit hash from https://github.com/apple/llvm-project
# The recommended approach is to use the tagged release that matches the Swift version
# returned by the command below:
# $ xcrun -sdk iphoneos swiftc --version

#LLVM_SWIFT_VERSION="5.3.2"
LLVM_BRANCH="swift-$LLVM_SWIFT_VERSION-RELEASE"

# 2. Select the best commit, tag or commit hash from https://github.com/rust-lang/rust

#RUST_COMMIT_NAME="nightly-2021-08-01"
#RUST_COMMIT="4e282795d" # nightly-2021-08-01

# 3. Select a name for the toolchain you want to install as. The toolchain will be installed
# under $HOME/.rustup/toolchains/rust-$RUST_TOOLCHAIN

RUST_TOOLCHAIN="ios-$BUILD_TARGET-$RUST_COMMIT_NAME-swift-${LLVM_SWIFT_VERSION//./-}"

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

echo "build.sh finished"
