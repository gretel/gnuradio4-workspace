# SPDX-License-Identifier: MIT
cmake_minimum_required(VERSION 3.27)
project(gnuradio4-workspace VERSION 4.0.0 LANGUAGES CXX)

# ---- Superbuild: orchestrates ExternalProject builds for split repos ----
# gnuradio4-core → gnuradio4-algorithm → gnuradio4-blocks
# Each installs to a shared prefix; workspace tools find_package() from there.

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ---- Kconfig configurator ----
set(PROJECT_ROOT "${CMAKE_SOURCE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${PROJECT_ROOT}/cmake")
# Help FindPython3 on Windows
if(WIN32 AND NOT Python3_EXECUTABLE)
    get_filename_component(_llvm_root "${CMAKE_CXX_COMPILER}" DIRECTORY)
    get_filename_component(_llvm_root "${_llvm_root}" DIRECTORY)
    find_program(Python3_EXECUTABLE NAMES python3 python
        HINTS "${_llvm_root}/python/bin"
        NO_DEFAULT_PATH)
    if(NOT Python3_EXECUTABLE)
        find_program(Python3_EXECUTABLE NAMES python3 python)
    endif()
    if(Python3_EXECUTABLE)
        set(Python3_EXECUTABLE "${Python3_EXECUTABLE}" CACHE FILEPATH "")
    endif()
endif()
if(NOT BUILD_CONFIG)
    set(BUILD_CONFIG "sdk" CACHE STRING "Build configuration (sdk / ci / full / custom)")
endif()
include(kconfig)

