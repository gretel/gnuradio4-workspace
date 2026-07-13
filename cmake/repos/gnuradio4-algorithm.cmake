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
        -DGR4_ENABLE_HTTP_TESTS=${CONFIG_ENABLE_HTTP}
    )

    set(GR4_LIBRARY_GIT_TAG "main" CACHE STRING "Git ref for gnuradio4-library")
    set(_gr4_ep_git_tag "${GR4_LIBRARY_GIT_TAG}")
    set(_gr4_ep_git_repo_base "gretel")
    gr4_ep(gnuradio4-algorithm
        GIT_REPO gnuradio4-library
        CMAKE_ARGS ${_ep_algorithm_args}
        DEPENDS gnuradio4-core
    )
    set(_gr4_ep_git_tag "${GR4_GIT_TAG}")
    set(_gr4_ep_git_repo_base "gnuradio")
endif()
