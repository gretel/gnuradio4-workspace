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

# ---- Smoke test ----
enable_testing()

add_executable(gr4-smoke src/smoke.cpp)
target_link_libraries(gr4-smoke PRIVATE gnuradio-core gnuradio-options)

add_test(NAME gr4-smoke COMMAND gr4-smoke)
