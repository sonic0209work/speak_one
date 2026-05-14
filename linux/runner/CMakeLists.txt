cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Snap Flutter toolchain (Ubuntu 20.04 ld) cannot verify transitive-dep symbols
# from Ubuntu 24.04 system libs at link time. --allow-shlib-undefined suppresses
# those link-time checks; runtime dynamic linker resolves everything correctly.
# rpath-link keeps snap-bundled libs (e.g. libsecret) preferred over system
# copies that would otherwise surface incompatible version requirements.
if(EXISTS "/snap/flutter/current/usr/lib/x86_64-linux-gnu")
  target_link_options(${BINARY_NAME} PRIVATE
    -Wl,--allow-shlib-undefined
    -Wl,-rpath-link,/snap/flutter/current/usr/lib/x86_64-linux-gnu
  )
endif()
