# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gnuradio4-blocks — standard block implementations (depends on core + algorithm)
# Includes audio, SDR, HTTP test blocks.
# --------------------------------------------------------------------------

if(CONFIG_ENABLE_GR4_BLOCKS)
    set(_EP_BLOCKS_ARGS ${_EP_COMMON_ARGS})
    list(APPEND _EP_BLOCKS_ARGS
        -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
        -DENABLE_EXAMPLES=${CONFIG_ENABLE_EXAMPLES}
        -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
        -DGR4_ENABLE_AUDIO=${CONFIG_ENABLE_AUDIO}
        -DGR4_ENABLE_SDR=${CONFIG_ENABLE_SDR}
        -DGR4_ENABLE_HTTP_TESTS=${CONFIG_ENABLE_HTTP}
    )

    set(_GR4_EP_GIT_TAG "interim/windows-test")
    set(_GR4_EP_GIT_REPO_BASE "gretel")
    gr4_ep(gnuradio4-blocks
        CMAKE_ARGS ${_EP_BLOCKS_ARGS}
        DEPENDS gnuradio4-algorithm
    )
    # Reset to defaults so subsequent repos don't inherit
    set(_GR4_EP_GIT_TAG "${GR4_GIT_TAG}")
    set(_GR4_EP_GIT_REPO_BASE "gnuradio")
endif()
