<p align="center">
  <img src="https://github.com/CAPS-UMU/FIDESlib/blob/main/doxygen/FidesLogo.drawio.svg?raw=true" width="200">
</p>

# FIDESlib

A server-side CKKS GPU library fully interoperable with OpenFHE.

## Features
  -  Full CKKS implementation: Add, AddPt, AddScalar, Mult, MultPt, MultScalar, Square, Rotate, RotateHoisted, Bootstrap.
  -  OpenFHE interoperability for FIXEDMANUAL, FIXEDAUTO, FLEXIBLEAUTO and FLEXIBLEAUTOEXT.
  -  Hardware acceleration with Nvidia CUDA.
  -  High-performance NTT/INTT implementation.
  -  Hybrid Key-Switching.

## Citation

If you use FIDESlib on your research, please cite our ISPASS paper.

```bibtex
@inproceedings{FIDESlib,
	title        = {{FIDESlib: A Fully-Fledged Open-Source FHE Library for Efficient CKKS on GPUs}},
	author       = {Carlos Agulló-Domingo and Óscar Vera-López and Seyda Guzelhan and Lohit Daksha and Aymane El Jerari and Kaustubh Shivdikar and Rashmi Agrawal and David Kaeli and Ajay Joshi and José L. Abellán},
	year         = 2025,
	booktitle    = {2025 IEEE International Symposium on Performance Analysis of Systems and Software (ISPASS)},
	publisher    = {IEEE},
	address      = {Ghent, Belgium},
	doi          = {https://doi.org/10.1109/ISPASS64960.2025.00045},
	url          = {https://github.com/CAPS-UMU/FIDESlib},
	note         = {Poster paper}
}
```

## Compilation

> [!IMPORTANT]
> Requirements:
>  -  Nvidia CUDA  version 12 or greater.
>  -  GNU GCC Compiler version 13 or greater.
>  -  CMake version 3.25.2 or greater.
>  -  Intel Thread Building Blocks

Ubuntu:
```bash 
sudo apt install make build-essential cmake git libtbb-dev
```

> [!NOTE]
> Some dependencies will be automatically downloaded if needed:
> - GoogleTest: used by our test suite.
> - GoogleBenchmark: used by our benchmark suite.

In order to be able to compile the project, one must follow these steps:
``` bash
git clone --recursive git@bitbucket.org:tiicrypto/tii-openfhe.git
cd tii-openfhe 
./build.sh
```

FIDESlib needs a patched version of OpenFHE in order to be able to access some internals needed for interoperability. This patched version will be automatically installed by the `build.sh` script


The build process produces the following artifacts: 
- fideslib.a: The FIDESlib library to be statically linked to any client application.
- fideslib-test: The test suite executable.
- fideslib-bench: The benchmark suite executable.
- gpu-test: A dummy executable to search for the CUDA capable devices on the machine.
- dummy: Another dummy executable.

> [!WARNING]
> Compiling FIDESlib sometimes produces TLS-related errors. This issue can be addressed by re-compiling OpenFHE in debug mode. In this case, you should:
> - Manually clone [OpenFHE](https://github.com/openfheorg/openfhe-development) and, with git, apply openfhe-hook.patch and openfhe-base.patch. 
> - Generate the build files with CMake using Debug as build type.
> - Compile and install OpenFHE on the machine. 


### **Basic CMake Options**

The following options can be used with CMake to configure the build. The default value for each option is denoted in **boldface** under the **Values** column:

| CMake option               | Values                                      | Information                                                                      |
|----------------------------|---------------------------------------------|----------------------------------------------------------------------------------|
| `CMAKE_CUDA_ARCHITECTURES` | naitve                                      | Use this toolchain file to integrate vcpkg with CMake for dependency management. |
| `BUILD_TESTS`              | **ON** / OFF                                | Build the tests for verifying the functionality of the project.                  |
| `BUILD_BENCHMARKS`         | **ON** / OFF                                | Build the benchmarks                                                             |

## Installation

Installing the library is as easy as running the following command:

```bash
cmake --build $PATH_TO_BUILD_DIR --target install -j
```

FIDESlib is currently ready to be consumed as a CMake library. The template project on the examples directory shows how to build and run a FIDESlib client application and contains examples of usage of most of the functionality provided by FIDESlib. Currently client applications consuming FIDESlib should use the CUDA compiler every time they include a FIDESlib header.

> [!NOTE]
> As the default installation prefix is /usr/local. All installed headers should be located under /usr/local/include/FIDESlib, the CMake package files under /usr/local/share/FIDESlib and the compiled library under /usr/local/lib.

> [!WARNING]
> FIDESlib currently does not support custom installation paths. One should run the installation command with administrator priviledges.

## Docker 
Note: all commands are prefixed with `sudo`, which may be not neccessary, as 
docker can be runned rootless.  Additionally :W

In order to build the docker image, run the following command:
```bash
sudo docker build -t cuda-tests .
```

You can run binaries in the docker image via:
```bash
# Run tests
sudo docker run --rm --device=nvidia.com/gpu=all cuda-tests ./build/fideslib-test
# Run benchmarks
sudo docker run --rm --device=nvidia.com/gpu=all cuda-tests ./build/fideslib-bench
```

## Usage

Check examples for projects that use FIDESlib.

## Credits

Thanks to all main contributors:
* Carlos Agulló Domingo. 
* Óscar Vera López.
* Seyda Guzelhan.
* Lohit Daksha.
* Aymane El Jerari.

## Grants

This project was possible thanks to the following grants:
* Grant CNS2023-144241 funded by "MICIU/AEI/10.13039/501100011033" and the "European Union NextGenerationEU/PRTR".
* Grants NSF CNS 2312275 and 2312276, and supported in part from the NSF IUCRC Center for Hardware and Embedded Systems Security and Trust (CHEST).

## Inquiries and comments

If you have any question, comment, or suggestion, please contact:
* Carlos Agulló Domingo (carlos.a.d@um.es).
* Óscar Vera López (oscar.veral@um.es).

Or feel free to open an issue or a general discussion on this repository.
