# SPDX-License-Identifier: MIT
# Helper for installing gnuradio4 SDK from ephemeral build dir to stable prefix.
#
# Usage:
#   cmake -P cmake/sdk-install.cmake \
#       -DSRC=/path/to/build/dev/_install \
#       -DDEST=/opt/gnuradio4
#
# Or after a default build:
#   cmake --install build/dev --prefix /opt/gnuradio4
#
# Both are equivalent. The cmake --install approach is preferred for normal use.

if(NOT DEFINED SRC)
    message(FATAL_ERROR "SRC not set. Usage: cmake -P cmake/sdk-install.cmake -DSRC=... -DDEST=...")
endif()
if(NOT DEFINED DEST)
    message(FATAL_ERROR "DEST not set. Usage: cmake -P cmake/sdk-install.cmake -DSRC=... -DDEST=...")
endif()

if(NOT IS_DIRECTORY "${SRC}")
    message(FATAL_ERROR "Source directory does not exist: ${SRC}")
endif()

file(MAKE_DIRECTORY "${DEST}")
file(COPY "${SRC}/" DESTINATION "${DEST}")

message(STATUS "gnuradio4 SDK installed: ${SRC} -> ${DEST}")
message(STATUS "Downstream projects use: cmake ... -DCMAKE_PREFIX_PATH=${DEST}")
