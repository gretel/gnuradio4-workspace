# SPDX-License-Identifier: MIT
# --------------------------------------------------------------------------
# gr4-studio — Web UI for the control-plane (optional, depends on control-plane)
# --------------------------------------------------------------------------

if(CONFIG_ENABLE_GR4_STUDIO)
    set(_ep_studio_args ${_ep_common_args})
    # gr4-studio is an npm-based frontend built by the control-plane
    list(APPEND _ep_studio_args
        -DGR4_ENABLE_STUDIO=ON
    )

    gr4_ep(gr4-studio
        GIT_URL "${CONFIG_GR4_STUDIO_REPO_URL}"
        GIT_TAG "${CONFIG_GR4_STUDIO_GIT_TAG}"
        CMAKE_ARGS ${_ep_studio_args}
        DEPENDS gr4-control-plane
    )
    unset(_ep_studio_args)
endif()
