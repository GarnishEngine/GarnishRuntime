# CMake module to find and configure the ANTLR C++ runtime.
# 
# Supports two modes:
#   1. Vendored: Build ANTLR4 from source (default if USE_VENDORED_ANTLR is ON)
#   2. External: Use pre-installed ANTLR4 via ANTLR_INS environment variable
#
# Creates:
#   - ANTLR_INCLUDE_DIRS: Include directories for ANTLR headers
#   - ANTLR_JAR: Path to ANTLR jar file (downloads if missing)
#   - antlr4-runtime: Static library target (vendored) or imported library (external)
#   - antlr: Custom target for dependency tracking

option(USE_VENDORED_ANTLR "Build ANTLR4 C++ runtime from source" ON)

if(USE_VENDORED_ANTLR)
  include("${CMAKE_SOURCE_DIR}/cmake/get_antlr_vendored.cmake")
  return()
endif()

# External installation mode: Get ANTLR installation directory from environment variable
if (NOT DEFINED ENV{ANTLR_INS})
  message(FATAL_ERROR "ANTLR_INS environment variable not set. Please set it to your ANTLR installation directory, or set USE_VENDORED_ANTLR=ON to build from source.")
endif()
file(TO_CMAKE_PATH "$ENV{ANTLR_INS}" _ANTLR_DIR)

# Setup ANTLR jar path and download if missing
file(TO_CMAKE_PATH "${_ANTLR_DIR}/bin" BIN_DIR)
set(BIN_DIR ${BIN_DIR} CACHE PATH "ANTLR jar directory")

file(TO_CMAKE_PATH "${BIN_DIR}/antlr-4.13.0-complete.jar" ANTLR_JAR)
if (NOT EXISTS "${ANTLR_JAR}")
  message(STATUS "Downloading ANTLR generator...")
  file(
    DOWNLOAD
    http://www.antlr.org/download/antlr-4.13.0-complete.jar
    "${ANTLR_JAR}"
    SHOW_PROGRESS
  )
  file(TO_NATIVE_PATH "${BIN_DIR}" BIN_DIR_NATIVE)
  message(STATUS "Downloaded ANTLR jar to: ${BIN_DIR_NATIVE}")
endif()

# Verify and setup include directories
if (NOT EXISTS "${_ANTLR_DIR}/include/antlr4-runtime/")
  message(FATAL_ERROR "Missing ANTLR include directory: ${_ANTLR_DIR}/include/antlr4-runtime/")
endif()

list(APPEND ANTLR_INCLUDE_DIRS "${_ANTLR_DIR}/include/antlr4-runtime")

foreach(subdir misc atn dfa tree support)
  set(subdir_path "${_ANTLR_DIR}/include/antlr4-runtime/${subdir}")
  if (NOT EXISTS "${subdir_path}")
    message(FATAL_ERROR "Missing ANTLR include subdirectory: ${subdir_path}")
  endif()
  list(APPEND ANTLR_INCLUDE_DIRS "${subdir_path}")
endforeach()

# Setup static library target
set(
  _antlr_static_lib
  "${_ANTLR_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}antlr4-runtime${CMAKE_STATIC_LIBRARY_SUFFIX}"
)

if (NOT EXISTS "${_antlr_static_lib}")
  message(FATAL_ERROR "Missing ANTLR static library: ${_antlr_static_lib}")
endif()

add_library(antlr4-runtime STATIC IMPORTED)
set_property(
  TARGET antlr4-runtime
  PROPERTY IMPORTED_LOCATION ${_antlr_static_lib}
)

# Create dependency target for build ordering
add_custom_target(antlr)
