# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# Workspace — smoke tests against the installed SDK.
# Builds after all sub-projects; finds their installed cmake configs.
# Also defines the convenience all-gr4 alias.
# --------------------------------------------------------------------------
# NOTE: DEPENDS list must be built with if(), not generator expressions —
# ExternalProject_Add resolves DEPENDS at configure time, not generation time.

if(CONFIG_ENABLE_GR4_CORE)
    set(_workspace_depends gnuradio4-core)
    if(CONFIG_ENABLE_GR4_ALGORITHM)
        list(APPEND _workspace_depends gnuradio4-algorithm)
    endif()
    if(CONFIG_ENABLE_GR4_BLOCKS)
        list(APPEND _workspace_depends gnuradio4-blocks)
    endif()

    set(_ws_args
        -DCMAKE_INSTALL_PREFIX=${_install_prefix}
        -DCMAKE_PREFIX_PATH=${_install_prefix}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DGIT_REV=${GIT_REV}
        -DWORKSPACE_VERSION=${PROJECT_VERSION}
    )
    if(CMAKE_TOOLCHAIN_FILE)
        list(APPEND _ws_args -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER})
    endif()

    ExternalProject_Add(workspace
        SOURCE_DIR "${CMAKE_SOURCE_DIR}/workspace"
        PREFIX "${CMAKE_BINARY_DIR}/_deps/workspace"
        BINARY_DIR "${CMAKE_BINARY_DIR}/workspace"
        INSTALL_DIR "${_install_prefix}"
        INSTALL_COMMAND ""
        CMAKE_ARGS ${_ws_args}
        DEPENDS ${_workspace_depends}
    )
    unset(_workspace_depends)

    # Top-level convenience alias
    if(TARGET gnuradio4-core AND TARGET workspace)
        add_custom_target(all-gr4 ALL DEPENDS workspace
            COMMENT "Convenience alias: build all gnuradio4 sub-projects"
        )
    endif()
endif()
