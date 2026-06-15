#!/usr/bin/env bash

set -euo pipefail

wun_ollama_installed() {
  wun_has_command ollama
}

wun_ollama_endpoint() {
  printf 'http://localhost:11434\n'
}

wun_ollama_variant_name() {
  case "$1" in
    *-32k)
      printf '%s\n' "$1"
      ;;
    *)
      printf '%s-32k\n' "$1"
      ;;
  esac
}

wun_ollama_base_model_name() {
  case "$1" in
    *-32k)
      printf '%s\n' "${1%-32k}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

wun_pull_model() {
  local requested_model="${1:-}"
  [ -n "${requested_model}" ] || wun_fail "Usage: wun pull-model <model>"

  if ! wun_ollama_installed; then
    wun_fail "Ollama is not installed"
  fi

  if ! wun_ollama_running; then
    wun_fail "Ollama is not running. Run 'wun ollama start' first."
  fi

  local base_model variant
  base_model="$(wun_ollama_base_model_name "${requested_model}")"
  variant="$(wun_ollama_variant_name "${base_model}")"

  wun_log "Pulling base model ${base_model}"
  ollama pull "${base_model}"

  if ! wun_ollama_model_exists "${base_model}"; then
    wun_fail "Base model ${base_model} was not found in ollama list after pull"
  fi

  wun_ollama_create_32k_variant "${base_model}" "${variant}"

  if wun_ollama_model_exists "${variant}"; then
    wun_log "Created 32K variant ${variant}"
  else
    wun_fail "32K variant ${variant} was not found in ollama list after create"
  fi
}

wun_ollama_create_32k_variant() {
  local base_model="$1"
  local variant_model="$2"
  local temp_dir modelfile

  temp_dir="$(wun_make_temp_dir)"
  modelfile="${temp_dir}/Modelfile"

  cat >"${modelfile}" <<EOF
FROM ${base_model}
PARAMETER num_ctx 32768
EOF

  wun_log "Creating 32K variant ${variant_model}"
  ollama create "${variant_model}" -f "${modelfile}"

  rm -rf "${temp_dir}"
}

wun_ollama_running() {
  curl -sf "$(wun_ollama_endpoint)/api/tags" >/dev/null 2>&1
}

wun_ollama_status() {
  local os
  os="$(wun_detect_os)"

  wun_log "Platform: ${os}/$(wun_detect_arch)"

  if wun_ollama_installed; then
    wun_log "Ollama: installed"
  else
    wun_warn "Ollama: not installed"
    return 1
  fi

  if wun_ollama_running; then
    wun_log "Ollama API: reachable at $(wun_ollama_endpoint)"
    return 0
  fi

  wun_warn "Ollama API: not reachable at $(wun_ollama_endpoint)"

  case "${os}" in
    macos)
      wun_log "Next step: run 'wun ollama start' or open the Ollama app."
      ;;
    ubuntu)
      wun_log "Next step: run 'wun ollama start' or 'sudo systemctl start ollama'."
      ;;
    *)
      wun_log "Next step: start Ollama, then rerun 'wun doctor'."
      ;;
  esac

  return 1
}

wun_ollama_start() {
  local os
  os="$(wun_detect_os)"

  if ! wun_ollama_installed; then
    wun_fail "Ollama is not installed"
  fi

  if wun_ollama_running; then
    wun_log "Ollama is already running at $(wun_ollama_endpoint)"
    return 0
  fi

  case "${os}" in
    macos)
      wun_ollama_start_macos
      ;;
    ubuntu)
      wun_ollama_start_ubuntu
      ;;
    *)
      wun_fail "Automatic Ollama startup is not supported on this platform"
      ;;
  esac
}

wun_ollama_start_macos() {
  if [ -d "/Applications/Ollama.app" ] || [ -d "${HOME}/Applications/Ollama.app" ]; then
    open -a Ollama >/dev/null 2>&1 || true
    sleep 2
  fi

  if wun_ollama_running; then
    wun_log "Started Ollama"
    return 0
  fi

  wun_warn "Unable to confirm that Ollama started"
  wun_log "Open the Ollama app manually, then rerun 'wun doctor'."
  return 1
}

wun_ollama_start_ubuntu() {
  if wun_has_command systemctl; then
    wun_warn "Ubuntu startup usually requires privileges."
    wun_log "Run: sudo systemctl start ollama"
    return 1
  fi

  wun_warn "systemctl not available; cannot manage the Ollama service automatically."
  wun_log "Start Ollama manually, then rerun 'wun doctor'."
  return 1
}


wun_ollama_list_output() {
  if wun_ollama_installed; then
    ollama list 2>/dev/null || true
  fi
}

wun_ollama_model_exists() {
  local model="$1"
  wun_ollama_list_output | awk 'NR>1 {print $1}' | grep -Fx "${model}" >/dev/null 2>&1
}

wun_configured_model() {
  local config
  config="$(wun_opencode_config_path)"
  if [ -f "${config}" ]; then
    sed -n 's/.*"model": "\(.*\)",*/\1/p' "${config}" | head -n 1
  fi
}
