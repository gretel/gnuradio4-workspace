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
        -DGR4_ENABLE_HTTP_TESTS=${CONFIG_ENABLE_HTTP}
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

    if(WIN32 OR MINGW)
        # cmake 4.x on MinGW: CMAKE_CXX_FLAGS_INIT with -Wno-error=* flags causes
        # "The warning category is not known" error because cmake parses -Wno-error
        # flags as its own -W flags. Strip CXX_FLAGS_INIT to avoid this.
        list(FILTER _EP_CORE_ARGS EXCLUDE REGEX "CMAKE_CXX_FLAGS_INIT")
    endif()
    set(_GR4_EP_GIT_TAG "interim/windows-test")
    set(_GR4_EP_GIT_REPO_BASE "gretel")
    gr4_ep(gnuradio4-core
        CMAKE_ARGS ${_EP_CORE_ARGS}
    )
    # Reset to defaults so subsequent repos don't inherit
    set(_GR4_EP_GIT_TAG "${GR4_GIT_TAG}")
    set(_GR4_EP_GIT_REPO_BASE "gnuradio")
endif()
