# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gr4-incubator — experimental blocks (IIO, SoapySDR, PFB, audio)
# Depends on core. Fetch-only; no tests/examples by default.
# --------------------------------------------------------------------------

if(CONFIG_ENABLE_GR4_INCUBATOR)
    set(_EP_INCUBATOR_ARGS ${_EP_COMMON_ARGS})
    list(APPEND _EP_INCUBATOR_ARGS
        -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
        -DENABLE_EXAMPLES=${CONFIG_ENABLE_EXAMPLES}
        -DWARNINGS_AS_ERRORS=${CONFIG_WARNINGS_AS_ERRORS}
        -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
    )

    gr4_ep(gr4-incubator
        CMAKE_ARGS ${_EP_INCUBATOR_ARGS}
        DEPENDS gnuradio4-core
    )
endif()
