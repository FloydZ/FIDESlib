FROM nvidia/cuda:12.9.1-devel-ubuntu24.04

# Install build dependencies
RUN apt-get update && apt-get install -y \
    make \
    build-essential \
    cmake \
    git \
    ninja-build \
    libtbb-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy project files into the container
COPY . .

# build openfhe
RUN cd deps && ./build.sh

# Create build directory
RUN mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release
RUN cd build && make -j8

# Default command to list test and benchmark binaries
# CMD ["find", "build/", "-type", "f", "-executable", "-print"]
RUN cd build && ls
RUN cd build && ./fideslib-test
RUN cd build && ./fideslib-bench
