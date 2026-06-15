#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing wuncode from ${REPO_ROOT}"

mkdir -p "${HOME}/.wuncode"

if [ ! -d "${HOME}/.wuncode/.git" ] && [ "${REPO_ROOT}" != "${HOME}/.wuncode" ]; then
  rm -rf "${HOME}/.wuncode"
  cp -R "${REPO_ROOT}" "${HOME}/.wuncode"
fi

"${HOME}/.wuncode/wun" doctor || true

echo
echo "Run '${HOME}/.wuncode/wun preset list' to see available presets."

