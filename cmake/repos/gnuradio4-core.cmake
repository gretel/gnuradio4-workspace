# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gnuradio4-core — runtime, scheduler, blocklib, meta, plugin infrastructure
# --------------------------------------------------------------------------
# Variables consumed from parent scope:
#   _EP_COMMON_ARGS, CONFIG_ENABLE_GR4_CORE, CONFIG_ENABLE_TESTING,
#   CONFIG_ENABLE_EXAMPLES, CONFIG_WARNINGS_AS_ERRORS, CONFIG_ENABLE_TBB,
#   CONFIG_ENABLE_BLOCK_REGISTRY, CONFIG_ENABLE_BLOCK_PLUGINS,
#   CONFIG_USE_FETCHCONTENT, CONFIG_ENABLE_MIT_ONLY, CONFIG_ENABLE_COVERAGE,
#   CONFIG_TIMETRACE, CONFIG_BUILD_JOBS, CONFIG_SANITIZER_ADDRESS|UB|THREAD

if(CONFIG_ENABLE_GR4_CORE)
    set(_ep_core_args ${_ep_common_args})
    list(APPEND _ep_core_args
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
    )
    if(CONFIG_SANITIZER_ADDRESS)
        list(APPEND _ep_core_args -DADDRESS_SANITIZER=ON)
    endif()
    if(CONFIG_SANITIZER_UB)
        list(APPEND _ep_core_args -DUB_SANITIZER=ON)
    endif()
    if(CONFIG_SANITIZER_THREAD)
        list(APPEND _ep_core_args -DTHREAD_SANITIZER=ON)
    endif()

    if(WIN32 OR MINGW)
        # cmake 4.x on MinGW: CMAKE_CXX_FLAGS_INIT with -Wno-error=* flags causes
        # "The warning category is not known" error because cmake parses -Wno-error
        # flags as its own -W flags. Strip CXX_FLAGS_INIT to avoid this.
        list(FILTER _ep_core_args EXCLUDE REGEX "CMAKE_CXX_FLAGS_INIT")
    endif()
    set(GR4_CORE_GIT_TAG "main" CACHE STRING "Git ref for gnuradio4-core")
    set(_gr4_ep_git_tag "${GR4_CORE_GIT_TAG}")
    set(_gr4_ep_git_repo_base "gretel")
    gr4_ep(gnuradio4-core
        CMAKE_ARGS ${_ep_core_args}
    )
    # Reset to defaults so subsequent repos don't inherit
    set(_gr4_ep_git_tag "${GR4_GIT_TAG}")
    set(_gr4_ep_git_repo_base "gnuradio")
endif()
