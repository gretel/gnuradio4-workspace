# gnuradio4-workspace

## Attention Please

- This is a prototype. 🚧
- It pins my forks, not the upstream ones. 🪛
- Not a lot of support can be given due to time constraints. 🧑‍🏭

## What is this?

A Superbuild for the GNU Radio 4.0 ecosystem!

## Components

| Repo | Contents |
|------|----------|
| [gnuradio4-core](https://github.com/gnuradio/gnuradio4-core) | Core runtime, scheduler, graph, block model, plugin support|
| [gnuradio4-library](https://github.com/gnuradio/gnuradio4-library) | Signal-processing algorithms  |
| [gnuradio4-blocks](https://github.com/gnuradio/gnuradio4-blocks) | Standard C++23 block libraries  |
| Your work 🌲| What makes the difference |

## Quick start

- Configure, build, and smoke-test - using comfy presets.
- Missing source dependencies are fetched from GitHub automatically.
  - Well, actually, it's a bit complicated, but you get the idea:

```sh
# ── macOS ──
cmake --preset macos -DBUILD_CONFIG=sdk
cmake --build build/dev

# ── Linux (requires gcc-14 / clang-20 as default) ──
CC=gcc-14 CXX=g++-14 cmake --preset linux -DBUILD_CONFIG=sdk
cmake --build build/dev

# ── Windows (ARM64 or x86_64, requires LLVM MinGW) ──
cmake --preset windows -DBUILD_CONFIG=sdk
cmake --build build/dev
```

## Prerequisites

```sh
# macOS
brew bundle

# Linux
sudo apt-get install -y cmake ninja-build ccache g++-14 make pkgconf

# Linux — full profile extras (add to the apt-get line above):
#   libboost-dev        – Boost (gr4-control-plane, Beast/WebSocket)
#   libcpp-httplib-dev  – HTTP / control-plane (GR4_ENABLE_HTTP)
#   nlohmann-json3-dev  – JSON for gr4-control-plane
#   libgtest-dev        – tests for gr4-control-plane
#   libsoapysdr-dev     – SDR blocks (GR4_ENABLE_SDR)
#   libsoundio-dev      – audio blocks (GR4_ENABLE_AUDIO)

# Windows (ARM64 or x86_64)
winget install -e --id Kitware.CMake
winget install -e --id Ninja-build.Ninja
winget install -e --id MartinStorsjo.LLVM-MinGW.UCRT
winget install -e --id bloodrock.pkg-config-lite
```

## Windows

> Windows support is even more experimental 🪄

- Install prerequisites with `winget` (see [Prerequisites](#prerequisites)).
- Optional libraries (cpp-httplib, nlohmann-json, GTest, SoapySDR) are
  **automatically fetched** by CMake via `FetchContent` when needed on
  Windows — no winget packages required.
- Block registry and plugins are disabled by default (the plugin loader uses `dlopen`, which is not available on Windows/MinGW). Override via `CONFIG_ENABLE_BLOCK_REGISTRY` / `CONFIG_ENABLE_BLOCK_PLUGINS` in the Windows preset.
- The `full` build profile is not supported on Windows (it enables block plugins).
- Known test issues: `qa_Tags` (`CONTEXT` identifier collision with `winnt.h`), `qa_thread_affinity` (POSIX `SCHED_*` constants not available). These are guarded at compile time.

## Configuration

- The superbuild uses **Kconfig** for all build options:
  - Symbols are defined in `Kconfig` at the project root and resolved at configure time.
  - Two orthogonal axes (⚔️) control the build:
    - **presets** pick the platform and toolchain (see [Presets](#presets))
    - while **build profiles** pick the feature set.

### Build profiles

- Predefined defconfig files in `configs/` provide ready-to-use sets of Kconfig values.
- The SDK profile is the default (`-DBUILD_CONFIG=sdk`).
- `CONFIG_ENABLE_GR4_CORE=y` auto-selects library and blocks via a Kconfig induced guru meditiation.
- Pass one via `-DBUILD_CONFIG=<profile>` at configure time:

| Profile | File | Testing | HTTP / control-plane | Use case |
|---------|------|---------|---------------------|----------|
| `sdk`  | `sdk_defconfig`  | off | off | Minimal SDK, no optional system deps needed |
| `ci`   | `ci_defconfig`   | on (Werror) | off | CI / QA, same deps as sdk |
| `full` | `full_defconfig` | on (Werror) | on | Full SDK with control-plane, requires cpp-httplib |

### Menuconfig

Now, you can toggle individual Kconfig symbols interactively:

```sh
cmake --build build/dev --target menuconfig
cmake -B build/dev   # regenerate build system from changed config
```

- Changes are written to `build/dev/.config` and persist across rebuilds.
- See below for cleansing options.

### Custom profile

For full control:
  - edit `build/dev/.config` directly and re-run `cmake -B build/dev`,
  - or create your own defconfig file and pass it with `-DBUILD_CONFIG=custom`.

### Local checkout

- Place at the repo root (e.g. `gnuradio4-core/CMakeLists.txt`) to override GitHub fetch.
- The superbuild uses it as `SOURCE_DIR` automatically.

## Cleaning

```sh
# Clean build artifacts, keep CMake cache (fastest, good for rebuilds)
cmake --build build/dev --target clean

# Wipe the build directory entirely (full reconfigure on next build)
rm -rf build/dev
```

- After a full wipe, the next `cmake --preset …` will re-fetch all external sources from scratch.
- This is also the correct way to switch between `BUILD_CONFIG` profiles — reconfigure from a clean build directory.

## CI builds

- By default all ExternalProject repos track `main`.
  - For reproducible CI runs, pin to a specific commit:

```sh
cmake --preset macos -DBUILD_CONFIG=ci -DGR4_GIT_TAG=abc1234
```

## Updating ExternalProject dependencies

- The upstream repos are fetched at configure time and cached in `build/dev/_deps/<name>/src/<name>/`.
- By default, CMake skips the update step on reconfigure (`EP_UPDATE_DISCONNECTED=ON`).

### Fast update (git pull)

- Skips repos that haven't been fetched yet or are using local checkouts.
- Pull latest from each fetched repo (respects `GR4_GIT_TAG`, works with shallow clones):

```sh
cmake --build build/dev --target update-deps
cmake --build build/dev
```

### From scratch

```sh
rm -rf build/dev
cmake --preset macos -DBUILD_CONFIG=sdk
cmake --build build/dev
```

### Toggle auto-update

```sh
# Enable auto-update on every reconfigure (requires network, prone to latency)
cmake --preset macos -DBUILD_CONFIG=sdk -DEP_UPDATE_DISCONNECTED=OFF
```

## SDK install

- Downstream CMakeLists.txt:

```cmake
find_package(gnuradio4 CONFIG REQUIRED)
target_link_libraries(my_app PRIVATE gnuradio4::gnuradio-core)
```

- Point `CMAKE_PREFIX_PATH` at the build output (`build/dev/_install/`).
- To move it to a stable system path:

```sh
cmake --install build/dev --prefix /opt/gnuradio4
```

## Attestation

- An SPDX 2.3 Software Bill of Materials (`SBOM`) is generated 
  - during `cmake --install` via [CMake-SBOM-Builder](https://github.com/sodgeit/CMake-SBOM-Builder).
- Toggle with `ENABLE_SBOM` in Kconfig (default `y`).
- For reproducible timestamps, set `SOURCE_DATE_EPOCH`.
- To verify an attested SBOM:

```sh
gh attestation verify share/gnuradio4_workspace-sbom-*.spdx --owner gretel
```

## Presets

- CMake presets define the platform, toolchain, and build directory
  - orthogonal to `-DBUILD_CONFIG` — pair any preset with any profile:

| Target | Preset | Build dir | Toolchain |
|--------|--------|-----------|-----------|
| macOS | `macos` | `build/dev` | Homebrew LLVM |
| Linux | `linux` | `build/dev` | gcc-14+ / clang-20+ |
| Windows | `windows` | `build/dev` | LLVM MinGW clang++ |

## Lint

```sh
prek run --all-files
```

## External dependencies

This repository incorporates vendored code from the following projects:

| Project | Files | License |
|---------|-------|---------|
| [cmake-kconfig](https://github.com/jameswalmsley/cmake-kconfig) | `cmake/kconfig.cmake`, `cmake/extensions.cmake`, `cmake/python.cmake`, `scripts/kconfig/kconfig.py`, `scripts/kconfig/menuconfig.py` | Apache-2.0 |
| [Kconfiglib](https://github.com/ulfalizer/Kconfiglib) | `scripts/kconfig/kconfiglib.py` | ISC |
| [CMake-SBOM-Builder](https://github.com/sodgeit/CMake-SBOM-Builder) | `cmake/sbom.cmake` | MIT |

Thank you very much! ☕🍺🌻

## License

MIT — workspace scaffolding. Sub-projects retain their own licenses.
