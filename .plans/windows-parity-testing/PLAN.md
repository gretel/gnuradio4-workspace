# Test Windows parity fixes across all platforms

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
