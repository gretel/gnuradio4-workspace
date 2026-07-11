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
| Windows | `windows` | LLVM MinGW clang++ | Block registry OFF by default |
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
| `cmake/toolchain-*.cmake` | Platform toolchain files |
| `CMakePresets.json` | Preset definitions |
| `workspace/CMakeLists.txt` | Downstream smoke test |
| `Brewfile` | macOS system deps |

## Repos

| Repo | Branch | Holds |
|------|--------|-------|
| `gretel/gnuradio4-core` | `interim/windows-test` (5 Win32 patches) | Runtime, scheduler, blocklib |
| `gretel/gnuradio4-blocks` | `interim/windows-test` | Standard blocks (audio, SDR) |
| `gnuradio/gnuradio4-library` | `main` | DSP / algorithm library (was `gnuradio4-algorithm`) |
| `gnuradio/gr4-incubator` | `main` | Experimental blocks |
| `gnuradio/gnuradio4-control-plane` | `main` | Server, WebSocket, plugins |

Override fetch: place local checkout at repo root (e.g. `gnuradio4-core/CMakeLists.txt`).

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
- Block registry disabled by default (COFF linking)
- ~45 min build (134 TUs via QEMU)

### GIT_REV
Baked at configure time. Reconfigure (`cmake -B build/dev`) after commit to pick up new hash.

### cmake version
Requires >= 3.27.

### Lint

```sh
prek run --all-files
```
