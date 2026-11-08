#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
build="$root/build/web-local"
install="$root/build/web-install"
if [ -x "$build/3rdparty/basis_universal_host_tool/basis_install/bin/basisu" ]; then
    export PATH="$build/3rdparty/basis_universal_host_tool/basis_install/bin:$PATH"
fi
# The caller activates Emscripten and provides a local vcpkg checkout.
: "${VCPKG_ROOT:?Set VCPKG_ROOT to your local vcpkg checkout}"
command -v emcc >/dev/null
export EMSDK_PYTHON="${EMSDK_PYTHON:-$(command -v python3)}"
export EMSCRIPTEN_ROOT="${EMSCRIPTEN_ROOT:-$(em-config EMSCRIPTEN_ROOT)}"
if ! command -v workbox >/dev/null; then
    if [ -x "$root/build/tools/node_modules/.bin/workbox" ]; then
        export PATH="$root/build/tools/node_modules/.bin:$PATH"
    else
        printf '%s\n' 'Install workbox-cli locally with: npm install --prefix build/tools --ignore-scripts workbox-cli' >&2
        exit 1
    fi
fi
git -C "$root" submodule update --init --depth 1
cmake -S "$root" -B "$build" -DCMAKE_BUILD_TYPE=Release -DENABLE_DOCS=OFF \
    -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_TARGET_TRIPLET=wasm32-emscripten -DWZ_DISTRIBUTOR=battlewire.io \
    -DWorkboxCLI_COMMAND="$(command -v workbox)" \
    -DCMAKE_INSTALL_PREFIX="$install" "$@"
cmake --build "$build" --target install --parallel "${WZ_BUILD_JOBS:-4}"
cp "$root/COPYING" "$root/COPYING.NONGPL" "$root/COPYING.README" "$root/AUTHORS" "$install/"
"$EMSDK_PYTHON" - "$root" "$install" <<'PY'
import json, pathlib, subprocess, sys
root, output = sys.argv[1:]
commit = subprocess.check_output(['git', '-C', root, 'rev-parse', 'HEAD'], text=True).strip()
dirty = subprocess.run(['git', '-C', root, 'diff', '--quiet', 'HEAD', '--']).returncode != 0
(pathlib.Path(output) / 'source.json').write_text(json.dumps({'repository': 'https://github.com/josephdriver/warzone-2100-web', 'commit': commit, 'dirty': dirty}, indent=2) + '\n')
PY
printf 'Local web build ready: %s\n' "$install"
