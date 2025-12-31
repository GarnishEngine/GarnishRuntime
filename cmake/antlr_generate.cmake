# CMake module to generate ANTLR parser and lexer from grammar files.
#
# Function: antlr_generate_parser
#   grammar_path: Full path to the .g4 grammar file
#   grammar_name: Name of the grammar (without .g4 extension) - used for output file names
#   namespace: Optional namespace for generated code
#   target_name: Name for the parser library target (default: parser_${grammar_name})
#
# Creates a static library target containing generated parser/lexer code.

function(antlr_generate_parser grammar_path grammar_name namespace target_name)
  # Verify ANTLR jar is available
  if(NOT EXISTS "${ANTLR_JAR}")
    message(FATAL_ERROR "ANTLR jar not found. Ensure get_antlr.cmake is included first.")
  endif()

  # Verify grammar file exists
  if(NOT EXISTS "${grammar_path}")
    message(FATAL_ERROR "Grammar file not found: ${grammar_path}")
  endif()

  # Setup output directory for generated sources
  # Convert namespace (with ::) to path (with /) for directory structure
  if(DEFINED namespace AND namespace)
    string(REPLACE "::" "/" namespace_path "${namespace}")
    file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}/gen/${namespace_path}" gen_dir)
  else()
    file(TO_CMAKE_PATH "${CMAKE_SOURCE_DIR}/gen" gen_dir)
  endif()

  # Build ANTLR command with optional namespace
  if(DEFINED namespace AND namespace)
    set(
      antlr_cmd
      "${Java_JAVA_EXECUTABLE}" -jar "${ANTLR_JAR}" -Werror -Dlanguage=Cpp -listener -visitor
      -o "${gen_dir}" -package "${namespace}" "${grammar_path}"
    )
  else()
    set(
      antlr_cmd
      "${Java_JAVA_EXECUTABLE}" -jar "${ANTLR_JAR}" -Werror -Dlanguage=Cpp -listener -visitor
      -o "${gen_dir}" "${grammar_path}"
    )
  endif()

  # List of generated source files (needed for dependency tracking)
  set(
    gen_src
    "${gen_dir}/${grammar_name}BaseListener.cpp"
    "${gen_dir}/${grammar_name}BaseVisitor.cpp"
    "${gen_dir}/${grammar_name}Lexer.cpp"
    "${gen_dir}/${grammar_name}Listener.cpp"
    "${gen_dir}/${grammar_name}Parser.cpp"
    "${gen_dir}/${grammar_name}Visitor.cpp"
  )

  set(
    gen_headers
    "${gen_dir}/${grammar_name}BaseListener.h"
    "${gen_dir}/${grammar_name}BaseVisitor.h"
    "${gen_dir}/${grammar_name}Lexer.h"
    "${gen_dir}/${grammar_name}Listener.h"
    "${gen_dir}/${grammar_name}Parser.h"
    "${gen_dir}/${grammar_name}Visitor.h"
  )

  # Generate parser/lexer sources from grammar
  add_custom_command(
    OUTPUT ${gen_src} ${gen_headers}
    DEPENDS antlr "${grammar_path}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${gen_dir}"
    COMMAND ${antlr_cmd}
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Generating ANTLR parser for ${grammar_name}"
  )

  # Build static library from generated sources
  add_library(${target_name} STATIC ${gen_src})
  target_include_directories(${target_name} PUBLIC ${ANTLR_INCLUDE_DIRS})
  target_link_libraries(${target_name} PUBLIC Threads::Threads)
  
  message(STATUS "Generated parser target: ${target_name} -> ${gen_dir}")
endfunction()
