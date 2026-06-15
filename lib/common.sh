#!/usr/bin/env bash

set -euo pipefail

wun_log() {
  printf '%s\n' "$*"
}

wun_warn() {
  printf 'WARN: %s\n' "$*" >&2
}

wun_fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

wun_repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

wun_state_dir() {
  if [ -n "${WUN_STATE_DIR:-}" ]; then
    printf '%s\n' "${WUN_STATE_DIR}"
  else
    printf '%s\n' "${HOME}/.wuncode"
  fi
}

wun_state_file() {
  printf '%s/state.json\n' "$(wun_state_dir)"
}

wun_timestamp() {
  date '+%Y%m%d-%H%M%S'
}

wun_ensure_dir() {
  mkdir -p "$1"
}

wun_make_temp_dir() {
  mktemp -d "${TMPDIR:-/tmp}/wuncode.XXXXXX"
}

wun_has_command() {
  command -v "$1" >/dev/null 2>&1
}
