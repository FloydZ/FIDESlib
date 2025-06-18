#!/usr/bin/env bash

mkdir -p openfhe-install
git submodule update --init

cd openfhe
git checkout v1.2.3
git submodule update --init
git apply ../have_int.patch
git apply ../../cmake/openfhe-hook.patch
git apply ../../cmake/openfhe-base.patch
mkdir -p build
cd build 
cmake -DCMAKE_INSTALL_PREFIX=../../openfhe-install ..
make -j12
make install -j12 
