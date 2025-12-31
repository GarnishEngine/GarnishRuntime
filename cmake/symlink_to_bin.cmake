# Function to create a symlink from a target's output to ${CMAKE_SOURCE_DIR}/bin.
# This makes executables and libraries easily accessible without navigating build directories.

function(symlink_to_bin target)
  add_custom_target(
    "symlink_${target}" ALL
    DEPENDS ${target}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_SOURCE_DIR}/bin"
    COMMAND ${CMAKE_COMMAND} -E create_symlink
      "$<TARGET_FILE:${target}>"
      "${CMAKE_SOURCE_DIR}/bin/$<TARGET_FILE_NAME:${target}>"
    COMMENT "Symlinking ${target} to ${CMAKE_SOURCE_DIR}/bin"
  )
endfunction()
