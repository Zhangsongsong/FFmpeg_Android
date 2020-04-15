#!/bin/bash

VERSION=1.1.1d
export ANDROID_NDK_HOME=/Users/zasko/Library/Android/sdk/ndk/20.1.5948944
ANDROID_API=21

if [ ! -f "openssl-$VERSION.tar.gz" ]; then
    curl -LO https://www.openssl.org/source/openssl-$VERSION.tar.gz
fi

rm -fr static
mkdir -p static/lib
mkdir -p static/include

# declare -A qt_architectures=( ["x86_64"]="x86_64" ["x86"]="x86" ["arm64"]="arm64-v8a" ["arm"]="armeabi-v7a" )
declare -A qt_architectures=( ["x86_64"]="x86_64")

for arch in "x86_64" 
do
    rm -fr $arch
    mkdir $arch
    rm -fr openssl-$VERSION
    tar -xvf openssl-$VERSION.tar.gz
    cd openssl-$VERSION

    case $arch in
        arm)
            ANDROID_API=16
            ;;
        x86)
            ANDROID_API=16
            ;;
        arm64)
            ANDROID_API=21
            ;;
        x86_64)
            ANDROID_API=21
            ;;
    esac
    ANDROID_TOOLCHAIN=""
    for host in "linux-x86_64" "linux-x86" "darwin-x86_64" "darwin-x86"
    do
        if [ -d "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$host/bin" ]; then
            ANDROID_TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$host/bin"
            break
        fi
    done

    export PATH="$ANDROID_TOOLCHAIN":"$PATH"

    ./Configure shared android-${arch} -D__ANDROID_API__=${ANDROID_API} || exit 1
    make depend
    make -j$(nproc) SHLIB_VERSION_NUMBER= SHLIB_EXT=_1_1.so build_libs || exit 1
    llvm-strip -strip-all libcrypto_1_1.so
    llvm-strip -strip-all libssl_1_1.so
    cp libcrypto_1_1.so ../$arch
    cp libssl_1_1.so ../$arch
    mv libcrypto.a ../static/lib/libcrypto_${qt_architectures[$arch]}.a
    mv libssl.a ../static/lib/libssl_${qt_architectures[$arch]}.a
    cd ..
done

cp -a openssl-$VERSION/include/openssl static/include
