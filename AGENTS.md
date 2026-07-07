# AGENTS.md

Build, configure, and develop the GNU Radio 4 superbuild ecosystem.
Target audience: agents and humans.

Prerequisite: `README.md` for quick start, presets, prerequisites, architecture.

---

## Build & configure

```sh
cmake --preset macos -DBUILD_CONFIG=sdk
cmake --build build/dev
./build/dev/src/gnuradio4          # smoke test
```

### Quick reference

| Command | What it does |
|---------|-------------|
| `cmake --preset macos -DBUILD_CONFIG=sdk` | configure with SDK profile (auto-detects host) |
| `cmake --build build/dev` | build all repos |
| `cmake --build build/dev --target menuconfig` then `cmake -B build/dev` | interactive Kconfig TUI |
| `cmake --preset macos -DBUILD_CONFIG=full` | reconfigure with `full` profile |
| `cmake --workflow --preset macos` | configure + build + test, one shot |
| `ctest --test-dir build/dev/workspace --output-on-failure` | run workspace smoke tests |

Windows: replace `macos` with `windows`. Linux: replace with `linux`.

### Profiles

`-DBUILD_CONFIG=sdk` — three repos, minimal, no tests
`-DBUILD_CONFIG=ci` — + tests + Werror + audio
`-DBUILD_CONFIG=full` — + control-plane, audio, tests, examples

### Presets

| Preset | Build dir | Toolchain |
|--------|-----------|-----------|
| `macos` | `build/dev` | Homebrew LLVM |
| `linux` | `build/dev` | system gcc-14+ / clang-20+ |
| `windows` | `build/dev` | LLVM MinGW clang++ |
| `cross_armv7` | `build/cross-armv7` | Bootlin armv7-eabihf |
| `cross_aarch64` | `build/cross-aarch64` | Bootlin aarch64 |

### Key files

| File | Role |
|------|------|
| `CMakeLists.txt` | Superbuild orchestrator (ExternalProject calls) |
| `Kconfig` | All config symbols, deps, prompts |
| `configs/*_defconfig` | Build profile pinning (sdk / ci / full) |
| `cmake/kconfig.cmake` | Kconfig → CMake integration |
| `cmake/toolchain-*.cmake` | Platform toolchain files |
| `workspace/CMakeLists.txt` | Workspace tools: diagnostic binary + smoke tests |
| `Brewfile` | macOS system deps |
| `Dockerfile` | Smoke-binary container image (single-stage build) |
| `docker/Dockerfile.cross-armv7` | Cross-compilation toolchain container (armv7) |
| `docker/Dockerfile.cross-aarch64` | Cross-compilation toolchain container (aarch64) |

### Lint

```sh
prek run --all-files
```

---

## Build approaches

Five ways to build GR4 composites. Each has trade-offs in rebuild speed,
reproducibility, and complexity.

### 1. Monolithic submodule

Single `add_subdirectory(gnuradio4)` via git submodule. Used by gr4-lora,
gr4-control-plane (fallback).

```sh
cmake -B build -G Ninja \
  -DGR_USE_FETCHCONTENT_DEPS=ON \
  -DGR_ENABLE_BLOCK_REGISTRY=OFF \
  -DINTERNAL_ENABLE_BLOCK_PLUGINS=OFF
cmake --build build -j$(nproc)
```

Key settings forced in parent:
```cmake
set(GR_ENABLE_HTTP "OFF" CACHE STRING "" FORCE)
set(GR_USE_FETCHCONTENT_DEPS "ON" CACHE BOOL "" FORCE)
set(GR_ENABLE_BLOCK_REGISTRY "OFF" CACHE BOOL "" FORCE)
set(INTERNAL_ENABLE_BLOCK_PLUGINS "OFF" CACHE BOOL "" FORCE)
```

Pros: single configure/build, full IDE support, circular deps handled once.
Con: gnuradio4 rebuilds every time (~100+ TUs).

