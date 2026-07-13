# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gnuradio4-blocks — standard block implementations (depends on core + algorithm)
# Includes audio, SDR, HTTP test blocks.
# --------------------------------------------------------------------------

if(CONFIG_ENABLE_GR4_BLOCKS)
    set(_ep_blocks_args ${_ep_common_args})
    list(APPEND _ep_blocks_args
        -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
        -DENABLE_EXAMPLES=${CONFIG_ENABLE_EXAMPLES}
        -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
        -DGR4_ENABLE_AUDIO=${CONFIG_ENABLE_AUDIO}
        -DGR4_ENABLE_SDR=${CONFIG_ENABLE_SDR}
        -DGR4_ENABLE_HTTP_TESTS=${CONFIG_ENABLE_HTTP}
    )

    set(GR4_BLOCKS_GIT_TAG "main" CACHE STRING "Git ref for gnuradio4-blocks")
    set(_gr4_ep_git_tag "${GR4_BLOCKS_GIT_TAG}")
    set(_gr4_ep_git_repo_base "gretel")
    gr4_ep(gnuradio4-blocks
        CMAKE_ARGS ${_ep_blocks_args}
        DEPENDS gnuradio4-algorithm
    )
    # Reset to defaults so subsequent repos don't inherit
    set(_gr4_ep_git_tag "${GR4_GIT_TAG}")
    set(_gr4_ep_git_repo_base "gnuradio")
endif()
