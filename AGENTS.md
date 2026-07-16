# AGENTS.md

Build instructions for agents. All platforms, all configurations.

## Build

```sh
cmake --preset <platform> -DBUILD_CONFIG=<profile>
cmake --build build/dev
ctest --test-dir build/dev/workspace --output-on-failure
```

| Platform | Preset | Toolchain | Notes |
|----------|--------|-----------|-------|
| macOS | `macos` | Homebrew LLVM (brew bundle) | `xcrun` needs Xcode CLT |
| Linux | `linux` | system gcc-14+ / clang-20+ | C++23 required |
| Windows | `windows` | LLVM MinGW clang++ | Block registry OFF by default (enable with CONFIG_ENABLE_BLOCK_REGISTRY=y); `full` profile now supported |
| Cross armv7 | `cross_armv7` | Bootlin armv7-eabihf | PlutoSDR / FISH Ball |
| Cross aarch64 | `cross_aarch64` | Bootlin aarch64 | Raspberry Pi 4/5 |

## Profiles

Set via `-DBUILD_CONFIG=<profile>`:

| Profile | Defconfig | Testing | HTTP | Audio | Control-plane |
|---------|-----------|---------|------|-------|---------------|
| `sdk` | `configs/sdk_defconfig` | off | off | off | off |
| `ci` | `configs/ci_defconfig` | on (Werror) | off | off | off |
| `full` | `configs/full_defconfig` | on (Werror) | on | off | on |
| `custom` | (build dir `.config`) | as set | as set | as set | as set |

Change profile mid-stream: wipe build dir (`rm -rf build/dev`) then reconfigure.

## SDK install

Build output lands in `build/dev/_install/`. Consume:

```cmake
find_package(gnuradio4 CONFIG REQUIRED)
target_link_libraries(my_app PRIVATE gnuradio4::gnuradio-core)
```

Install to stable path:

```sh
cmake --install build/dev --prefix /opt/gnuradio4
```

## Kconfig

Interactive configurator (after first build):

```sh
cmake --build build/dev --target menuconfig
cmake -B build/dev       # regenerate after changes
```

Symbols in `Kconfig`. Build profiles pin `configs/*_defconfig`.

## Key files

| File | Role |
|------|------|
| `CMakeLists.txt` | Superbuild orchestrator (ExternalProject) |
| `Kconfig` | All config symbols, deps, prompts |
| `configs/*_defconfig` | Build profile pinning |
| `cmake/repos/*.cmake` | Per-repo ExternalProject config |
| `cmake/toolchain-macos-homebrew-llvm.cmake` | macOS Homebrew LLVM toolchain |
| `CMakePresets.json` | Preset definitions |
| `workspace/CMakeLists.txt` | Downstream smoke test |
| `Brewfile` | macOS system deps |
| `cmake/sbom.cmake` | SPDX SBOM generator (sodgeit/CMake-SBOM-Builder v0.7.0) |

## SBOM