### 2. Installed SDK (`find_package`)

Build gnuradio4 once into prefix, consume via `find_package`.

```sh
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=/opt/gnuradio4 \
  -DUSE_CCACHE=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TESTING=OFF
cmake --build build --parallel
cmake --install build
```

Downstream:
```cmake
find_package(gnuradio4 CONFIG)
target_link_libraries(my_app PRIVATE gnuradio4::gnuradio-core)
```

Published artifacts: `lib/cmake/gnuradio4/gnuradio4Config.cmake`,
`lib/pkgconfig/gnuradio4.pc`, `lib/gnuradio-4/plugins/` (shared block libs).

Pros: fast downstream builds, clean separation, CI-friendly.
Con: prefix must be rebuilt on gnuradio4 updates, version skew possible.

### 3. SDK container image

Published to `ghcr.io/gnuradio/gnuradio4-sdk:<sha>` (and `:main`).
Base: `ghcr.io/gnuradio/ci:ubuntu-26.04-4.0` (from `gnuradio/gnuradio-docker`).
CI: `.github/workflows/sdk-image.yml`.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/gnuradio/gnuradio4-sdk:<sha>
    steps:
      - run: cmake -S . -B build -DCMAKE_PREFIX_PATH=/opt/gnuradio4
      - run: cmake --build build --parallel
```

Local:
```sh
docker run --rm -it -v "$PWD:/work" -w /work \
  ghcr.io/gnuradio/gnuradio4-sdk:<sha> \
  bash -lc 'cmake -S . -B build -DCMAKE_PREFIX_PATH=/opt/gnuradio4; cmake --build build'
```

Pros: fully reproducible, zero host deps, CI-optimised.
Con: Linux x86_64 only, no cross-compilation, ~2 GB image.

### 4. Umbrella workspace

Repo: `mormj/gnuradio4-umbrella`. Split-repo pattern via shell scripts.
Local overlays via `repos.local.yaml`.

```sh
./scripts/bootstrap.sh              # clone all repos at pinned refs
source ./scripts/dev-env.sh         # set PATH, CMAKE_PREFIX_PATH
./scripts/build-all.sh              # build each component in dep order
./scripts/test-all.sh
```

Build layout:
```
src/gnuradio4-core/  src/gnuradio4-algorithm/  src/gnuradio4-blocks/
build/dev/gnuradio4-core/  build/dev/gnuradio4-algorithm/  ...
install/dev/
```

Pros: clean split-repo boundaries, dev/release profiles.
Con: shell scripts instead of cmake (no `compile_commands.json`),
all core repos pinned to dead `split_repos` branches.

### 5. CI cross-build

Reusable GH workflow (`_cross-build.yml`) for armv7-eabihf + aarch64
via Bootlin toolchains. Staged artifact (bin/, lib/, etc/, BUILD_INFO.txt).

Pipeline:
1. checkout + submodule init
2. install cmake, ninja, ccache, patchelf
3. cache Bootlin toolchain (key: arch + toolchain name + SoapySDR/libiio version)
4. download + verify toolchain (sha256)
5. cross-build SoapySDR 0.8.1 into sysroot (cache miss only)
6. cross-build libiio v0.26 into sysroot (armv7 only, network-only)
7. cmake configure with cross toolchain
8. build hardware apps (lora_trx, lora_scan, tx_implicit)
9. RPATH normalization (`patchelf --set-rpath '$ORIGIN/../lib'`)
10. stage + upload artifact

```sh
cmake -DCMAKE_BUILD_TYPE=Release \
  -DGR_ENABLE_BLOCK_REGISTRY=OFF \
  -DINTERNAL_ENABLE_BLOCK_PLUGINS=OFF \
  -DGR_ENABLE_HTTP=OFF \
  -DWARNINGS_AS_ERRORS=OFF \
  -DCMAKE_CXX_FLAGS=-DGR_CACHE_LINE_SIZE=64 \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-armv7-bootlin.cmake
