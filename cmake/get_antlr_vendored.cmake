# CMake module to vendor and build ANTLR4 C++ runtime from source.
#
# Downloads and builds ANTLR4 C++ runtime in the build directory.
# Creates:
#   - ANTLR_INCLUDE_DIRS: Include directories for ANTLR headers
#   - ANTLR_JAR: Path to ANTLR jar file (downloads if missing)
#   - antlr4-runtime: Static library target (built from source)
#   - antlr: Custom target for dependency tracking

include(FetchContent)

# Download ANTLR4 C++ runtime
FetchContent_Declare(
  antlr4
  GIT_REPOSITORY https://github.com/antlr/antlr4.git
  GIT_TAG        4.13.0
  SOURCE_DIR     "${CMAKE_BINARY_DIR}/3rdParty/antlr4"
)

# Only fetch if not already available
FetchContent_GetProperties(antlr4)
if(NOT antlr4_POPULATED)
  message(STATUS "Fetching ANTLR4 C++ runtime...")
  FetchContent_Populate(antlr4)
endif()

# Add ANTLR4 C++ runtime subdirectory
# This will build the static library
set(ANTLR4_BUILD_TESTS OFF CACHE BOOL "Build ANTLR4 tests" FORCE)
set(ANTLR4_BUILD_DEMOS OFF CACHE BOOL "Build ANTLR4 demos" FORCE)
add_subdirectory("${antlr4_SOURCE_DIR}/runtime/Cpp" "${antlr4_BINARY_DIR}/runtime/Cpp" EXCLUDE_FROM_ALL)

# Setup include directories
# ANTLR4 C++ runtime headers are in runtime/src
set(antlr4_src_dir "${antlr4_SOURCE_DIR}/runtime/Cpp/runtime/src")
list(APPEND ANTLR_INCLUDE_DIRS "${antlr4_src_dir}")

# Add subdirectories
foreach(subdir misc atn dfa tree support)
  list(APPEND ANTLR_INCLUDE_DIRS "${antlr4_src_dir}/${subdir}")
endforeach()

# Setup ANTLR jar path and download if missing
set(ANTLR_JAR_DIR "${CMAKE_BINARY_DIR}/3rdParty/antlr4/jar")
file(MAKE_DIRECTORY "${ANTLR_JAR_DIR}")

set(ANTLR_JAR "${ANTLR_JAR_DIR}/antlr-4.13.0-complete.jar")
if(NOT EXISTS "${ANTLR_JAR}")
  message(STATUS "Downloading ANTLR generator jar...")
  file(
    DOWNLOAD
    http://www.antlr.org/download/antlr-4.13.0-complete.jar
    "${ANTLR_JAR}"
    SHOW_PROGRESS
  )
  message(STATUS "Downloaded ANTLR jar to: ${ANTLR_JAR}")
endif()

# Find the ANTLR4 static library target
# ANTLR4 C++ runtime may use different target names depending on version
set(antlr4_target_name "")
if(TARGET antlr4_static)
  set(antlr4_target_name "antlr4_static")
elseif(TARGET antlr4-runtime-static)
  set(antlr4_target_name "antlr4-runtime-static")
elseif(TARGET antlr4_shared)
  set(antlr4_target_name "antlr4_shared")
else()
  message(FATAL_ERROR "Could not find ANTLR4 library target. Expected one of: antlr4_static, antlr4-runtime-static, antlr4_shared")
endif()

# Create alias for consistent naming
add_library(antlr4-runtime ALIAS ${antlr4_target_name})

# Create dependency target for build ordering
add_custom_target(antlr DEPENDS ${antlr4_target_name})

message(STATUS "ANTLR4 C++ runtime will be built from source")

