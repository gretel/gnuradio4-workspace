# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gnuradio4-algorithm — DSP / algorithm library (depends on core)
# --------------------------------------------------------------------------

if(CONFIG_ENABLE_GR4_ALGORITHM)
    set(_EP_ALGORITHM_ARGS ${_EP_COMMON_ARGS})
    list(APPEND _EP_ALGORITHM_ARGS
        -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
        -DENABLE_EXAMPLES=${CONFIG_ENABLE_EXAMPLES}
        -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
        -DGR4_ENABLE_HTTP_TESTS=${CONFIG_ENABLE_HTTP}
    )

    set(_GR4_EP_GIT_TAG "main")
    set(_GR4_EP_GIT_REPO_BASE "gretel")
    gr4_ep(gnuradio4-algorithm
        GIT_REPO gnuradio4-library
        CMAKE_ARGS ${_EP_ALGORITHM_ARGS}
        DEPENDS gnuradio4-core
    )
    set(_GR4_EP_GIT_TAG "${GR4_GIT_TAG}")
    set(_GR4_EP_GIT_REPO_BASE "gnuradio")
endif()