# ---- Git revision (updated at build time) ----
execute_process(
    COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_REV OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
if(NOT GIT_REV)
    set(GIT_REV "unknown")
endif()

# Build-time GIT_REV update: forces re-generation on each build
# Uses a cmake -P script for resilience — writes "unknown" when .git absent.
set(GIT_REV_FILE "${CMAKE_BINARY_DIR}/GIT_REV.txt")
file(WRITE "${GIT_REV_FILE}" "${GIT_REV}")
add_custom_target(update_git_rev ALL
    COMMAND ${CMAKE_COMMAND} -DPATH="${CMAKE_SOURCE_DIR}" -DOUTFILE=${GIT_REV_FILE}
        -P "${CMAKE_SOURCE_DIR}/cmake/update_git_rev.cmake"
    BYPRODUCTS "${GIT_REV_FILE}"
    COMMENT "Updating GIT_REV (build-time)"
    VERBATIM)

# ---- Platform-specific defaults (for this superbuild, not sub-projects) ----
if(APPLE AND CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    add_compile_options(-stdlib=libc++ -fcolor-diagnostics)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -stdlib=libc++")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options(-fdiagnostics-color=always)
endif()
# Windows/MinGW: libdl does not exist. Ensure it's not propagated
# as a transitive link dependency. Pass down as cache var to all
# ExternalProject sub-builds.
if(WIN32 OR MINGW)
    set(CMAKE_DL_LIBS "" CACHE INTERNAL "No libdl on Windows/MinGW")
endif()

# ---- Shared install prefix for all sub-projects ----
# Default: ephemeral build-dir install. Override with -DGR4_INSTALL_PREFIX
# for a stable SDK install path (e.g. /opt/gnuradio4).
set(GR4_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/_install"
    CACHE STRING "Install prefix for gnuradio4 SDK sub-projects (set to /opt/gnuradio4 for stable SDK)")
set(_INSTALL_PREFIX "${GR4_INSTALL_PREFIX}")
file(MAKE_DIRECTORY "${_INSTALL_PREFIX}")

# ---- Build ExternalProject CMAKE_ARGS lists ----
# IMPORTANT: generator expressions ($<BOOL:...>) DO NOT work in CMAKE_ARGS.
# CMAKE_ARGS are evaluated at configure time, not generation time.
# Use plain if() + list(APPEND) instead.

# Common args passed to every sub-project
set(_EP_COMMON_ARGS
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_PREFIX_PATH=${_INSTALL_PREFIX}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
    -DCMAKE_CXX_STANDARD=23
    -DCMAKE_CXX_STANDARD_REQUIRED=ON
    -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DCMAKE_COLOR_DIAGNOSTICS=OFF
    -DUSE_CCACHE=${CONFIG_CACHE_CCACHE}
    -DCMAKE_CXX_FLAGS_INIT=-Wno-psabi
)
if(CMAKE_TOOLCHAIN_FILE)
    list(APPEND _EP_COMMON_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
    # C compiler needed for cross-compilation; on native builds sub-projects auto-detect
    list(APPEND _EP_COMMON_ARGS -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER})
endif()
# Windows/MinGW: no libdl, suppress cascading -ldl link failures
if(WIN32 OR MINGW)
    list(APPEND _EP_COMMON_ARGS -DCMAKE_DL_LIBS="")
    list(APPEND _EP_COMMON_ARGS -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM})
endif()

# MinGW: create empty libdl.a stub if llvm-ar is available.
# MinGW platform defaults add -ldl to every link target; setting
# CMAKE_DL_LIBS="" is not always sufficient for shared library targets.
if(WIN32 OR MINGW)
    find_program(_LLVM_AR llvm-ar)
    if(_LLVM_AR)
        get_filename_component(_MINGW_LIB "${CMAKE_CXX_COMPILER}" DIRECTORY)
        get_filename_component(_MINGW_LIB "${_MINGW_LIB}" DIRECTORY)
        set(_DL_STUB "${_MINGW_LIB}/libdl.a")
        if(NOT EXISTS "${_DL_STUB}")
            execute_process(COMMAND ${_LLVM_AR} rcs "${_DL_STUB}")
            message(STATUS "Created MinGW libdl.a stub: ${_DL_STUB}")
        endif()
        unset(_DL_STUB)
    endif()
    unset(_LLVM_AR)
endif()

# Windows/MinGW: create httplib-stub for cpp-httplib (being removed from core)
if(WIN32 OR MINGW)
    set(_HTTPLIB_STUB_DIR "${CMAKE_BINARY_DIR}/httplib-stub/cmake")
    file(MAKE_DIRECTORY "${_HTTPLIB_STUB_DIR}")
    set(_HTTPLIB_STUB_FILE "${_HTTPLIB_STUB_DIR}/httplibConfig.cmake")
    if(NOT EXISTS "${_HTTPLIB_STUB_FILE}")
        file(WRITE "${_HTTPLIB_STUB_FILE}" [[
# SPDX-License-Identifier: MIT
# Minimal stub for cpp-httplib - provides httplib::httplib target.
# cpp-httplib is being removed from gnuradio4-core upstream; this stub
# allows the build to proceed without the actual library when HTTP
# test blocks are disabled (CONFIG_ENABLE_HTTP=n).

if(NOT TARGET httplib::httplib)
    add_library(httplib::httplib INTERFACE IMPORTED)
endif()
]])
        message(STATUS "Created httplib stub: ${_HTTPLIB_STUB_FILE}")
    endif()
    unset(_HTTPLIB_STUB_DIR)
    unset(_HTTPLIB_STUB_FILE)
endif()

# ---- Git tag/ref for all GR4 ExternalProject repos ----
# Override with -DGR4_GIT_TAG=<sha> in CI for reproducible builds.
set(GR4_GIT_TAG "main" CACHE STRING "Git ref for all gnuradio4 ExternalProject repos")
# Per-repo overrides (set in cmake/repos/*.cmake before calling gr4_ep)
set(_GR4_EP_GIT_TAG "${GR4_GIT_TAG}")
set(_GR4_EP_GIT_REPO_BASE "gnuradio")

# Controls whether ExternalProject update step runs on reconfigure.
# ON (default): no auto-update — use `update-deps` target explicitly.
# OFF: re-fetches on every cmake configure (slow, needs network).
option(EP_UPDATE_DISCONNECTED "Skip ExternalProject auto-update on reconfigure" ON)
mark_as_advanced(EP_UPDATE_DISCONNECTED)

# Collects ExternalProject names for the update-deps target.
set(_GR4_EP_NAMES)

# ---- ExternalProject helper macro ----
# Uses local checkout dir if present, otherwise fetches from GitHub.
include(ExternalProject)
macro(gr4_ep name)
    cmake_parse_arguments(_GR4 "" "GIT_REPO" "" ${ARGN})
    if(_GR4_GIT_REPO)
        set(_repo_name "${_GR4_GIT_REPO}")
        set(_src "${CMAKE_SOURCE_DIR}/${_GR4_GIT_REPO}")
    else()
        set(_repo_name "${name}")
        set(_src "${CMAKE_SOURCE_DIR}/${name}")
    endif()
    list(APPEND _GR4_EP_NAMES "${name}")
    if(EXISTS "${_src}/CMakeLists.txt")
        message(STATUS "${name}: using local ${_src}/")
        set(_dl_args SOURCE_DIR "${_src}")
    else()
        set(_dl_args
            GIT_REPOSITORY "https://github.com/${_GR4_EP_GIT_REPO_BASE}/${_repo_name}.git"
            GIT_TAG ${_GR4_EP_GIT_TAG}
            GIT_SHALLOW TRUE)
    endif()
    unset(_repo_name)
    if(EP_UPDATE_DISCONNECTED)
        ExternalProject_Add(${name}
            ${_dl_args}
            PREFIX "${CMAKE_BINARY_DIR}/_deps/${name}"
            INSTALL_DIR "${_INSTALL_PREFIX}"
            UPDATE_DISCONNECTED TRUE
            ${ARGN}
        )
    else()
        ExternalProject_Add(${name}
            ${_dl_args}
            PREFIX "${CMAKE_BINARY_DIR}/_deps/${name}"
            INSTALL_DIR "${_INSTALL_PREFIX}"
            ${ARGN}
        )
    endif()
    unset(_src)
    unset(_dl_args)
endmacro()

# ==== Include per-repo cmake files in dependency order ====
# Each file is guarded by its CONFIG_ENABLE_* flag internally.

include(${CMAKE_SOURCE_DIR}/cmake/repos/gnuradio4-core.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/repos/gnuradio4-algorithm.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/repos/gnuradio4-blocks.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/repos/gr4-incubator.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/repos/gr4-control-plane.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/repos/workspace.cmake)

# ---- install target: deploy SDK from ephemeral _INSTALL_PREFIX to stable prefix ----
# This makes `cmake --install build/dev --prefix /opt/gnuradio4` copy the SDK
# to a stable location for downstream find_package usage.
# DESTINATION "." is relative to CMAKE_INSTALL_PREFIX (set via --prefix at install time).
# When GR4_INSTALL_PREFIX was set explicitly, sub-projects already installed
# directly to the stable path, so no copy is needed.
if("${GR4_INSTALL_PREFIX}" STREQUAL "${CMAKE_BINARY_DIR}/_install")
    # Default ephemeral mode — install copies from build/_install to --prefix
    install(DIRECTORY "${CMAKE_BINARY_DIR}/_install/" DESTINATION "."
        MESSAGE_NEVER
        USE_SOURCE_PERMISSIONS)
    message(STATUS "gnuradio4 SDK: cmake --install copies from ${CMAKE_BINARY_DIR}/_install")
else()
    # Explicit GR4_INSTALL_PREFIX — sub-projects already installed to stable path
    message(STATUS "gnuradio4 SDK: installed directly to ${GR4_INSTALL_PREFIX} during build")
endif()

# ---- Custom ExternalProject repo (from Kconfig) ----
if(CUSTOM_EP_ENABLE AND DEFINED CUSTOM_EP_URL AND NOT "${CUSTOM_EP_URL}" STREQUAL "")
    set(_custom_name "${CUSTOM_EP_NAME}")
    if("${_custom_name}" STREQUAL "")
        set(_custom_name "custom-ep")
    endif()
    list(APPEND _GR4_EP_NAMES "${_custom_name}")
    message(STATUS "custom-ep: ${_custom_name} <- ${CUSTOM_EP_URL}")

    set(_custom_depends)
    if(NOT "${CUSTOM_EP_DEPENDS}" STREQUAL "")
        separate_arguments(_custom_depends UNIX_COMMAND "${CUSTOM_EP_DEPENDS}")
    endif()

    ExternalProject_Add(${_custom_name}
            GIT_REPOSITORY "${CUSTOM_EP_URL}"
        GIT_TAG "${CUSTOM_EP_TAG}"
        GIT_SHALLOW TRUE
        PREFIX "${CMAKE_BINARY_DIR}/_deps/${_custom_name}"
        INSTALL_DIR "${_INSTALL_PREFIX}"
        CMAKE_ARGS ${_EP_COMMON_ARGS}
        DEPENDS ${_custom_depends}
        EXCLUDE_FROM_ALL TRUE
    )
    unset(_custom_name _custom_depends)
endif()

# ---- update-deps: refresh fetched ExternalProject repos ----
# Runs git pull --ff-only in each fetched source directory.
# Skips repos that haven't been fetched yet or are using local checkouts.
foreach(_name ${_GR4_EP_NAMES})
    set(_sd "${CMAKE_BINARY_DIR}/_deps/${_name}/src/${_name}")
    if(NOT TARGET ${_name} OR EXISTS "${CMAKE_SOURCE_DIR}/${_name}/CMakeLists.txt")
        continue()
    endif()
    list(APPEND _update_cmds
        COMMAND ${CMAKE_COMMAND} -E echo "  -- ${_name}: git pull --ff-only"
        COMMAND git -C "${_sd}" pull --ff-only
    )
    unset(_sd)
endforeach()
if(_update_cmds)
    add_custom_target(update-deps
        COMMAND ${CMAKE_COMMAND} -E echo "Updating ExternalProject repos..."
        ${_update_cmds}
        COMMAND ${CMAKE_COMMAND} -E echo ""
        COMMAND ${CMAKE_COMMAND} -E echo "Rebuild with: cmake --build ${CMAKE_BINARY_DIR}"
        USES_TERMINAL
    )
    unset(_update_cmds)
endif()
unset(_GR4_EP_NAMES)
