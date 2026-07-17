# gnuradio4-workspace dependency graph

```mermaid
flowchart TD
    SB[gnuradio4-workspace superbuild]
    CORE[gretel/gnuradio4-core<br/>main]
    LIB[gretel/gnuradio4-library<br/>main]
    BLOCKS[gretel/gnuradio4-blocks<br/>main]
    INC[gnuradio/gr4-incubator<br/>main]
    CP[gnuradio/gnuradio4-control-plane<br/>main]
    CORE[gretel/gnuradio4-core<br/>main]<br/>+ CMP0154 & dlfcn-win32 patch
    LIB[gretel/gnuradio4-library<br/>main]
    BLOCKS[gretel/gnuradio4-blocks<br/>main]
    INC[gnuradio/gr4-incubator<br/>main]
    CP[gnuradio/gnuradio4-control-plane<br/>main]
    WS[workspace diagnostic binary + test plugin]

    SB --> CORE
    SB --> LIB
    SB --> BLOCKS
    SB --> INC
    SB --> CP
    SB --> WS

    LIB --> CORE
    BLOCKS --> CORE
    BLOCKS --> LIB
    INC --> CORE
    CP --> CORE

    CORE -->|FetchContent / system| UT[Boost.UT]
    CORE -->|FetchContent / system| VIR[vir-simd]
    CORE -->|optional tests| HTTPLIB[cpp-httplib]
    CORE -->|CMake 4.x / Win| DLFCN[dlfcn-win32]

    LIB -->|optional tests| HTTPLIB
    LIB --> EXPRTK[exprtk]

    BLOCKS -->|optional GR4_ENABLE_AUDIO| SOUNDIO[libsoundio]
    BLOCKS -->|optional GR4_ENABLE_SDR| SOAPY[SoapySDR]
    BLOCKS -->|optional GR4_ENABLE_HTTP_TESTS| HTTPLIB

    INC -->|tests / plugins / examples| HTTPLIB
    INC -->|tests / plugins| ZMQ[cppzmq]
    INC -->|examples / plugins| RTAUDIO[rtaudio]
    INC -->|examples / plugins| SOAPY
    INC -->|examples / plugins| IIO[libiio]
    INC -->|GUI examples| IMGUI[imgui / implot / glfw]
    INC -->|examples| CLI11[CLI11]

    CP -->|required| HTTPLIB
    CP -->|required| JSON[nlohmann_json]
    CP -->|tests| GTEST[GTest]
    CP -->|optional| IIO
```

## Workspace-level patches

### cpp-httplib stub

The upstream gnuradio4-core and gnuradio4-library CMakeLists.txt
unconditionally call `find_package(httplib CONFIG QUIET)` and fatal on
missing cpp-httplib, regardless of `GR4_ENABLE_HTTP_TESTS`.  The
superbuild generates a minimal stub `httplibConfig.cmake` inside the
shared install prefix when `CONFIG_ENABLE_HTTP=n` (sdk / ci profiles),
satisfying the find without needing the real library.

### gnuradio4Algorithm → gnuradio4Library rename

Similarly, gnuradio4-blocks (`main`) expects
`find_package(gnuradio4Algorithm CONFIG)`, but gnuradio4-library
installs as `gnuradio4LibraryConfig.cmake`. A thin wrapper config
bridges the naming gap until the upstream repos converge.

### CONTEXT → CONTEXT_KEY

gnuradio4-library `main` renamed `gr::tag::CONTEXT` to
`gr::tag::CONTEXT_KEY` to avoid collision with `winnt.h` on Windows,
but gnuradio4-core `main` only has `CONTEXT`.  The superbuild applies
`patches/core-context-key.patch` to add a `CONTEXT_KEY` alias to
core's `Tag.hpp`.

### CMake 4.x dl target fix (Windows)

CMake 4.x changed `ExternalProject` semantics for target include
directories.  The `dl` target (dlfcn-win32) in gnuradio4-core needs
its include directories changed from `PUBLIC` to `PRIVATE`, and
dlfcn.c added directly to gnuradio-core sources.  The superbuild
applies `patches/fix-dl-public-include.cmake` at configure time.

### Diagnostic binary & test plugin

The workspace diagnostic (`workspace/src/gnuradio4.cpp`) replaces the
earlier smoke test.  It lists available blocks, and when given a
plugin directory argument it loads and enumerates plugins from that
path.  A minimal test plugin (`workspace/src/plugin.cpp`, built as
`gr4-test-plugin`) verifies plugin loading end-to-end.
