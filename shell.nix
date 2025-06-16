with import <nixpkgs> {};
{ pkgs ? import <nixpkgs> {} }:

stdenv.mkDerivation {
  name = "custom_openfhe_backend";
  src = ./.;

  buildInputs = [
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    cudaPackages.libcurand
    linuxPackages.nvidia_x11

    git gitRepo gnupg autoconf curl
    procps gnumake util-linux m4 gperf unzip
    cudatoolkit 
    libGLU libGL
    xorg.libXi xorg.libXmu freeglut
    xorg.libXext xorg.libX11 xorg.libXv xorg.libXrandr zlib
    ncurses5 stdenv.cc binutils

    filecheck
    cmake
    gcc12
    libgcc
    gmp
    gtest
    openssl
    pkg-config
  ]++ (lib.optionals pkgs.stdenv.isLinux ([
  ]));

  shellHook = ''
    export CUDA_PATH=${pkgs.cudatoolkit}
    export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib
    export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
    export EXTRA_CCFLAGS="-I/usr/include"
  '';
  # shellHook = ''
  #   # NVIDIA Driver and CUDA setup
  #   export NVIDIA_VISIBLE_DEVICES=all
  #   export NVIDIA_DRIVER_CAPABILITIES=compute,utility
  #   export CUDA_VISIBLE_DEVICES=0

  #   # Path setup
  #   export PATH="${pkgs.gcc12}/bin:$PATH"
  #   export PATH=${pkgs.cudaPackages.cuda_nvcc}/bin:$PATH

  #   # CUDA setup
  #   export CUDAHOSTCXX="${pkgs.gcc12}/bin/g++"
  #   export CUDA_HOST_COMPILER="${pkgs.gcc12}/bin/gcc"
  #   export CUDA_HOME=${pkgs.cudaPackages.cuda_cudart}
  #   export CUDA_PATH=${pkgs.cudaPackages.cuda_cudart}

  #   # Library paths with specific NVIDIA driver
  #   export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib
  #   export LD_LIBRARY_PATH=${pkgs.cudaPackages.cuda_cudart}/lib64:${pkgs.cudaPackages.cuda_cudart}/lib:$LD_LIBRARY_PATH
  #   export LD_LIBRARY_PATH=${stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH

  #   export LIBRARY_PATH=${pkgs.cudaPackages.cuda_cudart}/lib64:${pkgs.cudaPackages.cuda_cudart}/lib:$LIBRARY_PATH

  #   # OpenGL driver path
  #   export LD_LIBRARY_PATH=${pkgs.linuxPackages.nvidia_x11}/lib:$LD_LIBRARY_PATH

  #   echo "CUDA C/C++ development environment ready"
  #   echo "GCC version in use:"
  #   gcc --version
  #   echo "NVCC version:"
  #   nvcc --version
  #   echo "SHELL NVIDIA driver version:"
  #   cat ${pkgs.linuxPackages.nvidia_x11}/lib/nvidia/version
  # '';
}