```

| Workflow | Trigger | Arch | Retention |
|----------|---------|------|-----------|
| `ci-armv7.yml` | PR + manual | armv7-eabihf | 14 days |
| `ci-aarch64.yml` | PR + manual | aarch64 | 14 days |
| `release.yml` | tag `v*-*` + manual | matrix: both | 7 days |

Pros: real cross-compilation for ARM, portable artifact (`$ORIGIN` rpath).
Con: Linux-only runner, no armv7 emulation for test execution, ~15 min/arch.

### Comparison

| Aspect | Monolithic | Installed SDK | SDK container | Umbrella | CI cross-build |
|--------|------------|---------------|---------------|----------|----------------|
| gnuradio4 source | git submodule | installed prefix | Docker image | git clone (split) | git submodule |
| Build entry | `cmake -B build` | `find_package` | `docker pull` | shell scripts | GH Actions YAML |
| Build granularity | single tree | one prefix | multi-stage Docker | N independent trees | single tree (cross) |
| IDE support | full | full (per proj.) | none | none (scripts) | none |
| Circular deps | `LINK_GROUP:RESCAN` | resolved in prefix | resolved in image | per-component | `LINK_GROUP:RESCAN` |
| Cross-platform | native + cross | host only | Linux x86_64 only | host only | Linux → ARM |
| Rebuild trigger | submodule bump | reinstall prefix | new image tag | git pull | new commit |
| Profile system | single build type | single build type | single build type | dev/release YAML | CMake build type |

### Key deps per approach

| Dep | Monolithic | Installed SDK | SDK container | Umbrella | CI cross |
|-----|------------|---------------|---------------|----------|----------|
| cmake >= 3.27 | req | req | provided | req | provided |
| Ninja | opt | opt | provided | opt | provided |
| gcc >= 15 / clang >= 20 | req | req | provided | req | provided |
| libc++ (macOS) | forced in parent | N/A | N/A | dev-env | N/A |
| Homebrew LLVM | req (macOS) | N/A | N/A | opt | N/A |
| libsoundio | brew install | N/A | provided | N/A | N/A |
| SoapySDR | brew/pkg-config | N/A | N/A | N/A | cross-built |
| libiio | brew/pkg-config | N/A | N/A | N/A | cross-built |
| cpp-httplib | FetchContent | in prefix | provided | FetchContent | not needed |
| Boost.UT | FetchContent | in prefix | provided | FetchContent | not needed |
| Docker | opt | N/A | req | N/A | GH runner |
| Bootlin toolchain | N/A | N/A | N/A | N/A | req |

---

## Development

Entry point for developing GR4 and its components.

### Component repos

```
gnuradio4-core ──→ gnuradio4-algorithm ──→ gnuradio4-blocks
     │                      │                      │
     └── gr4-incubator      └── gr4-control-plane
                                     └── gr4-studio
