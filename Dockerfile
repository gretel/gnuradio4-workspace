FROM ubuntu:24.04 AS builder
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake ninja-build ccache g++-14 make pkgconf git ca-certificates python3 \
    libcpp-httplib-dev libsoundio-dev nlohmann-json3-dev libgtest-dev libboost-dev \
    && rm -rf /var/lib/apt/lists/*
COPY . /src/gnuradio4-workspace
WORKDIR /src/gnuradio4-workspace
RUN CXX=g++-14 cmake --preset linux -DBUILD_CONFIG=full -DCMAKE_BUILD_TYPE=RelWithDebInfo
RUN CXX=g++-14 cmake --build build/dev -- -j"$(nproc)"
RUN cmake --install build/dev --prefix /opt/gnuradio4 && cp build/dev/src/gnuradio4 /opt/gnuradio4/bin/gnuradio4
FROM ubuntu:24.04
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends libsoundio2 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /opt/gnuradio4 /opt/gnuradio4
ENTRYPOINT ["/opt/gnuradio4/bin/gnuradio4"]
CMD []
