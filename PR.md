# Upstream PRs — overview

## gnuradio4-blocks

| PR | Branch | Base | Description | Commits |
|----|--------|------|-------------|---------|
| 1 | `main` | `gnuradio/gnuradio4-blocks main` | Rebased onto upstream. `tag::CONTEXT`→`tag::CONTEXT_KEY` across 7 files (ClockSource, Trigger, GpsSource, PpsSource, tests). Add missing `#include <string>` + `using namespace std::literals` to `qa_apptest_LoadingPlainBlocklibs.cpp`. | 2 |
| 2 | `pr/pch-unity-build` | `main` | PCH support for test targets via `GnuRadioTestHelpers.cmake` (`target_precompile_headers`). | 1 |

## gnuradio4-core

| PR | Branch | Base | Description | Commits |
|----|--------|------|-------------|---------|
| 3 | `interim/windows-test` | `gnuradio/gnuradio4-core main` | Windows/MinGW build support. Rename `CONTEXT`→`CONTEXT_KEY` to avoid `winnt.h` collision. Suppress `-Wdll-attribute-on-redeclaration`. Fix `qa_thread_affinity` SCHED\_\* values for Windows. Make `qa_SubGraphAssets` conditional on `httplib.h`. | 6 |
| 4 | `pr/pch-unity-build` | `interim/windows-test` | PCH support for test targets. Same pattern as blocks. | 1 |
| 12 | `pr/pluginloader-windows-core` | `interim/windows-test` | Port PluginLoader to Windows/MinGW via dlfcn-win32 v1.4.2 (MIT). FetchContent downloads the library; dlfcn.c compiled as a static `dl` target and linked into `gnuradio-core`. Guard `<dlfcn.h>` in `Plugin.hpp` with `INTERNAL_ENABLE_BLOCK_PLUGINS`. Use `generic_string()` for plugin paths. Add `qa_plugin` test fixture and `qa_PluginLoader` test (block/scheduler discovery, instantiation, bad-plugin rejection). CMake 4.x compat: `dl` target include dirs PRIVATE, dlfcn.c compiled as part of `gnuradio-core` sources. | 5 |

## gnuradio4-library

| PR | Branch | Base | Description | Commits |
|----|--------|------|-------------|---------|
| 5 | `main` | `gnuradio/gnuradio4-library main` | `GR_HTTP_ENABLED` changed from hardcoded `set(OFF)` to proper `option()`. `qa_FileIo` test guarded behind it. | 1 |
| 6 | `pr/pch-unity-build` | `main` | PCH support for test targets. Same pattern as core. | 1 |

## gr4-control-plane

| PR | Branch | Base | Description | Commits |
|----|--------|------|-------------|---------|
| 7 | `feat/armv7-cross-ci` | `gnuradio/gnuradio4-control-plane main` | Rebased onto upstream. Vendored Studio sink blocks (dropped submodule). armv7 cross-compile CI. Studio WebSocket SHA1 stub for cross-build. Scheduler selection. `grc_content` in session GET. | 16 |

## gr4-incubator

| PR | Branch | Base | Description | Commits |
|----|--------|------|-------------|---------|
| 8 | `feat/iio-block` | `gnuradio/gr4-incubator main` | Rebased onto upstream. IIO blocks: IIOSource, IIOSink for libiio v0.26 (Pluto SDR / AD9361). Collision-avoidance, zero-pad DMA, sample_rate as float, ENOSYS tolerance, Soapy-convention gain naming. CI workflow uses Docker buildx. | 8 |

## gr4-studio

| PR | Branch | Base | Description | Commits |
|----|--------|------|-------------|---------|
| 9 | `main` (gretel) | `altiolabs/gr4-studio main` | Session linking from `grc_content`. NaN/transport guards. FFT buffer alignment (`gr::allocator::Aligned`). Fix YAML block-type serialization (drop `sanitizeScalar` quotes). | 2 |

## gnuradio4-workspace

Target: `gnuradio/gnuradio4-workspace` (does not exist yet — author is ready to open PRs once the org repo is created).

| PR | Branch | Description | Commits |
|----|--------|-------------|---------|
| 10 | `pr/kconfig-repo-urls` | Kconfig menu "Repository sources" with per-repo git URL + tag symbols. `gr4_ep` macro extended with `GIT_URL`/`GIT_TAG` kwargs. `cmake/repos/gr4-studio.cmake` added. Hardcoded `gretel`/`gnuradio` owner strings removed. | 4 |
| 11 | `pr/pch-unity-build` | Propagate `GR4_USE_PRECOMPILE_HEADERS` to sub-projects. Fix `httplib_DIR` unconditional propagation. | 1 |
| 13 | `pr/pluginloader-windows` | `pr/pluginloader-windows-core` core pin. Remove Windows plugin-loader fatal error and empty `libdl.a` stub. Windows preset: enable block registry + plugins + testing. Add minimal workspace test plugin (`gr4-test-plugin`) extend diagnostic binary to accept optional plugin directory and load via `gr::PluginLoader`. CMake 4.x compat patch for the `dl` target. Tested on aarch64 MinGW: `gnuradio4.exe` loads plugin and lists `gr4_workspace::TestBlock`. | 2 |
