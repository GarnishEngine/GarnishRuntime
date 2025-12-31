# Gather our source files in this directory.
# Add source files here as they are created.

set(
  compiler_src_files
    "${CMAKE_CURRENT_SOURCE_DIR}/main.cc"
)

# Build our executable from the source files.
add_executable(compiler ${compiler_src_files})

# Include ANTLR generated headers
target_include_directories(compiler PUBLIC ${ANTLR_GEN_DIR})

# Include ANTLR runtime headers
target_include_directories(compiler PUBLIC ${ANTLR_INCLUDE_DIRS})

# Include project headers
target_include_directories(compiler PUBLIC
    "${CMAKE_SOURCE_DIR}/include"
    "${CMAKE_SOURCE_DIR}/gen"
)

# Suppress noisy warnings coming from external headers.
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(compiler PRIVATE -Wno-comment)
endif()

# Ensure that the antlr4-runtime is available.
add_dependencies(compiler antlr)

# Add the parser, antlr runtime, and threads as libraries to link.
target_link_libraries(compiler PRIVATE
    parser
    antlr4-runtime
    Threads::Threads
)

# Symbolic link our executable to the base directory so we don't have to go searching for it.
symlink_to_bin("compiler")

