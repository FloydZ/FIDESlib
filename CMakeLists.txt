cmake_minimum_required(VERSION 3.25.2)
cmake_policy(VERSION 3.21.3...3.28)

project(FIDESlib VERSION 0.1 DESCRIPTION "Homomorphic Encryption Library")

############### Project configuration ###################

option(BUILD_BENCHMARKS "build benchmarks" ON)
option(BUILD_TESTS "build tests" ON)

############### Build Type Validation ###################

set(DEFAULT_BUILD_TYPE "Release")
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to '${DEFAULT_BUILD_TYPE}' as none was specified.")
  set(CMAKE_BUILD_TYPE "${DEFAULT_BUILD_TYPE}" CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Export compile commands for debugging, needed for nvim autocompletion
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "")
if(CMAKE_EXPORT_COMPILE_COMMANDS)
  set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES 
      ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
endif()

############### Utils ###################

include(FetchContent)
include(CMakePrintHelpers)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

############### CPP ###################

enable_language(CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

############### CUDA ##################

include(CheckLanguage)
check_language(CUDA)

if (NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES "native")
    # possible other values
    # set(CMAKE_CUDA_ARCHITECTURES "80-real;86-real;89-real")
endif ()

enable_language(CUDA)

set(CMAKE_RELOCATABLE_DEVICE_CODE ON)
set(CMAKE_CUDA_SEPARABLE_COMPILATION ON)
set(CMAKE_CUDA_STANDARD 20)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS ON)

find_package(CUDAToolkit REQUIRED)

############### OpenFHE Configuration ###################

set(${FIDESLIB_INSTALL_OPENFHE_PREFIX} "./deps/openfhe")
find_package(OpenFHE 1.2.3 CONFIG EXACT PATHS ${FIDESLIB_INSTALL_OPENFHE_PREFIX} REQUIRED)

option(BUILD_STATIC "Set to ON to include static versions of the library" ON)

if (OpenFHE_FOUND)
    message(STATUS "FOUND PACKAGE OpenFHE")
    message(STATUS "OpenFHE Version: ${BASE_OPENFHE_VERSION}")
    message(STATUS "OpenFHE installed as shared libraries: ${OpenFHE_SHARED}")
    message(STATUS "OpenFHE include files location: ${OpenFHE_INCLUDE}")
    message(STATUS "OpenFHE lib files location: ${OpenFHE_LIBDIR}")
    message(STATUS "OpenFHE Native Backend size: ${OpenFHE_NATIVE_SIZE}")
else ()
    message(FATAL_ERROR "PACKAGE OpenFHE NOT FOUND")
endif ()

set(CMAKE_CXX_FLAGS ${OpenFHE_CXX_FLAGS})
set(CMAKE_CUDA_FLAGS "-I${OpenFHE_INCLUDE}/..")

cmake_print_variables(OpenFHE_CXX_FLAGS)
cmake_print_variables(CMAKE_CUDA_FLAGS)

include_directories(${OPENMP_INCLUDES})
include_directories(${OpenFHE_INCLUDE})
include_directories(${OpenFHE_INCLUDE}/third-party/include)
include_directories(${OpenFHE_INCLUDE}/core)
include_directories(${OpenFHE_INCLUDE}/pke)
include_directories(${OpenFHE_INCLUDE}/binfhe)

link_directories(${OpenFHE_LIBDIR})
link_directories(${OPENMP_LIBRARIES})

############### NVTX ###################

include(nvtx/c/nvtxImportedTargets.cmake)

############### FIDESlib Definition ###################

