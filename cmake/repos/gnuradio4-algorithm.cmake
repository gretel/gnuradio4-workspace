# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gnuradio4-algorithm — DSP / algorithm library (depends on core)
# --------------------------------------------------------------------------

if(CONFIG_ENABLE_GR4_ALGORITHM)
    set(_ep_algorithm_args ${_ep_common_args})
    list(APPEND _ep_algorithm_args
        -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
        -DENABLE_EXAMPLES=${CONFIG_ENABLE_EXAMPLES}
        -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
    )

    gr4_ep(gnuradio4-algorithm
        GIT_REPO gnuradio4-library
        GIT_URL "${CONFIG_GR4_LIBRARY_REPO_URL}"
        GIT_TAG "${CONFIG_GR4_LIBRARY_GIT_TAG}"
        CMAKE_ARGS ${_ep_algorithm_args}
        DEPENDS gnuradio4-core
    )
endif()
