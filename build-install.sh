#!/bin/bash

usage()
{
    echo "usage: build-install.sh [-t architecture target] [-l llvm-swift-version] [-r rust-commit] [-n rust-branch-name] | [-h]"
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
                                          export BUILD_TARGET=$1
                                          ;;
        -l | --llvm-swift-version )       shift
                                          export LLVM_SWIFT_VERSION=$1
                                          ;;
        -r | --rust-commit )              shift
                                          export RUST_COMMIT=$1
                                          ;;
        -n | --rust-commit-name )         shift
                                          export RUST_COMMIT_NAME=$1
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
export LLVM_BRANCH="swift-$LLVM_SWIFT_VERSION-RELEASE"

# 2. Select the best commit, tag or commit hash from https://github.com/rust-lang/rust

#RUST_COMMIT_NAME="nightly-2021-08-01"
#RUST_COMMIT="4e282795d" # nightly-2021-08-01

# 3. Select a name for the toolchain you want to install as. The toolchain will be installed
# under $HOME/.rustup/toolchains/rust-$RUST_TOOLCHAIN

export RUST_TOOLCHAIN="ios-$BUILD_TARGET-$RUST_COMMIT_NAME-swift-${LLVM_SWIFT_VERSION//./-}"

# call build script to checkout & compile rust with LLVM
./build.sh

# install in $HOME directory
./install.sh
