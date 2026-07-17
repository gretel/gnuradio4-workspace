# SPDX-License-Identifier: MIT
# Patch gnuradio4-core CMakeLists for CMake 4.x + Windows dl link:
# 1. Change dl target include dirs from PUBLIC to PRIVATE
# 2. Add dlfcn.c directly to gnuradio-core sources so no extra target link needed
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt" _top)

# Fix 1: dl include dirs PUBLIC -> PRIVATE
string(REPLACE
  "target_include_directories(dl PUBLIC third_party/dlfcn-win32)"
  "target_include_directories(dl PRIVATE third_party/dlfcn-win32)"
  _top "${_top}")

# Fix 2: Remove the separate dl target, add dlfcn.c source to core/CMakeLists.txt instead
# We replace the whole dl block with nothing (it becomes a no-op since sources moved to core)
# Actually, keep the dl target but don't link to gnuradio-core from here.
# Instead, modify core/CMakeLists.txt to include dlfcn.c in gnuradio-core sources.
file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt" "${_top}")

# Fix 3: Ensure dlfcn-win32 directory exists (missing on macOS/Linux)
set(_dl_dir "${CMAKE_CURRENT_SOURCE_DIR}/third_party/dlfcn-win32")
if(NOT EXISTS "${_dl_dir}")
    file(MAKE_DIRECTORY "${_dl_dir}")
    # On non-Windows systems dlfcn.h is provided by libc, so an empty stub suffices.
    file(WRITE "${_dl_dir}/dlfcn.c" "// Stub — system dlfcn.h used instead\n")
    message(STATUS "dlfcn-win32: created stub (non-Windows)")
endif()
unset(_dl_dir)

# Fix 4: Add dlfcn.c to gnuradio-core sources in core/CMakeLists.txt
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/core/CMakeLists.txt" _core)
string(REPLACE
  "src/PluginLoader.cpp"
  "src/PluginLoader.cpp\n  ../third_party/dlfcn-win32/dlfcn.c"
  _core "${_core}")
file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/core/CMakeLists.txt" "${_core}")

message(STATUS "Patched: dl include PRIVATE, dlfcn.c added to gnuradio-core sources")