set(SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)
set(INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)
file(GLOB_RECURSE SOURCE_FILES ${SOURCE_DIR}/*.cpp ${SOURCE_DIR}/*.cu)
file(GLOB_RECURSE HEADER_FILES ${INCLUDE_DIR}/*.h ${INCLUDE_DIR}/*.cuh ${INCLUDE_DIR}/*.hpp)

add_library(fideslib STATIC)

target_sources(fideslib PRIVATE ${SOURCE_FILES})
target_sources(fideslib PUBLIC FILE_SET HEADERS BASE_DIRS ${INCLUDE_DIR} FILES ${HEADER_FILES})

target_include_directories(fideslib
        PRIVATE nvtx/c/include
)

target_link_libraries(fideslib
        PUBLIC CUDA::cudart
        PUBLIC tbb
        PUBLIC ${OpenFHE_LIBDIR}/libOPENFHEcore_static.a
        PUBLIC ${OpenFHE_LIBDIR}/libOPENFHEpke_static.a
        PUBLIC ${OpenFHE_LIBDIR}/libOPENFHEbinfhe_static.a
        PUBLIC ${OpenFHE_LIBDIR}/libOPENFHEhook_static.a
)

target_compile_options(fideslib PRIVATE
        $<$<COMPILE_LANGUAGE:CXX>:-Wall -ltbb -O3>
        $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:DEBUG>>:-g -O0 -rdynamic>
        $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=-Wall,-lineinfo,-ltbb,-O3 -rdc=true -ltbb>
        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:DEBUG>>:-G>
        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:RELWITHDEBINFO>>:>
)

set_target_properties(fideslib PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
        POSITION_INDEPENDENT_CODE ON
        CUDA_RESOLVE_DEVICE_SYMBOLS ON
        PREFIX ""
)

############### GPU Checker ###################

add_executable(gpu-test GPUTest.cu)

target_compile_options(gpu-test PRIVATE
        $<$<COMPILE_LANGUAGE:CXX>:-Wall>
        $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=-Wall,-lineinfo>
        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:DEBUG>>:-G -g>
        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:RELWITHDEBINFO>>:>
)

if (CUDA_FOUND)
    try_run(RUN_RESULT_VAR COMPILE_RESULT_VAR
            ${CMAKE_BINARY_DIR}
            ${CMAKE_CURRENT_SOURCE_DIR}/GPUTest.cu
            CMAKE_FLAGS
            -DINCLUDE_DIRECTORIES:STRING=${CUDA_TOOLKIT_INCLUDE}
            -DLINK_LIBRARIES:STRING=${CUDA_CUDART_LIBRARY}
            COMPILE_OUTPUT_VARIABLE COMPILE_OUTPUT_VAR
            RUN_OUTPUT_VARIABLE RUN_OUTPUT_VAR)
    message("${RUN_OUTPUT_VAR}")
    if (COMPILE_RESULT_VAR AND NOT RUN_RESULT_VAR)
        set(CUDA_HAVE_GPU TRUE CACHE BOOL "Whether CUDA-capable GPU is present")
    else ()
        set(CUDA_HAVE_GPU FALSE CACHE BOOL "Whether CUDA-capable GPU is present")
    endif ()
endif (CUDA_FOUND)

############### Dummy executable ###################

add_executable(dummy Dummy.cu)
target_link_libraries(dummy PRIVATE fideslib)

set_target_properties(dummy PROPERTIES CUDA_RESOLVE_DEVICE_SYMBOLS ON
        CUDA_SEPARABLE_COMPILATION ON
        POSITION_INDEPENDENT_CODE ON
)
target_compile_options(dummy PRIVATE
        $<$<COMPILE_LANGUAGE:CXX>:-Wall -fchar8_t>
        $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=-Wall,-fchar8_t,-lineinfo>
        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:DEBUG>>:-G -g>
        $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:RELWITHDEBINFO>>:>
)

############### Configuration export ###################

set(CMAKE_INSTALL_PREFIX "/usr/local")

set(INSTALL_INCLUDE_DIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}")
set(INSTALL_LIBRARY_DIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
set(INSTALL_BINARY_DIR "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}")

############### Library Installation ###################

install(
        TARGETS fideslib
        EXPORT ${PROJECT_NAME}Targets
        LIBRARY DESTINATION "${INSTALL_LIBRARY_DIR}"
        ARCHIVE DESTINATION "${INSTALL_LIBRARY_DIR}"
        RUNTIME DESTINATION "${INSTALL_BINARY_DIR}"
        INCLUDES DESTINATION "${INSTALL_INCLUDE_DIR}"
        FILE_SET HEADERS DESTINATION "${INSTALL_INCLUDE_DIR}"
)

install(
        EXPORT ${PROJECT_NAME}Targets
        FILE ${PROJECT_NAME}Targets.cmake
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION "${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/cmake"
)

configure_package_config_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        INSTALL_DESTINATION "${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/cmake"
)

configure_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}ConfigVersion.cmake.in"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        @ONLY
)

install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        DESTINATION "${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/cmake"
)

############### Test ###################

set(INSTALL_GTEST OFF)
if (BUILD_TESTS)
    FetchContent_Declare(googletest GIT_REPOSITORY https://github.com/google/googletest.git GIT_TAG main)
    FetchContent_MakeAvailable(googletest)
    include(GoogleTest)
    
    set(TEST_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/test)
    file(GLOB_RECURSE TEST_SOURCE_FILES ${TEST_SOURCE_DIR}/*.cu ${TEST_SOURCE_DIR}/*.cpp ${TEST_SOURCE_DIR}/*.cuh ${TEST_SOURCE_DIR}/*.hpp)
    
    add_executable(fideslib-test)
    
    target_sources(fideslib-test PRIVATE ${TEST_SOURCE_FILES})
    
    target_link_libraries(fideslib-test
            PRIVATE gtest
            PRIVATE gtest_main
            PRIVATE fideslib
    )
    
    target_compile_options(fideslib-test PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:-Wall >
            $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=-Wall,-lineinfo -rdc=true>
            $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:DEBUG>>:-G -g>
            $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:RELWITHDEBINFO>>:-lineinfo>
    )
endif ()

############### Benchmark ###################

set(BENCHMARK_ENABLE_INSTALL OFF)
set(BENCHMARK_INSTALL_DOCS OFF)

if (BUILD_BENCHMARKS)
    FetchContent_Declare(benchmark GIT_REPOSITORY https://github.com/google/benchmark.git GIT_TAG main)
    FetchContent_MakeAvailable(benchmark)
    message(INFO "patching ${benchmark_SOURCE_DIR}")
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E chdir ${benchmark_SOURCE_DIR} 
              patch -p1 < ${CMAKE_SOURCE_DIR}/deps/patches/google-benchmark.patch
      RESULT_VARIABLE PATCH_RESULT
    )

    # if(NOT PATCH_RESULT EQUAL 0)
    #   message(FATAL_ERROR "Failed to apply benchmark patch")
    # endif()
    
    set(BENCH_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/bench)
    file(GLOB_RECURSE BENCH_SOURCE_FILES ${BENCH_SOURCE_DIR}/*.cu ${BENCH_SOURCE_DIR}/*.cpp ${BENCH_SOURCE_DIR}/*.cuh ${BENCH_SOURCE_DIR}/*.hpp)
    
    add_executable(fideslib-bench)
    
    target_sources(fideslib-bench PRIVATE ${BENCH_SOURCE_FILES})
    
    target_link_libraries(fideslib-bench
            PRIVATE benchmark::benchmark
            PRIVATE fideslib
    )
    
    target_compile_options(fideslib-bench PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:-Wall >
            $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=-Wall,-lineinfo -rdc=true -ltbb>
            $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:DEBUG>>:-G>
            $<$<AND:$<COMPILE_LANGUAGE:CUDA>,$<CONFIG:RELWITHDEBINFO>>:-lineinfo>
    )
endif()
