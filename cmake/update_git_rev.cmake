# SPDX-License-Identifier: MIT
# Build-time GIT_REV update.  Resilient: writes "unknown" when .git absent.
#
# Called from CMakeLists.txt as:
#   cmake -DPATH=<srcdir> -DOUTFILE=<path> -P cmake/update_git_rev.cmake

if(NOT DEFINED PATH OR NOT DEFINED OUTFILE)
    message(FATAL_ERROR "update_git_rev.cmake: PATH and OUTFILE required")
endif()

# Pinned abbreviation length for reproducible builds (default 12).
# Passed from CMakeLists.txt; falls back to 12 if undefined.
if(NOT DEFINED ABBREV_LEN OR ABBREV_LEN STREQUAL "")
    set(ABBREV_LEN 12)
endif()

set(_rev "unknown")
if(EXISTS "${PATH}/.git")
    execute_process(
        COMMAND git rev-parse --short=${ABBREV_LEN} HEAD
        WORKING_DIRECTORY "${PATH}"
        OUTPUT_VARIABLE _rev
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)
    if(_rev STREQUAL "")
        set(_rev "unknown")
    endif()
endif()

file(WRITE "${OUTFILE}" "${_rev}")
