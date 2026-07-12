# Windows Build Parity — Plan Context

## Current State

- Repository: `gretel/gnuradio4-workspace` (`/Users/tom/src/uhd/gnuradio4-dev`)
- Active branch: `interim/windows-test` with uncommitted local changes
- VM `miniwin` (Windows 11 ARM64, UTM QEMU, Tailscale `100.119.150.21`) has a live build in progress: 21 `ninja`/`cmake`/`clang` processes.
- The Windows build is using the `gretel/gnuradio4` fork at `C:\Users\tom\src\gnuradio4`, branch `interim/windows-test`.

## What Already Works (per memory + local state)

- PR branches `pr/windows-build` pushed to gretel forks:
  - `gretel/gnuradio4-core`
  - `gretel/gnuradio4-blocks`
  - `gretel/gnuradio4-workspace`
- Superbuild CMakeLists.txt has MinGW/Windows scaffolding:
  - `CMAKE_DL_LIBS=""`, empty `libdl.a` stub via `llvm-ar`
  - `httplib-stub` for cpp-httplib
  - Windows preset in `CMakePresets.json` (`windows`)
  - Block plugins/registry disabled on Windows (`dlopen` not available)
- `workspace/src/smoke.cpp` added as a small downstream smoke test.
- `main.exe` smoke test previously passed on Windows (block reflection, graph exec).

## Known Remaining Issues

1. **Blocks submodule compile** — currently building on miniwin; result unknown.
2. **`qa_Tags`** — `CONTEXT` identifier collides with `winnt.h` macro.
3. **`qa_thread_affinity`** — uses POSIX `SCHED_*` APIs unavailable on Windows.
4. **Superbuild clone on Windows** — `gnuradio4-dev` is private; VM could not clone it without a PAT.
5. **BlockRegistry dllexport redeclaration warning** — `BlockRegistry.hpp:157/160` warns about redeclaration with `dllexport`.
6. **`bm_Scheduler` string-literal issue** — `"out"s` / `"in"s` without `using namespace std::string_literals` (CI failure on `ci` config, both macOS and Linux).

## Constraints

- **NO opening PRs.** Branches stay ready; we fix and verify locally/CI only.
- Windows `full` profile unsupported (requires `dlopen`-based plugins).
- Cross-platform changes must not regress macOS or Linux builds.
- TDD: add/run tests, fix root causes, avoid symptom-papering.

## Definition of Done

- `cmake --preset windows -DBUILD_CONFIG=sdk && cmake --build build/dev` succeeds on miniwin.
- `ctest --test-dir build/dev/workspace --output-on-failure` passes on Windows (or known, documented failures are isolated).
- macOS and Linux `sdk`/`ci` presets still pass.
- Remaining Windows test failures (`qa_Tags`, `qa_thread_affinity`) are either fixed or explicitly excluded on Windows with comments explaining why.
- Superbuild can be cloned/built on Windows via a documented path (PAT or public transfer).
- All work committed to the gretel `pr/windows-build` branches, ready for future PR.
