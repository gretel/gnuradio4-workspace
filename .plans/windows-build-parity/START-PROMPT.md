[EXECUTING PLAN — FOLLOW THE PLAN EXACTLY]

You are executing a structured plan. Your ONLY job is to implement the plan tasks below, one at a time.

Rules:
- Work on ONE task at a time, starting with t-001
- After completing each task, IMMEDIATELY call update_task to mark it done with notes
- Do NOT run diagnostics, linters, test suites, or skills unless a task explicitly asks for it
- Do NOT explore the codebase beyond what the current task requires
- Do NOT deviate from the plan — if something seems wrong, call update_task with status "blocked"
- If you notice worthwhile work OUTSIDE the plan, call add_task to capture it, then keep going

## Current task
t-001: Monitor miniwin build → analyze results
Details: Wait for build on miniwin to finish. Check .ninja_log, compile_commands.json, stderr/stdout for errors. Check which targets succeeded/failed. Identify any new issues beyond known ones.

## Handoff
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

## All remaining tasks
t-001. Monitor miniwin build → analyze results
   Details: Wait for build on miniwin to finish. Check .ninja_log, compile_commands.json, stderr/stdout for errors. Check which targets succeeded/failed. Identify any new issues beyond known ones.

t-002. Fix blocks submodule compile issues
   Details: If blocks repo fails to compile on Windows, diagnose and fix. May involve CMake target issues, MinGW-specific code paths, or missing exports.

t-003. Fix qa_Tags test (CONTEXT vs winnt.h)
   Details: The CONTEXT identifier collides with winnt.h macro on Windows. Options: rename to gr_context or similar, #undef before use, or guard with #ifndef _WIN32.

t-004. Fix qa_thread_affinity (POSIX SCHED_*)
   Details: Test uses SCHED_FIFO/SCHED_OTHER which don't exist on Windows. Guard the test body with #ifndef _WIN32. Document why.

t-005. Fix bm_Scheduler string-literal CI failure
   Details: bm_Scheduler.cpp uses "out"s and "in"s without `using namespace std::string_literals`. Fix the source file in the pinned gnuradio4-core commit.

t-006. Solve superbuild clone on miniwin
   Details: gnuradio4-dev is private. Options: (A) request PAT via request_secret, (B) tar-pipe the repo over SSH from macOS, (C) use a shallow worktree transfer.

t-007. Suppress BlockRegistry dllexport warning
   Details: BlockRegistry.hpp:157/160 -Wdll-attribute-on-redeclaration. Guard with __declspec(dllexport) conditional on WIN32 or suppress the warning.

t-008. Cross-platform regression check
   Details: Build and test macOS (ci profile) and Linux (ci profile). Ensure no regressions from Windows changes. Fix any discovered issues.

t-009. Update docs for Windows parity status
   Details: Update README.md and AGENTS.md with current Windows build status, known test failures, workarounds, and setup instructions.

t-010. Push all fixes to pr/windows-build branches
   Details: Commit fixes to the gretel pr/windows-build branches. DO NOT open upstream PRs. Branches ready for future when user decides to submit.

Start with t-001 NOW.
