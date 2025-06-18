#!/usr/bin/env bash

# first build the openfhe submodule
cd deps
./build.sh
cd ..

# now build the openfhe cuda wrapper
mkdir -p build 
cd build
cmake .. 
make -j $(nproc)
cd ..
