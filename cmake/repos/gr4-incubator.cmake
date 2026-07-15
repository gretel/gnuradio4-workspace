# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gr4-incubator — experimental blocks (IIO, SoapySDR, PFB, audio)
# Depends on core. Fetch-only; no tests/examples by default.
# --------------------------------------------------------------------------

if(CONFIG_ENABLE_GR4_INCUBATOR)
    set(_ep_incubator_args ${_ep_common_args})
    list(APPEND _ep_incubator_args
        -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
        -DENABLE_EXAMPLES=${CONFIG_ENABLE_EXAMPLES}
        -DWARNINGS_AS_ERRORS=${CONFIG_WARNINGS_AS_ERRORS}
        -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
    )

    gr4_ep(gr4-incubator
        GIT_URL "${CONFIG_GR4_INCUBATOR_REPO_URL}"
        GIT_TAG "${CONFIG_GR4_INCUBATOR_GIT_TAG}"
        CMAKE_ARGS ${_ep_incubator_args}
        DEPENDS gnuradio4-core
    )
endif()
