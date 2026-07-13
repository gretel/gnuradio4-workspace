# gnuradio4-workspace dependency graph

```mermaid
flowchart TD
    SB[gnuradio4-workspace superbuild]
    CORE[gretel/gnuradio4-core<br/>main]
    LIB[gretel/gnuradio4-library<br/>main]
    BLOCKS[gretel/gnuradio4-blocks<br/>main]
    INC[gnuradio/gr4-incubator<br/>main]
    CP[gnuradio/gnuradio4-control-plane<br/>main]
    WS[workspace smoke test]

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

## Workspace-level workarounds

The upstream gnuradio4-core and gnuradio4-library CMakeLists.txt
unconditionally call `find_package(httplib CONFIG QUIET)` and fatal on
missing cpp-httplib, regardless of `GR4_ENABLE_HTTP_TESTS`.  The
superbuild generates a minimal stub `httplibConfig.cmake` inside the
shared install prefix when `CONFIG_ENABLE_HTTP=n` (sdk / ci profiles),
satisfying the find without needing the real library.

Similarly, gnuradio4-blocks (`main`) expects
`find_package(gnuradio4Algorithm CONFIG)`, but gnuradio4-library
installs as `gnuradio4LibraryConfig.cmake`. A thin wrapper config
bridges the naming gap until the upstream repos converge.
