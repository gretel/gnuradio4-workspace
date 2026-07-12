# Complete Windows/MinGW build parity for gnuradio4

## Handoff: Windows Build Parity

### Context
gnuradio4-workspace superbuild (`/Users/tom/src/uhd/gnuradio4-dev`) needs full Windows/MinGW parity on the `gretel/gnuradio4` fork branches (`pr/windows-build`). The core libs already compile and `main.exe` smoke test passes. Remaining work: fix test failures, verify blocks compile, get superbuild to work on the Windows VM (`miniwin`), and cross-platform regression. **Do NOT open upstream PRs.**

### Current State (2026-07-11)
- Active branch: `interim/windows-test` on gretel fork
- VM `miniwin` (100.119.150.21, Tailscale) has a full build in progress
- PR branches pushed: `gretel/gnuradio4-core`, `gretel/gnuradio4-blocks`, `gretel/gnuradio4-workspace` all on `pr/windows-build`
- Superbuild scaffolding done: CMakePresets.json (windows preset), MinGW stubs (libdl.a, httplib), plugin guard, `CMAKE_DL_LIBS=""`
- Workspace smoke test (`smoke.cpp`) added

### Key Files
- `CMakeLists.txt` — superbuild orchestrator with all Windows/MinGW scaffolding
- `CMakePresets.json` — preset definitions including `windows`
- `workspace/CMakeLists.txt` — downstream smoke test
- `workspace/src/smoke.cpp` — small smoke test executable

### Known Issues
1. **Blocks submodule compile** — currently building; result unknown
2. **`qa_Tags`** — `CONTEXT` collides with `winnt.h` macro on Windows
3. **`qa_thread_affinity`** — uses POSIX `SCHED_*`; needs `#ifndef _WIN32` guard
4. **`bm_Scheduler`** — `"out"s` / `"in"s` missing `using namespace std::string_literals` (CI `ci` config, macOS + Linux)
5. **Superbuild clone** — private repo, VM lacks PAT
6. **BlockRegistry dllexport warning** — `-Wdll-attribute-on-redeclaration`
7. **SSH rate-limit** — miniwin needs 15-45s between rapid SSH connections

### VM Access
- `sshpass -e ssh -o PreferredAuthentications=password tom@100.119.150.21` via `$MINIWIN_SSH_PASSWORD`
- cmd over SSH buffers stdout for long processes; use `cmd /c` prefix, long polls (600s+ for ninja)
- UTM internal IP: 10.0.23.172 (same auth)

### Constraints
- No opening upstream PRs
- `full` profile unsupported on Windows (dlopen)
- Changes must not regress macOS/Linux
