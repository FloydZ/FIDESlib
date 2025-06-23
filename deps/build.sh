#!/usr/bin/env bash
set -e
set -x

mkdir -p openfhe-install
git submodule update --init

cd openfhe

# way of doing it for v1.2.3
# git checkout v1.2.3
# git submodule update --init
# git apply ../patchtes/have_int.patch
# git apply ../../cmake/openfhe-hook.patch
# git apply ../../cmake/openfhe-base.patch

# my version for v1.3.0
git checkout v1.3.0
git submodule update --init
git apply ../patches/have_int.patch
git apply ../patches/hook.patch
git apply ../patches/hook_code.patch
git apply ../patches/private_protected_to_public.patch
git apply ../patches/ckksrns-fhe.patch
git apply ../patches/base-sheme.h.patch
git apply ../patches/cryptocontext.cpp.patch

mkdir -p build
cd build 
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../../openfhe-install ..
make -j12
make install -j12 
