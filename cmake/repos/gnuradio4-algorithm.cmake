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
    )

    gr4_ep(gnuradio4-algorithm
        CMAKE_ARGS ${_EP_ALGORITHM_ARGS}
        DEPENDS gnuradio4-core
    )
endif()
