set(CMAKE_C_COMPILER /opt/homebrew/opt/llvm/bin/clang)
set(CMAKE_CXX_COMPILER /opt/homebrew/opt/llvm/bin/clang++)
# -no_warn_duplicate_libraries silences ld warnings when the same
# .a appears multiple times on the link line (common with INTERFACE
# propagation in gnuradio4's split-repo layout).
set(_lk_flags "-L/opt/homebrew/opt/llvm/lib/c++ -Wl,-rpath,/opt/homebrew/opt/llvm/lib/c++")
set(CMAKE_EXE_LINKER_FLAGS "${_lk_flags} -Wl,-no_warn_duplicate_libraries")
set(CMAKE_SHARED_LINKER_FLAGS "${_lk_flags} -Wl,-no_warn_duplicate_libraries")
set(CMAKE_MODULE_LINKER_FLAGS "-Wl,-no_warn_duplicate_libraries")

# macOS SDK sysroot — Homebrew LLVM ships without system headers.
# xcrun locates the macOS SDK provided by Xcode/CommandLineTools.
if(APPLE)
    execute_process(
        COMMAND xcrun --show-sdk-path
        OUTPUT_VARIABLE _sdk_path
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(CMAKE_OSX_SYSROOT "${_sdk_path}")
endif()
