# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gr4-control-plane — REST API server, WebSocket transport, block registry
# Fetched from gnuradio/gnuradio4-control-plane. Depends on core.
# --------------------------------------------------------------------------

if(CONFIG_ENABLE_GR4_CONTROL_PLANE)
    set(_EP_CPLANE_ARGS ${_EP_COMMON_ARGS})
    list(APPEND _EP_CPLANE_ARGS
        -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
        -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
    )

    gr4_ep(gr4-control-plane
        GIT_REPO gnuradio4-control-plane
        CMAKE_ARGS ${_EP_CPLANE_ARGS}
        DEPENDS gnuradio4-core
    )
endif()
