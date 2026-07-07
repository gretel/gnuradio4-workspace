#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
#
# Local test matrix for gnuradio4-workspace.
# Runs configure + build + smoke-test across all platform targets.
#
# Usage:
#   ./scripts/test-matrix.sh                  # run all targets
#   ./scripts/test-matrix.sh macos            # single target
#   ./scripts/test-matrix.sh macos docker     # subset
#
# Targets:
#   macos       macOS native (arm64, Homebrew LLVM)
#   linux-vm    Linux VM via SSH (tom@bld.jitter.local)
#   win-vm      Windows VM via SSH (tom@10.0.23.172)
#   docker      Docker: linux (native build container)
#   docker-arm  Docker: cross armv7 (PlutoSDR/FISH Ball)
#   docker-arm64 Docker: cross aarch64 (Raspberry Pi)
#
# Each target tests sdk and ci (or full for docker-linux) profiles.

set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo "${0%/*}/..")"

BUILD_DIR_DEFAULT="build/test"
SSH_LINUX="tom@bld.jitter.local"
SSH_WIN="tom@10.0.23.172"
DOCKER_CONTEXT="${DOCKER_CONTEXT:-orbstack}"

results=()
pass=0
fail=0

pass()  { results+=("PASS  $*"); ((pass++)); }
fail()  { results+=("FAIL  $*"); ((fail++)); echo "  ^ $*"; }
run()   { echo; echo "━━━ $* ━━━"; "$@"; }

# ── macOS native ──
test_macos() {
    for config in sdk ci full; do
        local tag="macos/${config}"
        run cmake -B "${BUILD_DIR_DEFAULT}-macos-${config}" -G Ninja \
            --toolchain cmake/toolchain-macos-homebrew-llvm.cmake \
            -DBUILD_CONFIG="${config}" \
            -DCMAKE_BUILD_TYPE=RelWithDebInfo 2>&1 | tail -3 || { fail "${tag} configure"; continue; }
        run cmake --build "${BUILD_DIR_DEFAULT}-macos-${config}" -- -j$(sysctl -n hw.logicalcpu) 2>&1 | tail -5 || { fail "${tag} build"; continue; }
        "${BUILD_DIR_DEFAULT}-macos-${config}/src/gnuradio4" && pass "${tag}" || fail "${tag} smoke"
        run rm -rf "${BUILD_DIR_DEFAULT}-macos-${config}"
    done
}

# ── Linux VM (SSH) ──
test_linux_vm() {
    local host="$1"
    local build_dir="build/test-linux"
    for config in sdk ci full; do
        local tag="linux-vm/${config}"
        ssh "${host}" "cd gnuradio4-dev && rm -rf ${build_dir} && \
            cmake -B ${build_dir} -G Ninja --preset linux -DBUILD_CONFIG=${config} -DCMAKE_BUILD_TYPE=RelWithDebInfo 2>&1 | tail -3" || { fail "${tag} configure"; continue; }
        ssh "${host}" "cd gnuradio4-dev && cmake --build ${build_dir} -- -j\$(nproc) 2>&1 | tail -5" || { fail "${tag} build"; continue; }
        ssh "${host}" "cd gnuradio4-dev && ${build_dir}/src/gnuradio4" && pass "${tag}" || fail "${tag} smoke"
        ssh "${host}" "cd gnuradio4-dev && rm -rf ${build_dir}"
    done
}

# ── Windows VM (SSH) ──
test_win_vm() {
    local host="$1"
    local build_dir="build/test-win"
    for config in sdk ci; do
        local tag="win-vm/${config}"
        # Windows preset with build_config overrides to disable plugins/registry
        ssh "${host}" "cd gnuradio4-dev && if exist ${build_dir} rmdir /s /q ${build_dir} && \
            cmake -B ${build_dir} -G Ninja --preset windows -DBUILD_CONFIG=${config} -DCMAKE_BUILD_TYPE=RelWithDebInfo" || { fail "${tag} configure"; continue; }
        ssh "${host}" "cd gnuradio4-dev && cmake --build ${build_dir}" || { fail "${tag} build"; continue; }
        ssh "${host}" "cd gnuradio4-dev && ${build_dir}/src/gnuradio4.exe" && pass "${tag}" || fail "${tag} smoke"
        ssh "${host}" "cd gnuradio4-dev && if exist ${build_dir} rmdir /s /q ${build_dir}"
    done
}

# ── Docker: Linux native build ──
test_docker_linux() {
    local tag="docker/linux"
    DOCKER_CONTEXT="${DOCKER_CONTEXT}" docker build -f Dockerfile -t gr4-test:linux . 2>&1 | tail -3 || { fail "${tag} build"; return; }
    DOCKER_CONTEXT="${DOCKER_CONTEXT}" docker run --rm gr4-test:linux && pass "${tag}" || fail "${tag} smoke"
}

# ── Docker: cross armv7 ──
test_docker_armv7() {
    local tag="docker/armv7"
    DOCKER_CONTEXT="${DOCKER_CONTEXT}" docker build -f docker/Dockerfile.cross-armv7 -t gr4-test:armv7 . 2>&1 | tail -5 || { fail "${tag} build"; return; }
    local out
    out=$(DOCKER_CONTEXT="${DOCKER_CONTEXT}" docker run --rm --entrypoint file gr4-test:armv7 /opt/gnuradio4/bin/gnuradio4 2>&1)
    if echo "$out" | grep -q 'ELF 32-bit.*ARM'; then
        pass "${tag} (valid ARM32 ELF)"
    else
        fail "${tag} (unexpected format: $out)"
    fi
}

# ── Docker: cross aarch64 ──
test_docker_arm64() {
    local tag="docker/aarch64"
    DOCKER_CONTEXT="${DOCKER_CONTEXT}" docker build -f docker/Dockerfile.cross-aarch64 -t gr4-test:aarch64 . 2>&1 | tail -5 || { fail "${tag} build"; return; }
    local out
    out=$(DOCKER_CONTEXT="${DOCKER_CONTEXT}" docker run --rm --entrypoint file gr4-test:aarch64 /opt/gnuradio4/bin/gnuradio4 2>&1)
    if echo "$out" | grep -q 'ELF 64-bit.*ARM aarch64'; then
        pass "${tag} (valid ARM64 ELF)"
    else
        fail "${tag} (unexpected format: $out)"
    fi
}

# ── Dispatch ──
targets=()
if [[ $# -eq 0 ]]; then
    targets=(macos linux-vm win-vm docker docker-arm docker-arm64)
else
    targets=("$@")
fi

for t in "${targets[@]}"; do
    case "$t" in
        macos)       test_macos ;;
        linux-vm)    test_linux_vm "${SSH_LINUX}" ;;
        win-vm)      test_win_vm "${SSH_WIN}" ;;
        docker)      test_docker_linux ;;
        docker-arm)  test_docker_armv7 ;;
        docker-arm64) test_docker_arm64 ;;
        *)           echo "unknown target: $t (valid: macos linux-vm win-vm docker docker-arm docker-arm64)" ;;
    esac
done

# ── Summary ──
echo
echo "═══════════════════════════════════"
echo "  Test matrix results"
echo "═══════════════════════════════════"
for r in "${results[@]}"; do echo "  $r"; done
echo "───────────────────────────────────"
echo "  ${pass} passed, ${fail} failed"
echo "═══════════════════════════════════"
exit "$(( fail > 0 ? 1 : 0 ))"