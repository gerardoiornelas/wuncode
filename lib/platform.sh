#!/usr/bin/env bash

set -euo pipefail

wun_detect_os() {
  case "$(uname -s)" in
    Darwin)
      printf 'macos\n'
      ;;
    Linux)
      if [ -r /etc/os-release ] && grep -qi '^ID=ubuntu' /etc/os-release; then
        printf 'ubuntu\n'
      else
        printf 'linux\n'
      fi
      ;;
    *)
      printf 'unknown\n'
      ;;
  esac
}

wun_detect_arch() {
  case "$(uname -m)" in
    arm64|aarch64)
      printf 'arm64\n'
      ;;
    x86_64)
      printf 'x86_64\n'
      ;;
    *)
      uname -m
      ;;
  esac
}

wun_platform_summary() {
  printf '%s/%s\n' "$(wun_detect_os)" "$(wun_detect_arch)"
}

