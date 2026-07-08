# SPDX-License-Identifier: MIT
# Builder stage: build GR4 workspace using upstream CI base image.
# The gnuradio-docker project (gnuradio/gnuradio-docker) provides CI images
# with all native system deps pre-installed. Use them instead of maintaining
# our own apt-get list.
#
# Build:  docker build --platform=linux/arm64 -t gr4-workspace:full .
# Run:    docker run --rm --platform=linux/arm64 gr4-workspace:full
#
# NOTE: requires a multi-arch CI image. If ghcr.io/gnuradio/ci:ubuntu-26.04-4.0
# is amd64-only on your host arch, build first with --platform or use
# docker buildx.
#
# Cross-compilation images are in ./docker/ (Dockerfile.cross-armv7, etc.)

FROM ghcr.io/gnuradio/ci:ubuntu-26.04-4.0 AS builder

COPY . /src/gnuradio4-workspace
WORKDIR /src/gnuradio4-workspace

# cmake preset selects the toolchain (gcc-14 on ubuntu-26.04)
RUN CXX=g++ cmake --preset linux -DBUILD_CONFIG=full -DCMAKE_BUILD_TYPE=RelWithDebInfo
RUN CXX=g++ cmake --build build/dev -j"$(nproc)"
RUN cmake --install build/dev --prefix /opt/gnuradio4 \
    && cp build/dev/src/gnuradio4 /opt/gnuradio4/bin/gnuradio4

# Runtime stage: minimal image with only runtime libs
FROM ghcr.io/gnuradio/ci:ubuntu-26.04-4.0
COPY --from=builder /opt/gnuradio4 /opt/gnuradio4
ENTRYPOINT ["/opt/gnuradio4/bin/gnuradio4"]
CMD []
