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
    CORE -.->|disabled in this branch| CPR[CPR / libcurl]

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

## Option matrix

| CMake option | Repo | Default | Superbuild source | Effect |
|---|---|---|---|---|
| `GR4_ENABLE_HTTP_TESTS` | core, library, blocks | ON | `CONFIG_ENABLE_HTTP` | Build httplib-dependent tests |
| `GR4_ENABLE_AUDIO` | blocks | OFF | `CONFIG_ENABLE_AUDIO` | Build audio blocks; fatal if libsoundio missing |
| `GR4_ENABLE_SDR` | blocks | OFF | `CONFIG_ENABLE_SDR` | Build SoapySDR-based blocks |
| `CONFIG_ENABLE_HTTP` | superbuild Kconfig | y | — | Enables HTTP features (control-plane, incubator) |
| `GR_ENABLE_HTTP` | core (monorepo) | ON/OFF | — | HTTP client via CPR/libcurl (disabled in split) |

## Key decisions

- **cpp-httplib** is required only by `gr4-control-plane` and `gr4-incubator` (tests/plugins/examples).
- **libsoundio** **must** be present when `GR4_ENABLE_AUDIO=ON`; configure fails with a clear message otherwise.
- **libcurl** / **CPR** is **disabled** in the gretel core branch and the algorithm library.
- Several incubator deps (`rtaudio`, `SoapySDR`, `libiio`, `imgui`/`implot`/`glfw`) are only needed for examples/plugins/tests and are not pulled in by default profiles.
