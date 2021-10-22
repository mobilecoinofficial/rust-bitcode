#!/bin/bash
usage()
{
    echo "usage: install.sh [-t architecture target] [-l llvm-swift-version] [-n rust-branch-name] | [-h]"
    echo -e "  -t architecture target like: 'aarch64-apple-ios'"
    echo -e "  -l should match a version number in an `llvm-project` branch ie: 'swift-5.3.2-RELEASE'"
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

RUST_TOOLCHAIN="ios-$BUILD_TARGET-$RUST_COMMIT_NAME-swift-${LLVM_SWIFT_VERSION//./-}"

set -euxo
source config.sh

WORKING_DIR="$(pwd)/build"
DEST_TOOLCHAIN="$HOME/.rustup/toolchains/$RUST_TOOLCHAIN"

# Remove unneeded files from output
rm -rf "$WORKING_DIR/rust-build/build/x86_64-apple-darwin/stage2/lib/rustlib/src"

rm -rf "$DEST_TOOLCHAIN"
mkdir -p "$DEST_TOOLCHAIN"
cp -r "$WORKING_DIR/rust-build/build/x86_64-apple-darwin/stage2"/* "$DEST_TOOLCHAIN"
cp -r "$WORKING_DIR/rust-build/build/x86_64-apple-darwin/stage2-tools/x86_64-apple-darwin/release/cargo" "$DEST_TOOLCHAIN/bin"

echo "Installed bitcode-enabled Rust toolchain. Use with: +$RUST_TOOLCHAIN"
