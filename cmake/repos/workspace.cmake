# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# Workspace — diagnostic binary + smoke tests
# Builds after all sub-projects; finds their installed cmake configs.
# Also defines the convenience all-gr4 alias.
# --------------------------------------------------------------------------
# NOTE: DEPENDS list must be built with if(), not generator expressions —
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

    # Top-level convenience alias
    if(TARGET gnuradio4-core AND TARGET workspace)
        add_custom_target(all-gr4 ALL DEPENDS workspace)
    endif()
endif()
