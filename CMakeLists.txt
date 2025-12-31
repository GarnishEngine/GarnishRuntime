cmake_minimum_required(VERSION 3.22)
project(GarnishRuntime)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Add GarnishEngine
add_subdirectory(3rdParty/GarnishEngine)

# Build GarnishPong
file(GLOB_RECURSE SOURCE_FILES CONFIGURE_DEPENDS
    src/*.cc 
)

add_executable(GarnishRuntime main.cc ${SOURCE_FILES})

target_link_libraries(GarnishRuntime PRIVATE GarnishEngine)

# Include Directories
target_include_directories(GarnishRuntime PUBLIC
    3rdParty/GarnishEngine/include
    3rdParty/GarnishEngine/3rdParty/SDL/include
)

# Ensure tool dependencies.
include(ExternalProject) # Required to download and build external projects (i.e. ANTLR).
find_package(Git REQUIRED) # Need git to download ANTLR through ExternalProject.
find_package(Java COMPONENTS Runtime REQUIRED) # Need java to run ANTLR, but only the runtime.

# Ensure we have LLVM.
include("${CMAKE_SOURCE_DIR}/cmake/get_mlir.cmake")

# Link against the pthreads library to make std::call_once
# in generated ANTLR code to run without producing system errors
# (see issue https://github.com/antlr/antlr4/issues/3708).
set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)




# Set default option values based on build type
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(ASAN_DEFAULT ON)
  set(LTO_DEFAULT OFF)
  set(NATIVE_OPT_DEFAULT OFF)
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
  set(ASAN_DEFAULT OFF)
  set(LTO_DEFAULT ON)
  set(NATIVE_OPT_DEFAULT ON)
else()
  set(ASAN_DEFAULT OFF)
  set(LTO_DEFAULT ON)
  set(NATIVE_OPT_DEFAULT ON)
endif()

option(ENABLE_ASAN "Enable AddressSanitizer" ${ASAN_DEFAULT})
if(ENABLE_ASAN)
  message(STATUS "ASan enabled")

  # Choose flags per compiler (works for AppleClang/Clang/GNU)
  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|AppleClang")
    set(_ASAN_COMPILE_FLAGS "-fsanitize=address -fsanitize-address-use-after-scope -fno-omit-frame-pointer -g -O1")
    set(_ASAN_LINK_FLAGS    "-fsanitize=address")
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(_ASAN_COMPILE_FLAGS "-fsanitize=address -fno-omit-frame-pointer -g -O1")
    set(_ASAN_LINK_FLAGS    "-fsanitize=address")
  else()
    set(_ASAN_COMPILE_FLAGS "")
    set(_ASAN_LINK_FLAGS    "")
  endif()

  # Apply to both C and C++; and to exe/shared/module linkers
  set(CMAKE_C_FLAGS             "${CMAKE_C_FLAGS} ${_ASAN_COMPILE_FLAGS}")
  set(CMAKE_CXX_FLAGS           "${CMAKE_CXX_FLAGS} ${_ASAN_COMPILE_FLAGS}")
  set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS} ${_ASAN_LINK_FLAGS}")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${_ASAN_LINK_FLAGS}")
  set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} ${_ASAN_LINK_FLAGS}")
endif()

option(ENABLE_LTO "Enable interprocedural (link-time) optimization" ${LTO_DEFAULT})
if(ENABLE_LTO)
  include(CheckIPOSupported)
  check_ipo_supported(RESULT ipo_supported OUTPUT ipo_output)
  if(ipo_supported)
    message(STATUS "IPO/LTO enabled")
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -flto=auto")
    
  else()
    message(WARNING "IPO/LTO not supported: ${ipo_output}")
  endif()
endif()

option(ENABLE_NATIVE_OPTIMIZATIONS "Enable -march/-mtune native for Release builds" ${NATIVE_OPT_DEFAULT})
if(ENABLE_NATIVE_OPTIMIZATIONS)
  add_compile_options("$<$<CONFIG:Release>:-march=native>" "$<$<CONFIG:Release>:-mtune=native>")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
endif()

# Set C++ standards.
set(CMAKE_CXX_STANDARD 20)

# Add CXX flags.
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")

# Pass build configuration to compiler for conditional optimization
add_compile_definitions(CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}")

# Pass feature flags to compiler
if(ENABLE_ASAN)
    add_compile_definitions(ENABLE_ASAN)
endif()

if(ENABLE_LTO)
    add_compile_definitions(ENABLE_LTO)
endif()

if(ENABLE_NATIVE_OPTIMIZATIONS)
    add_compile_definitions(ENABLE_NATIVE_OPTIMIZATIONS)
endif()

# Include cmake utilities.
include("${CMAKE_SOURCE_DIR}/cmake/symlink_to_bin.cmake")

# Grab ANTLR.
include("${CMAKE_SOURCE_DIR}/cmake/get_antlr.cmake")

# Set up paths and info to generate ANTLR sources with.
set(GRAMMAR_NAME "Gazprea")
set(ANTLR_NAMESPACE "gazprea")

# Generate sources.
include("${CMAKE_SOURCE_DIR}/cmake/antlr_generate.cmake")

# Include project headers.
include_directories("${CMAKE_SOURCE_DIR}/include")
include_directories("${CMAKE_SOURCE_DIR}/gen")


# Add the source directory.
add_subdirectory("${CMAKE_SOURCE_DIR}/src")

# Add the runtime directory.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/runtime")