An SPDX 2.3 SBOM (`*.spdx`) is generated during `cmake --install` via
[CMake-SBOM-Builder v0.7.0](https://github.com/sodgeit/CMake-SBOM-Builder).
The SBOM lists all installed SDK files and the enabled runtime dependencies.

### Toggle

Controlled by Kconfig symbol `ENABLE_SBOM` (default `y`).

```sh
cmake -B build/dev -DCONFIG_ENABLE_SBOM=n   # disable
```

### How to generate

```sh
cmake --install build/dev --prefix /tmp/install
ls /tmp/install/share/gnuradio4-workspace-sbom-*.spdx
```

### Dependency list (manual)

The runtime dependencies recorded in the SBOM are declared explicitly in
`CMakeLists.txt` under the `# ---- SBOM: capture installed SDK artifacts` block.
Each dependency entry must include a SPDX license identifier, version, and
supplier. The list is manually maintained — update it when adding or removing
an optional feature that introduces a new runtime dependency.

| Dependency | Kconfig gate | License |
|-----------|-------------|---------|
| `cpp-httplib` | `CONFIG_ENABLE_HTTP` | MIT |
| `SoapySDR` | `CONFIG_ENABLE_SDR` | BSL-1.0 |
| `nlohmann_json` | `CONFIG_ENABLE_GR4_CONTROL_PLANE` | MIT |
| `Boost` | `CONFIG_ENABLE_GR4_CONTROL_PLANE` | BSL-1.0 |

### Profiles

`sdk` and `ci` profiles disable HTTP and SDR, so only the SDK files are
recorded in the SBOM (no dependency packages). The `full` profile enables
HTTP and control-plane, producing a richer SBOM.

## Repos

Repo sources are configured via Kconfig (`menu "Repository sources"`). Each repo has a URL + git-ref symbol.

| Repo (target name) | Default URL | Default tag | Holds |
|---------------------|-------------|-------------|-------|
| `gnuradio4-core` | `https://github.com/gretel/gnuradio4-core.git` | `interim/windows-test` | Runtime, scheduler, blocklib |
| `gnuradio4-algorithm` | `https://github.com/gretel/gnuradio4-library.git` | `main` | DSP / algorithm library |
| `gnuradio4-blocks` | `https://github.com/gretel/gnuradio4-blocks.git` | `main` | Standard blocks (audio, SDR) |
| `gr4-incubator` | `https://github.com/gnuradio/gr4-incubator.git` | `main` | Experimental blocks |
| `gr4-control-plane` | `https://github.com/gnuradio/gnuradio4-control-plane.git` | `main` | Server, WebSocket, plugins |
| `gr4-studio` | `https://github.com/altiolabs/gr4-studio.git` | `main` | Web UI (optional) |

Override via Kconfig (`cmake --build build/dev --target menuconfig`) or `-D<SYMBOL>=<value>` on cmake command line.
Local checkout override: place repo dir at workspace root (e.g. `gnuradio4-core/CMakeLists.txt`).

## Upstream PR branches

| Repo | Branch | Status |
|------|--------|--------|
| `gretel/gnuradio4-workspace` | `pr/kconfig-repo-urls` | Kconfig repo-source configurability + gr4-studio ExternalProject |
| `gretel/gnuradio4-workspace` | `pr/pch-unity-build` | GR4_USE_PRECOMPILE_HEADERS propagation + httplib_DIR guard fix |
| `gretel/gnuradio4-core` | `interim/windows-test` | Rebased onto upstream main (c35f5c8). Win32 patches + CONTEXT_KEY |
| `gretel/gnuradio4-core` | `pr/pch-unity-build` | PCH support for test targets |
| `gretel/gnuradio4-blocks` | `main` | Rebased onto upstream (74f9d64). CONTEXT_KEY fix + missing string include |
| `gretel/gnuradio4-blocks` | `pr/pch-unity-build` | PCH support + CONTEXT_KEY fix + string include |
| `gretel/gnuradio4-library` | `main` | Rebased onto upstream (07c93162). CONTEXT_KEY fix + GR_HTTP_ENABLED option |
| `gretel/gnuradio4-library` | `pr/pch-unity-build` | PCH support + GR_HTTP_ENABLED fix |
| `gretel/gr4-control-plane` | `feat/armv7-cross-ci` | Rebased onto upstream (7410d26). Studio sinks, armv7 CI |
| `gretel/gr4-incubator` | `feat/iio-block` | Rebased onto upstream main (8182906c). IIO blocks |
| (local) `gr4-studio` | `main` | 1 commit ahead of altiolabs. Session linking. Needs gretel fork for PR |

## Gotchas

### Circular symbol deps
macOS ld64 rescans by default. Linux needs `LINK_GROUP:RESCAN` for `gnuradio-blocklib-core` + `gnuradio-core`.

### macOS linker
- `-flat_namespace` for BlockRegistry
- `-dead_strip` (not `--gc-sections`)
- `-stdlib=libc++` (Homebrew LLVM, not system)
- `-Wl,-rpath,/opt/homebrew/opt/llvm/lib/c++`

### Windows/MinGW
- No `-ldl` → `CMAKE_DL_LIBS=""` or cmake adds it anyway → create empty `libdl.a` stub via `llvm-ar rcs`
- `cpp-httplib` not always available → httplib-stub in CMakeLists.txt provides dummy target
- `thread_affinity.hpp`: `native_handle()` returns `void*` not `pthread_t` → guarded with `!defined(__MINGW32__)`
- Block registry disabled by default; the `dlopen`-based plugin loader now works on Windows via [dlfcn-win32](https://github.com/dlfcn-win32/dlfcn-win32). Enable with `CONFIG_ENABLE_BLOCK_REGISTRY=y CONFIG_ENABLE_BLOCK_PLUGINS=y`. The `full` build profile is now supported on Windows.
- `gr::tag::CONTEXT` renamed to `gr::tag::CONTEXT_KEY` to avoid collision with `winnt.h`'s `CONTEXT` typedef
- `qa_thread_affinity`: POSIX `SCHED_*` tests guarded with `not defined(_WIN32)`
- `BlockRegistry.hpp`: dllexport redeclaration warning suppressed with `-Wdll-attribute-on-redeclaration` pragma (MinGW+Clang only)
- Known test failures (Windows only): `qa_Tags` (CONTEXT reference in test), `qa_thread_affinity` (POSIX SCHED_*)
- ~45 min build (134 TUs via QEMU)
- Ninja stdout buffered by `cmd.exe` over SSH — output appears only after the process exits.
  Workarounds: build individual targets (`ninja -j1 target.exe`), redirect to a log file
  (`ninja > build.log 2>&1`), or use PowerShell `Start-Process` background jobs.

### GIT_REV
Baked at configure time. Reconfigure (`cmake -B build/dev`) after commit to pick up new hash.

### cmake version
Requires >= 3.27.

### Lint

```sh
prek run --all-files
```
