# gnuradio4-workspace

Superbuild for the GNU Radio 4.0 split-repo ecosystem.

```
gnuradio4-core ──→ gnuradio4-algorithm ──→ gnuradio4-blocks ──→ workspace/
```

Builds three repos in dependency order via `ExternalProject_Add`, each installing to a shared prefix. The `workspace/` directory is where you build your own flowgraph apps against the installed SDK.

## Quick start

Configure, build, and smoke-test with one platform preset. Missing deps are fetched automatically (see [Prerequisites](#prerequisites) for optional system deps).

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

> **Windows notes**
> - Install prerequisites with `winget` (see below).
> - Block registry and plugins are disabled by default (COFF linking model works differently — see `CONFIG_ENABLE_BLOCK_REGISTRY` / `CONFIG_ENABLE_BLOCK_PLUGINS` in the Windows preset).
> - `cmake --workflow` is not yet wired for Windows (no test preset).

## Quick reference

| Command | What it does |
|---------|-------------|
| `cmake --preset <platform> -DBUILD_CONFIG=<profile>` | configure (platform: `macos`/`linux`/`windows`/`cross_armv7`/`cross_aarch64`) |
| `cmake --build build/dev` | build all repos for the dev target |
| `cmake --build build/dev --target menuconfig` | interactive Kconfig TUI (requires Ninja, run after first build) |
| `cmake -B build/dev` | reconfigure after menuconfig changes |
| `cmake --build build/dev --target clean` | clean build artifacts (keeps CMake cache) |
| `cmake --workflow --preset macos` | configure + build + test, one shot (macOS / Linux only) |
| `cmake --build build/dev --target update-deps` | git pull --ff-only in each fetched ExternalProject repo |
| `ctest --test-dir build/dev/workspace --output-on-failure` | workspace smoke tests |
| `cmake --install build/dev --prefix <path>` | copy SDK to a stable path (e.g. `/opt/gnuradio4`) for shared reuse |

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

## Build profiles

Three profiles in `configs/` control what gets built:

| Profile | File | What |
|---------|------|------|
| `sdk`  | `sdk_defconfig`  | Three repos, minimal, no tests |
| `ci`   | `ci_defconfig`   | + tests + Werror + audio |
| `full` | `full_defconfig` | Full SDK: control-plane, audio, tests, examples |

The SDK profile is the default. `CONFIG_ENABLE_GR4_CORE=y` auto-selects algorithm + blocks via Kconfig dependency chains.

## Build hierarchy

Platform builds live in separate build directories:

| Target | Build dir | Use case |
|--------|-----------|----------|
| Native dev | `build/dev` | macOS, Linux, Windows |
| Cross armv7 | `build/cross-armv7` | PlutoSDR / FISH Ball (Cortex-A9) |
| Cross aarch64 | `build/cross-aarch64` | Raspberry Pi 4/5 (Cortex-A72/A76) |

Each cross target uses a Bootlin toolchain and builds in Release mode.

## Cleaning

Three options, depending on how thorough you need to be:

```sh
# 1. Clean build artifacts, keep CMake cache (fastest, good for rebuilds)
cmake --build build/dev --target clean

# 2. Wipe the build directory entirely (full reconfigure on next build)
rm -rf build/dev

# 3. Wipe a cross-compilation build directory
rm -rf build/cross-armv7
rm -rf build/cross-aarch64
```

After a full wipe (`rm -rf build/dev`), the next `cmake --preset …` will re-fetch all external sources and start from scratch. This is also the correct way to switch between `BUILD_CONFIG` profiles — reconfigure from a clean directory.

## CI builds (pinning dependencies)

By default all ExternalProject repos track `main`. For reproducible CI runs, pin to a specific commit via `-DGR4_GIT_TAG=<sha>`:

```sh
cmake --preset macos -DBUILD_CONFIG=ci -DGR4_GIT_TAG=abc1234
```

This applies the same ref to all three repos (core, algorithm, blocks). Reconfigure with a clean build dir to force re-fetch.

## Updating ExternalProject dependencies

The upstream repos are fetched at configure time and cached in `build/dev/_deps/<name>/src/<name>/`. By default, CMake skips the update step on reconfigure (`EP_UPDATE_DISCONNECTED=ON`).

### Fast update (git pull)

Pull latest from each fetched repo (respects `GR4_GIT_TAG`, works with shallow clones):

```sh
cmake --build build/dev --target update-deps
cmake --build build/dev           # rebuild
```

This runs `git pull --ff-only` in each cached source dir. Skips repos that haven't been fetched yet or are using local checkouts.

### Full re-fetch

Delete the cached source + build artifacts entirely and start from scratch:

```sh
rm -rf build/dev/_deps/gnuradio4-core*
rm -rf build/dev/_deps/gnuradio4-algorithm*
rm -rf build/dev/_deps/gnuradio4-blocks*
rm -rf build/dev/gnuradio4-core
rm -rf build/dev/gnuradio4-algorithm
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

## Prerequisites

```sh
# macOS
brew bundle

# Linux
sudo apt-get install -y cmake ninja-build ccache g++-14 make pkgconf
# Optional: libsoundio-dev libcpp-httplib-dev soapysdr-dev

# Windows (ARM64 or x86_64)
winget install -e --id Kitware.CMake
winget install -e --id Ninja-build.Ninja
winget install -e --id MartinStorsjo.LLVM-MinGW.UCRT
winget install -e --id bloodrock.pkg-config-lite
```

## Presets

| Target | Preset | Build dir | Toolchain |
|--------|--------|-----------|-----------|
| macOS | `macos` | `build/dev` | Homebrew LLVM |
| Linux | `linux` | `build/dev` | gcc-14+ / clang-20+ |
| Windows | `windows` | `build/dev` | LLVM MinGW clang++ |
| Cross armv7 | `cross_armv7` | `build/cross-armv7` | Bootlin armv7-eabihf |
| Cross aarch64 | `cross_aarch64` | `build/cross-aarch64` | Bootlin aarch64 |

## Split repos

| Repo | Contents |
|------|----------|
| [gnuradio4-core](https://github.com/gnuradio/gnuradio4-core) | Runtime, scheduler, blocklib, meta, options, plugin infra |
| [gnuradio4-algorithm](https://github.com/gnuradio/gnuradio4-algorithm) | DSP / algorithm library |
| [gnuradio4-blocks](https://github.com/gnuradio/gnuradio4-blocks) | Standard MIT-licensed block implementations (audio, SDR, etc.) |

Place a local checkout at repo root (e.g. `gnuradio4-core/CMakeLists.txt`) to override GitHub fetch — the superbuild uses it as `SOURCE_DIR` automatically.

## Lint

```sh
prek run --all-files
```

## License

MIT — workspace scaffolding. Sub-projects retain their own licenses.