```

| Repo | Contains | Upstream |
|------|----------|----------|
| `gnuradio4-core` | Runtime, scheduler, blocklib, meta, options, plugin infra | gnuradio/gnuradio4-core |
| `gnuradio4-algorithm` | DSP / algorithm library | gnuradio/gnuradio4-algorithm |
| `gnuradio4-blocks` | Standard MIT-licensed blocks (audio, SDR, etc.) | gnuradio/gnuradio4-blocks |
| `gr4-incubator` | Experimental blocks (IIO, PlutoSDR, etc.) | gnuradio/gr4-incubator |
| `gnuradio4-control-plane` | Server, registry, plugins, WebSocket transport | gnuradio/gnuradio4-control-plane |
| `gnuradio4-studio` | Web-based flowgraph IDE + sinks | gnuradio/gnuradio4-studio |
| `gr4-lora` | LoRa PHY blocks + apps (lora_trx, lora_scan) | gretel/gr4-lora |

### Local checkout overrides

Place a repo at root with `CMakeLists.txt` (e.g. `gnuradio4-core/`) → superbuild
uses it as `SOURCE_DIR` instead of fetching from GitHub.

### Superbuild tasks

| Task | What |
|------|------|
| Add a component | `ExternalProject_Add(...)` in `CMakeLists.txt`, Kconfig symbol in `Kconfig` |
| Change build flags | `CMAKE_CACHE_ARGS` on the `ExternalProject_Add` call |
| Pin a commit | Change `GIT_TAG` in the `ExternalProject_Add` call |
| Use local checkout | Place repo at root — auto-detected |

### Testing

```sh
cmake --workflow --preset macos
ctest --test-dir build/dev/workspace --output-on-failure
ctest --test-dir build/dev/workspace -R <test-name> --output-on-failure
```

### Block authoring

Pattern: inherit `block<PortIn, PortOut>`, override `processBulk`,
use `GR_MAKE_REFLECTABLE` for port reflection.
- API: `core/include/gnuradio-4.0/block/*.hpp`
- Skill: `gr4-blocks` (processBulk, tags, scheduler, telemetry)

### Cross-compilation

| Target | Preset | Dockerfile | HW |
|--------|--------|-----------|----|
| armv7-eabihf | `cross_armv7` | `docker/Dockerfile.cross-armv7` | FISH Ball / PlutoSDR (Cortex-A9) |
| aarch64 | `cross_aarch64` | `docker/Dockerfile.cross-aarch64` | Raspberry Pi 4/5 (Cortex-A72/A76) |

```sh
cmake --preset cross_armv7 -DBUILD_CONFIG=sdk
cmake --build build/cross-armv7
```

---

## Agent skills

| Skill | Use when… |
|-------|-----------|
| `gr4-dev` | Build, test, lint, commit, deploy gr4-lora |
| `gr4-blocks` | Author/debug blocks (processBulk, tags, scheduler) |
| `gr4-review` | Pre-merge QA, portability review, upstream PR |
| `gr4-studio-dev` | Build/run gr4-studio frontend + gr4cp_server backend |
| `perf-investigation` | Scheduler stalls, overflows, cycle budget |
| `hw-testing` | RF hardware A/B decode/scan quality validation |
| `lora-telemetry-dev` | Decoder quality metrics, DuckDB dashboard |
| `dc-spur-mitigation` | Zero-IF DC spike removal (LO offset, DSP) |

Generic: `cpp-core-guidelines`, `rust-engineer`, `uhd-dev`, `soapy-dev`,
`iio-dev`, `cbor`, `meshcore`, `tezuka-dev`, `sdrangel-dev`,
`tinysa-validation`, `verilog`/`vivado-*`, `chirpmunk-dev`.

---

## Key gotchas

- **Sign all commits**: `git commit -S`, conventional commits, imperative mood.
  No AI prose or test dumps in messages.
- **Circular symbol deps**: macOS ld64 rescans by default. Linux needs
  `LINK_GROUP:RESCAN` for `gnuradio-blocklib-core` + `gnuradio-core`.
- **macOS**: Homebrew LLVM, `-stdlib=libc++`, `-flat_namespace` (global
  BlockRegistry), `-dead_strip` (not `--gc-sections`).
- **Windows**: No `-ldl` (use `CMAKE_DL_LIBS`), no block registry by default,
  LLVM MinGW + libc++.
- **GIT_REV** baked at configure time — reconfigure after commit.
- **Kconfig**: Build profiles pin `configs/*_defconfig`. Custom `.config` in
  build dir (untracked).
- **Cross-build CI**: bump `cache_key_suffix` on toolchain/cache issues.
  Submodule refs must be on remote `main` or push ref via `git push origin <sha>:main`.

---

## See also

- `README.md` — quick start, architecture, prerequisites
- `Kconfig` — all config symbols with prompts and dependencies
- `CMakePresets.json` — CMake preset definitions
- `cmake/kconfig.cmake` — Kconfig-to-CMake integration
- `scripts/` — bootstrap and CI helpers
