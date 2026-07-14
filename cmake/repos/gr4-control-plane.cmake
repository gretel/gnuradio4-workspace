# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gr4-control-plane — REST API server, WebSocket transport, block registry
# Fetched from gnuradio/gnuradio4-control-plane. Depends on core.
# --------------------------------------------------------------------------

if(CONFIG_ENABLE_GR4_CONTROL_PLANE)
    set(_ep_cplane_args ${_ep_common_args})
    list(APPEND _ep_cplane_args
        -DENABLE_TESTING=${CONFIG_ENABLE_TESTING}
        -DGR_USE_FETCHCONTENT_DEPS=${CONFIG_USE_FETCHCONTENT}
        # control-plane sets Boost_NO_BOOST_CMAKE ON (old module);
        # CMake 4.x removed FindBoost.cmake, so force Boost CONFIG mode.
        -DBoost_NO_BOOST_CMAKE=OFF
    )

    gr4_ep(gr4-control-plane
        GIT_REPO gnuradio4-control-plane
        CMAKE_ARGS ${_ep_cplane_args}
        DEPENDS gnuradio4-core
    )
endif()
