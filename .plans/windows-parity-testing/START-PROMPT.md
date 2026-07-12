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
t-001: Test Windows ci profile on miniwin VM
Details: Build and test with ci profile. Check qa_Tags, qa_thread_affinity, bm_Scheduler results.

## Handoff
# Windows Parity Testing

Run the test suites on all three platforms to validate the CONTEXT_KEY rename, thread_affinity guard, and BlockRegistry warning suppression.

## What to test

### Windows (miniwin VM)
- Build `ci` profile (tests on, WARNINGS_AS_ERRORS on)
- Run smoke test
- Run test suite (ctest)
- Watch for: qa_Tags, qa_thread_affinity, any new errors from CONTEXT rename

### macOS (local)
- Build `ci` profile
- Run smoke + ctest
- Verify no regressions from CONTEXT rename

### Linux (CI or container)
- Build `ci` profile
- Run smoke + ctest

## Infrastructure
- miniwin: ssh via ControlMaster, use forward slashes in paths
- macOS: cmake --preset macos -DBUILD_CONFIG=ci
- Linux: no local Linux host — use Docker or CI workflow

## Success criteria
- Windows `ci` builds and tests pass (or known failures match documented list)
- macOS `ci` no regressions
- Linux `ci` no regressions

## All remaining tasks
t-001. Test Windows ci profile on miniwin VM
   Details: Build and test with ci profile. Check qa_Tags, qa_thread_affinity, bm_Scheduler results.

t-002. Test macOS ci profile locally
   Details: Build and test. Verify no regressions from CONTEXT rename.

t-003. Test Linux ci (Docker or skip)
   Details: Use Docker SDK image or skip if not practical. Document findings.

t-004. Report findings and update docs
   Details: Summarize test results. Update docs if new issues found.

Start with t-001 NOW.
