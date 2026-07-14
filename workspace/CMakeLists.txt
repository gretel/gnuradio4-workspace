# SPDX-License-Identifier: MIT
# Workspace — builds against the installed GR4 SDK.
# Copy this to create your own flowgraph apps.

cmake_minimum_required(VERSION 3.27)
project(workspace LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---- Required: core SDK ----
find_package(gnuradio4 CONFIG REQUIRED)

# Alias targets for convenience
if(NOT TARGET gnuradio-core AND TARGET gnuradio4::gnuradio-core)
    add_library(gnuradio-core ALIAS gnuradio4::gnuradio-core)
endif()
if(NOT TARGET gnuradio-options AND TARGET gnuradio4::gnuradio-options)
    add_library(gnuradio-options ALIAS gnuradio4::gnuradio-options)
endif()
if(NOT TARGET gnuradio-blocklib-core AND TARGET gnuradio4::gnuradio-blocklib-core)
    add_library(gnuradio-blocklib-core ALIAS gnuradio4::gnuradio-blocklib-core)
endif()

# ---- Optional: algorithm library ----
find_package(gnuradio4Library QUIET)
if(gnuradio4Library_FOUND)
    if(NOT TARGET gnuradio-algorithm AND TARGET gnuradio4::gnuradio-algorithm)
        add_library(gnuradio-algorithm ALIAS gnuradio4::gnuradio-algorithm)
    endif()
    message(STATUS "workspace: gnuradio4Library found")
endif()

# ---- Optional: blocks library ----
find_package(gnuradio4Blocks QUIET)
if(gnuradio4Blocks_FOUND)
    message(STATUS "workspace: gnuradio4Blocks found")
endif()

# ---- Diagnostic binary — verify the SDK is installed and linkable ----
add_executable(gnuradio4 src/gnuradio4.cpp)
target_compile_definitions(gnuradio4 PRIVATE
    GIT_REV="${GIT_REV}"
    WORKSPACE_VERSION="${WORKSPACE_VERSION}")

# gnuradio4-core exports gnuradio-core with a bogus INTERFACE_LINK_LIBRARY
# self-reference, producing a harmless-but-noisy duplicate-libraries warning
# on Apple ld64. Silence it.
if(APPLE)
    target_link_options(gnuradio4 PRIVATE -Wl,-no_warn_duplicate_libraries)
endif()

target_link_libraries(gnuradio4 PRIVATE gnuradio-core)

if(TARGET gnuradio-blocklib-core)
    target_link_libraries(gnuradio4 PRIVATE gnuradio-blocklib-core)
endif()

# Ensure the shared block library can be found at runtime
if(APPLE AND TARGET gnuradio4::GrBasicBlocksShared)
    target_link_options(gnuradio4 PRIVATE "-Wl,-rpath,$<TARGET_FILE_DIR:gnuradio4::GrBasicBlocksShared>")
endif()
if(NOT APPLE AND TARGET gnuradio4::GrBasicBlocksShared)
    target_link_options(gnuradio4 PRIVATE "-Wl,-rpath,$<TARGET_FILE_DIR:gnuradio4::GrBasicBlocksShared>")
endif()

if(TARGET gnuradio-algorithm)
    target_link_libraries(gnuradio4 PRIVATE gnuradio-algorithm)
    target_compile_definitions(gnuradio4 PRIVATE HAVE_GNURADIO4_ALGORITHM)
endif()

if(TARGET gnuradio4::gr-basic)
    target_link_libraries(gnuradio4 PRIVATE gnuradio4::gr-basic)
    target_compile_definitions(gnuradio4 PRIVATE HAVE_GNURADIO4_BLOCKS)
endif()

# Link the actual shared block library so block registrations are available
# at runtime. Skip HTTP blocks (GrHttpBlocksShared) — they require HTTP runtime.
if(TARGET gnuradio4::GrBasicBlocksShared)
    target_link_libraries(gnuradio4 PRIVATE gnuradio4::GrBasicBlocksShared)
endif()

# ---- Smoke test ----
enable_testing()
add_test(NAME gnuradio4-smoke COMMAND gnuradio4)
