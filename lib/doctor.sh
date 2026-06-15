#!/usr/bin/env bash

set -euo pipefail

wun_doctor() {
  local status=0
  local os arch config_path auth_path configured_model ollama_model base_model preferred_variant

  os="$(wun_detect_os)"
  arch="$(wun_detect_arch)"
  config_path="$(wun_opencode_config_path)"
  auth_path="$(wun_opencode_auth_path)"
  configured_model="$(wun_configured_model)"
  ollama_model="${configured_model#ollama/}"
  base_model=""
  preferred_variant=""
  if [ -n "${ollama_model}" ]; then
    base_model="$(wun_ollama_base_model_name "${ollama_model}")"
    preferred_variant="$(wun_ollama_variant_name "${ollama_model}")"
  fi

  wun_log "Platform: ${os}/${arch}"
  wun_log "Config path: ${config_path}"

  if wun_ollama_installed; then
    wun_log "Ollama: installed"
  else
    wun_warn "Ollama: not installed"
    status=1
  fi

  if wun_ollama_running; then
    wun_log "Ollama API: reachable"
  else
    wun_warn "Ollama API: not reachable at $(wun_ollama_endpoint)"
    status=1
  fi

  if [ -f "${config_path}" ]; then
    wun_log "OpenCode config: present"
  else
    wun_warn "OpenCode config: missing"
    status=1
  fi

  if [ -f "${auth_path}" ]; then
    wun_log "Auth placeholder: present"
  else
    wun_warn "Auth placeholder: missing"
    status=1
  fi

  if [ -n "${configured_model}" ]; then
    wun_log "Configured model: ${configured_model}"
  else
    wun_warn "Configured model: missing"
    status=1
  fi

  if [ -n "${ollama_model}" ] && wun_ollama_model_exists "${ollama_model}"; then
    wun_log "Model availability: present in ollama list"
  elif [ -n "${ollama_model}" ]; then
    wun_warn "Model availability: ${ollama_model} not found in ollama list"
    status=1
  fi

  if [ -n "${base_model}" ] && [ "${ollama_model}" != "${base_model}" ] && wun_ollama_model_exists "${base_model}"; then
    wun_log "Base model: ${base_model} present"
  elif [ -n "${base_model}" ] && [ "${ollama_model}" != "${base_model}" ]; then
    wun_warn "Base model: ${base_model} not found in ollama list"
    status=1
  fi

  if [ -n "${preferred_variant}" ] && [ "${preferred_variant}" != "${ollama_model}" ] && wun_ollama_model_exists "${preferred_variant}"; then
    wun_log "32K variant: ${preferred_variant} present"
  elif [ -n "${preferred_variant}" ] && [ "${preferred_variant}" != "${ollama_model}" ]; then
    wun_warn "32K variant: ${preferred_variant} not found in ollama list"
    status=1
  fi

  if [ ${status} -ne 0 ]; then
    wun_log
    wun_log "Suggested next steps:"
    wun_log "  1. Install Ollama if needed"
    wun_log "  2. Run: wun ollama status"
    wun_log "  3. Run: wun ollama start"
    wun_log "  4. Run: wun pull-model gemma4:latest"
    wun_log "  5. Run: wun preset use gemma4-balanced"
  fi

  return "${status}"
}
