cmake_minimum_required(VERSION 3.22)
project(GarnishRuntime)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_subdirectory(3rdParty/GarnishEngine)

# Exclude compiler directory - it has its own CMakeLists.txt
file(GLOB_RECURSE SOURCE_FILES CONFIGURE_DEPENDS src/*.cc)
list(FILTER SOURCE_FILES EXCLUDE REGEX ".*/src/compiler/.*")

add_executable(GarnishRuntime main.cc ${SOURCE_FILES})
target_link_libraries(GarnishRuntime PRIVATE GarnishEngine)

target_include_directories(GarnishRuntime PUBLIC
    3rdParty/GarnishEngine/include
    3rdParty/GarnishEngine/3rdParty/SDL/include
)

include(ExternalProject)
find_package(Git REQUIRED)
find_package(Java COMPONENTS Runtime REQUIRED)

# Required for ANTLR generated code (see https://github.com/antlr/antlr4/issues/3708)
set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)

option(ENABLE_ASAN "Enable AddressSanitizer" ${ASAN_DEFAULT})
if(ENABLE_ASAN)
  message(STATUS "ASan enabled")

  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|AppleClang")
    set(_ASAN_COMPILE_FLAGS "-fsanitize=address -fsanitize-address-use-after-scope -fno-omit-frame-pointer -g -O1")
    set(_ASAN_LINK_FLAGS "-fsanitize=address")
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(_ASAN_COMPILE_FLAGS "-fsanitize=address -fno-omit-frame-pointer -g -O1")
    set(_ASAN_LINK_FLAGS "-fsanitize=address")
  else()
    set(_ASAN_COMPILE_FLAGS "")
    set(_ASAN_LINK_FLAGS "")
  endif()

  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${_ASAN_COMPILE_FLAGS}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_ASAN_COMPILE_FLAGS}")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${_ASAN_LINK_FLAGS}")
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

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
add_compile_definitions(CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}")

if(ENABLE_ASAN)
  add_compile_definitions(ENABLE_ASAN)
endif()

if(ENABLE_LTO)
  add_compile_definitions(ENABLE_LTO)
endif()

if(ENABLE_NATIVE_OPTIMIZATIONS)
  add_compile_definitions(ENABLE_NATIVE_OPTIMIZATIONS)
endif()

include("${CMAKE_SOURCE_DIR}/cmake/symlink_to_bin.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/get_antlr.cmake")
include("${CMAKE_SOURCE_DIR}/cmake/antlr_generate.cmake")

file(GLOB_RECURSE grammar_files "${CMAKE_SOURCE_DIR}/grammar/*.g4")
set(ANTLR_NAMESPACE "garnish")

if(grammar_files)
  foreach(grammar_file ${grammar_files})
    get_filename_component(grammar_name "${grammar_file}" NAME_WE)
    string(REPLACE "${CMAKE_SOURCE_DIR}/grammar/" "" rel_path "${grammar_file}")
    get_filename_component(rel_dir "${rel_path}" DIRECTORY)

    if(rel_dir)
      get_filename_component(folder_name "${rel_dir}" NAME)
      set(full_namespace "${ANTLR_NAMESPACE}::${grammar_name}::${folder_name}")
    else()
      set(full_namespace "${ANTLR_NAMESPACE}::${grammar_name}")
    endif()

    string(REPLACE "/" "_" target_suffix "${rel_path}")
    string(REPLACE ".g4" "" target_suffix "${target_suffix}")
    set(target_name "parser_${target_suffix}")

    message(STATUS "Found grammar: ${grammar_file} -> target: ${target_name}, namespace: ${full_namespace}")

    antlr_generate_parser("${grammar_file}" "${grammar_name}" "${full_namespace}" "${target_name}")

    if(grammar_name STREQUAL "scdsk")
      add_library(parser ALIAS ${target_name})
      string(REPLACE "::" "/" namespace_path "${full_namespace}")
      file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}/gen/${namespace_path}" ANTLR_GEN_DIR)
      set(ANTLR_GEN_DIR ${ANTLR_GEN_DIR} CACHE PATH "Generated source directory (ANTLR)")
    endif()
  endforeach()
else()
  message(WARNING "No grammar files found in ${CMAKE_SOURCE_DIR}/grammar/")
endif()

include_directories("${CMAKE_SOURCE_DIR}/include")
include_directories("${CMAKE_SOURCE_DIR}/gen")

add_subdirectory("${CMAKE_SOURCE_DIR}/src")
