# gnuradio4-workspace

Superbuild for the GNU Radio 4.0 split-repo ecosystem.

```
gnuradio4-core ──→ gnuradio4-library ──→ gnuradio4-blocks ──→ workspace/
```

Builds three repos in dependency order via `ExternalProject_Add`, each installing to a shared prefix. The `workspace/` directory is where you build your own flowgraph apps against the installed SDK.

## Prerequisites

```sh
# macOS
brew bundle

# Linux
sudo apt-get install -y cmake ninja-build ccache g++-14 make pkgconf

# Optional dependencies (enabled by build profile):
#   libsoundio-dev     – audio blocks (GR4_ENABLE_AUDIO)
#   libcpp-httplib-dev – HTTP tests and control-plane (GR4_ENABLE_HTTP)
#   soapysdr-dev       – SDR blocks (GR4_ENABLE_SDR)

# Windows (ARM64 or x86_64)
winget install -e --id Kitware.CMake
winget install -e --id Ninja-build.Ninja
winget install -e --id MartinStorsjo.LLVM-MinGW.UCRT
winget install -e --id bloodrock.pkg-config-lite
```

## Windows

- Install prerequisites with `winget` (see [Prerequisites](#prerequisites)).
- Block registry and plugins are disabled by default (the plugin loader uses `dlopen`, which is not available on Windows/MinGW). Override via `CONFIG_ENABLE_BLOCK_REGISTRY` / `CONFIG_ENABLE_BLOCK_PLUGINS` in the Windows preset.
- The `full` build profile is not supported on Windows (it enables block plugins).
- Known test issues: `qa_Tags` (`CONTEXT` identifier collision with `winnt.h`), `qa_thread_affinity` (POSIX `SCHED_*` constants not available). These are guarded at compile time.

## Quick start

Configure, build, and smoke-test with one platform preset. Missing source dependencies are fetched from GitHub automatically.

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

## Configuration

The superbuild uses **Kconfig** for all build options — symbols are defined in `Kconfig` at the project root and resolved at configure time.

Two orthogonal axes control the build: **presets** pick the platform and toolchain (see [Presets](#presets)), while **build profiles** pick the feature set.

### Build profiles

Predefined defconfig files in `configs/` provide ready-to-use sets of Kconfig values. Pass one via `-DBUILD_CONFIG=<profile>` at configure time:

| Profile | File | Testing | HTTP / control-plane | Use case |
|---------|------|---------|---------------------|----------|
| `sdk`  | `sdk_defconfig`  | off | off | Minimal SDK, no optional system deps needed |
| `ci`   | `ci_defconfig`   | on (Werror) | off | CI / QA, same deps as sdk |
| `full` | `full_defconfig` | on (Werror) | on | Full SDK with control-plane, requires cpp-httplib |

The SDK profile is the default (`-DBUILD_CONFIG=sdk`). `CONFIG_ENABLE_GR4_CORE=y` auto-selects library + blocks via Kconfig dependency chains.

### Interactive tuning (menuconfig)

After the first configure you can toggle individual Kconfig symbols interactively:

```sh
cmake --build build/dev --target menuconfig
cmake -B build/dev   # regenerate build system from changed config
```

Changes are written to `build/dev/.config` and persist across rebuilds. To switch to a different profile, wipe the build directory and reconfigure from scratch.

### Custom profile

For full control, edit `build/dev/.config` directly and re-run `cmake -B build/dev`, or create your own defconfig file and pass it with `-DBUILD_CONFIG=custom`.

## Quick reference

For a guided overview of presets and build profiles, see [Configuration](#configuration).

| Command | What it does |
|---------|-------------|
| `cmake --preset <platform> -DBUILD_CONFIG=<profile>` | configure |
| `cmake --build build/dev` | build all repos |
| `cmake --build build/dev --target clean` | clean build artifacts (keeps CMake cache) |
| `cmake --install build/dev --prefix <path>` | copy SDK to a stable path (e.g. `/opt/gnuradio4`) |
| `cmake --workflow --preset <platform>` | configure + build + test, one shot |
| `cmake -B build/dev` | reconfigure after profile or menuconfig changes |
| `cmake --build build/dev --target menuconfig` | interactive Kconfig TUI (see [Configuration](#configuration)) |
| `cmake --build build/dev --target update-deps` | git pull --ff-only in each fetched ExternalProject repo |
| `ctest --test-dir build/dev/workspace --output-on-failure` | workspace smoke tests |

## Cleaning

```sh
# Clean build artifacts, keep CMake cache (fastest, good for rebuilds)
cmake --build build/dev --target clean

# Wipe the build directory entirely (full reconfigure on next build)
rm -rf build/dev
```

After a full wipe, the next `cmake --preset …` will re-fetch all external sources from scratch. This is also the correct way to switch between `BUILD_CONFIG` profiles — reconfigure from a clean build directory.

## CI builds (pinning dependencies)

By default all ExternalProject repos track `main`. For reproducible CI runs, pin to a specific commit:

```sh
cmake --preset macos -DBUILD_CONFIG=ci -DGR4_GIT_TAG=abc1234
```

This applies the same ref to all three repos (core, library, blocks). Reconfigure with a clean build dir to force re-fetch.

## Updating ExternalProject dependencies

The upstream repos are fetched at configure time and cached in `build/dev/_deps/<name>/src/<name>/`. By default, CMake skips the update step on reconfigure (`EP_UPDATE_DISCONNECTED=ON`).

### Fast update (git pull)

Pull latest from each fetched repo (respects `GR4_GIT_TAG`, works with shallow clones):

```sh
cmake --build build/dev --target update-deps
cmake --build build/dev           # rebuild
```

Skips repos that haven't been fetched yet or are using local checkouts.

### Full re-fetch

Delete the cached source and build directories for specific repos, then reconfigure:

```sh
rm -rf build/dev/_deps/gnuradio4-core*
rm -rf build/dev/_deps/gnuradio4-library*
rm -rf build/dev/_deps/gnuradio4-blocks*
rm -rf build/dev/gnuradio4-core
rm -rf build/dev/gnuradio4-library
rm -rf build/dev/gnuradio4-blocks

cmake --preset macos -DBUILD_CONFIG=sdk   # reconfigure, re-fetches
cmake --build build/dev                    # rebuild
```

Or wipe the entire build directory:

```sh
rm -rf build/dev
cmake --preset macos -DBUILD_CONFIG=sdk
cmake --build build/dev
```

### Toggle auto-update

```sh
# Enable auto-update on every reconfigure (slow, needs network)
cmake --preset macos -DBUILD_CONFIG=sdk -DEP_UPDATE_DISCONNECTED=OFF
```

## SDK install

Downstream CMakeLists.txt:

```cmake
find_package(gnuradio4 CONFIG REQUIRED)
target_link_libraries(my_app PRIVATE gnuradio4::gnuradio-core)
```

Point `CMAKE_PREFIX_PATH` at the build output (`build/dev/_install/`). To move it to a stable system path:

```sh
cmake --install build/dev --prefix /opt/gnuradio4
```

## Split repos

| Repo | Contents |
|------|----------|
| [gnuradio4-core](https://github.com/gnuradio/gnuradio4-core) | Runtime, scheduler, blocklib, meta, options, plugin infra |
| [gnuradio4-library](https://github.com/gnuradio/gnuradio4-library) | DSP / algorithm library |
| [gnuradio4-blocks](https://github.com/gnuradio/gnuradio4-blocks) | Standard MIT-licensed block implementations (audio, SDR, etc.) |

Place a local checkout at the repo root (e.g. `gnuradio4-core/CMakeLists.txt`) to override GitHub fetch — the superbuild uses it as `SOURCE_DIR` automatically.

## Presets

CMake presets define the platform, toolchain, and build directory (orthogonal to `-DBUILD_CONFIG` — pair any preset with any profile):

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
| [cmake-kconfig](https://github.com/jameswalmsley/cmake-kconfig) (adapted from Zephyr RTOS) | `cmake/kconfig.cmake`, `cmake/extensions.cmake`, `cmake/python.cmake`, `scripts/kconfig/kconfig.py`, `scripts/kconfig/menuconfig.py` | Apache-2.0 |
| [Kconfiglib](https://github.com/ulfalizer/Kconfiglib) | `scripts/kconfig/kconfiglib.py` | ISC |

## License

MIT — workspace scaffolding. Sub-projects retain their own licenses.
