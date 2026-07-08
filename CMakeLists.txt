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

# ---- Git revision ----
execute_process(
    COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_REV OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
if(NOT GIT_REV)
    set(GIT_REV "unknown")
endif()

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
set(_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/_install")
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
    -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
    -DCMAKE_CXX_STANDARD=23
    -DCMAKE_CXX_STANDARD_REQUIRED=ON
    -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DUSE_CCACHE=${CONFIG_CACHE_CCACHE}
)
if(CMAKE_TOOLCHAIN_FILE)
    list(APPEND _EP_COMMON_ARGS -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
endif()
# Windows/MinGW: no libdl, suppress cascading -ldl link failures
if(WIN32 OR MINGW)
    list(APPEND _EP_COMMON_ARGS -DCMAKE_DL_LIBS="")
endif()

# gnuradio4-core specific args
set(_EP_CORE_ARGS ${_EP_COMMON_ARGS})
list(APPEND _EP_CORE_ARGS
    -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
    -DENABLE_EXAMPLES=${CONFIG_ENABLE_EXAMPLES}
    -DWARNINGS_AS_ERRORS=${CONFIG_WARNINGS_AS_ERRORS}
    -DENABLE_TBB=${CONFIG_ENABLE_TBB}
    -DGR_ENABLE_BLOCK_REGISTRY=${CONFIG_ENABLE_BLOCK_REGISTRY}
    -DINTERNAL_ENABLE_BLOCK_PLUGINS=${CONFIG_ENABLE_BLOCK_PLUGINS}
    -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
    -DMIT_ONLY=${CONFIG_ENABLE_MIT_ONLY}
    -DENABLE_COVERAGE=${CONFIG_ENABLE_COVERAGE}
    -DTIMETRACE=${CONFIG_TIMETRACE}
    -DPARALLEL_LEVEL=${CONFIG_BUILD_JOBS}
)
if(CONFIG_SANITIZER_ADDRESS)
    list(APPEND _EP_CORE_ARGS -DADDRESS_SANITIZER=ON)
endif()
if(CONFIG_SANITIZER_UB)
    list(APPEND _EP_CORE_ARGS -DUB_SANITIZER=ON)
endif()
if(CONFIG_SANITIZER_THREAD)
    list(APPEND _EP_CORE_ARGS -DTHREAD_SANITIZER=ON)
endif()

# gnuradio4-algorithm specific args
set(_EP_ALGORITHM_ARGS ${_EP_COMMON_ARGS})
list(APPEND _EP_ALGORITHM_ARGS
    -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
    -DENABLE_EXAMPLES=${CONFIG_ENABLE_EXAMPLES}
    -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
)

# ---- Git tag/ref for all GR4 ExternalProject repos ----
# Override with -DGR4_GIT_TAG=<sha> in CI for reproducible builds.
set(GR4_GIT_TAG "main" CACHE STRING "Git ref for all gnuradio4 ExternalProject repos")

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
            GIT_REPOSITORY "https://github.com/gnuradio/${_repo_name}.git"
            GIT_TAG ${GR4_GIT_TAG}
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

# ==== Build the three split repos in order ====

# 1. gnuradio4-core — runtime, scheduler, blocklib, meta
if(CONFIG_ENABLE_GR4_CORE)
    gr4_ep(gnuradio4-core
        CMAKE_ARGS ${_EP_CORE_ARGS}
    )
endif()

# 2. gnuradio4-algorithm — DSP / algorithm library (depends on core)
if(CONFIG_ENABLE_GR4_ALGORITHM)
    gr4_ep(gnuradio4-algorithm
        CMAKE_ARGS ${_EP_ALGORITHM_ARGS}
        DEPENDS gnuradio4-core
    )
endif()

# 3. gnuradio4-blocks — block implementations (depends on core + algorithm)
if(CONFIG_ENABLE_GR4_BLOCKS)
    set(_EP_BLOCKS_ARGS
        ${_EP_ALGORITHM_ARGS}
        -DGR4_ENABLE_AUDIO=${CONFIG_ENABLE_AUDIO}
        -DGR4_ENABLE_SDR=${CONFIG_ENABLE_SDR}
        -DGR4_ENABLE_HTTP_TESTS=${CONFIG_ENABLE_HTTP}
    )
    gr4_ep(gnuradio4-blocks
        CMAKE_ARGS ${_EP_BLOCKS_ARGS}
        DEPENDS gnuradio4-algorithm
    )
endif()

# ---- gr4-incubator (IIO, SoapySDR, PFB, audio blocks) ----
if(CONFIG_ENABLE_GR4_INCUBATOR)
    gr4_ep(gr4-incubator
        CMAKE_ARGS
            ${_EP_COMMON_ARGS}
            -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
            -DENABLE_EXAMPLES=${CONFIG_ENABLE_EXAMPLES}
            -DWARNINGS_AS_ERRORS=${CONFIG_WARNINGS_AS_ERRORS}
            -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
        DEPENDS gnuradio4-core
    )
endif()

# ---- gr4-control-plane (REST API server) ----
if(CONFIG_ENABLE_GR4_CONTROL_PLANE)
    gr4_ep(gr4-control-plane
        GIT_REPO gnuradio4-control-plane
        CMAKE_ARGS
            ${_EP_COMMON_ARGS}
            -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
            -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
        DEPENDS gnuradio4-core
    )
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

# ---- Workspace tools (diagnostic binary + smoke tests) ----
# Builds after all sub-projects; finds their installed cmake configs.
# NOTE: DEPENDS list must be built with if() not generator expressions -
# ExternalProject_Add resolves DEPENDS at configure time, not generation time.
if(CONFIG_ENABLE_GR4_CORE)
    set(_WORKSPACE_DEPENDS gnuradio4-core)
    if(CONFIG_ENABLE_GR4_ALGORITHM)
        list(APPEND _WORKSPACE_DEPENDS gnuradio4-algorithm)
    endif()
    if(CONFIG_ENABLE_GR4_BLOCKS)
        list(APPEND _WORKSPACE_DEPENDS gnuradio4-blocks)
    endif()
    ExternalProject_Add(workspace
        SOURCE_DIR "${CMAKE_SOURCE_DIR}/workspace"
        PREFIX "${CMAKE_BINARY_DIR}/_deps/workspace"
        BINARY_DIR "${CMAKE_BINARY_DIR}/workspace"
        INSTALL_DIR "${_INSTALL_PREFIX}"
        INSTALL_COMMAND ""
        CMAKE_ARGS
            -DCMAKE_INSTALL_PREFIX=${_INSTALL_PREFIX}
            -DCMAKE_PREFIX_PATH=${_INSTALL_PREFIX}
            -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
            -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
            -DGIT_REV=${GIT_REV}
            -DWORKSPACE_VERSION=${PROJECT_VERSION}
        DEPENDS ${_WORKSPACE_DEPENDS}
    )
    unset(_WORKSPACE_DEPENDS)
endif()

# ---- Top-level convenience alias ----
if(TARGET gnuradio4-core AND TARGET workspace)
    add_custom_target(all-gr4 ALL DEPENDS workspace)
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
