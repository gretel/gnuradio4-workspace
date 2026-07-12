# Windows Parity Testing — Context

## Background
The windows-build-parity plan is complete. All code fixes are pushed to gretel forks:
- gretel/gnuradio4-core: CONTEXT → CONTEXT_KEY rename, thread_affinity _WIN32 guard, BlockRegistry warning suppression
- gretel/gnuradio4-workspace: docs + AGENTS.md updates

## What "do the testing" means
Run the actual test suites on Windows, macOS, and Linux to validate the fixes and catch any remaining issues. Focus on:
1. Windows `ci` preset — builds tests + benchmarks
2. macOS `ci` preset — regression check
3. Linux `ci` preset — regression check

## Windows specifics
- `sdk` profile already built successfully on miniwin
- `ci` profile enables tests/benchmarks and WARNINGS_AS_ERRORS
- Known Windows-only issues to watch for:
  - `qa_Tags` — may still reference `CONTEXT` directly in main repo test
  - `qa_thread_affinity` — SCHED_* guarded out, should pass
  - `bm_Scheduler` — string literals fix should be present

## Constraints
- No opening PRs
- Use existing branches on gretel forks
- Prefer targeted test runs over full rebuilds where possible
