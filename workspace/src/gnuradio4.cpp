// SPDX-License-Identifier: MIT
// gnuradio4-workspace diagnostic entrypoint

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

#include <gnuradio-4.0/BlockRegistry.hpp>
#include <gnuradio-4.0/PluginLoader.hpp>

#ifdef _WIN32
#include <windows.h>
#endif

#ifndef GIT_REV
#define GIT_REV "unknown"
#endif

#define STRINGIFY2(x) #x
#define STRINGIFY(x)  STRINGIFY2(x)

namespace {

#if defined(__clang__)
constexpr const char* compiler_id = "Clang " STRINGIFY(__clang_major__) "." STRINGIFY(__clang_minor__) "." STRINGIFY(__clang_patchlevel__);
#elif defined(__GNUC__)
constexpr const char* compiler_id = "GCC " STRINGIFY(__GNUC__) "." STRINGIFY(__GNUC_MINOR__) "." STRINGIFY(__GNUC_PATCHLEVEL__);
#else
constexpr const char* compiler_id = "unknown";
#endif

constexpr const char* build_type_str() {
#ifdef NDEBUG
    return "Release";
#else
    return "Debug";
#endif
}

constexpr const char* platform_name() {
#if defined(__APPLE__)
    return "macOS";
#elif defined(__linux__)
    return "Linux";
#elif defined(_WIN32)
    return "Windows";
#else
    return "?";
#endif
}

constexpr const char* arch_name() {
#if defined(__aarch64__) || defined(__arm64__)
    return "arm64";
#elif defined(__arm__)
    return "armv7";
#elif defined(__x86_64__) || defined(_M_AMD64)
    return "x86_64";
#else
    return "?";
#endif
}

} // namespace

int main(int argc, char* argv[]) {
#ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
#endif

    // Optional positional argument: plugin directory path
    std::string pluginDir;
    if (argc > 1) {
        pluginDir = argv[1];
    }

    std::cout << '\n';
    std::cout << "  ▄▖▖ ▖▖▖▄▖   ▌▘  ▖▖ " << WORKSPACE_VERSION << "-" << GIT_REV << '\n';
    std::cout << "  ▌ ▛▖▌▌▌▙▘▀▌▛▌▌▛▌▙▌ " << platform_name() << " / " << arch_name() << "  " << build_type_str() << '\n';
    std::cout << "  ▙▌▌▝▌▙▌▌▌█▌▙▌▌▙▌ ▌ " << compiler_id << '\n';
    std::cout << '\n';

    // ---- Block registry / plugin loader listing ----
    std::vector<std::string> blockNames;

    if (!pluginDir.empty()) {
        gr::PluginLoader loader(gr::globalBlockRegistry(), gr::globalSchedulerRegistry(), std::vector<std::string>{pluginDir});
        blockNames = loader.availableBlocks();
        // Report any failed plugins
        for (const auto& [file, status] : loader.failedPlugins()) {
            std::cout << "  [failed] " << file << ": " << status << '\n';
        }
    } else {
        const auto& blockRegistry = gr::globalBlockRegistry();
        blockNames                = blockRegistry.keys();
    }

    std::sort(blockNames.begin(), blockNames.end());
    auto last = std::unique(blockNames.begin(), blockNames.end());
    blockNames.erase(last, blockNames.end());

    std::cout << "Available blocks (" << blockNames.size() << "):\n";
    if (blockNames.empty()) {
        std::cout << "  (none / block registry disabled)\n";
    } else {
        for (const auto& name : blockNames) {
            std::cout << "  " << name << '\n';
        }
    }
    std::cout << std::flush;

    return 0;
}
