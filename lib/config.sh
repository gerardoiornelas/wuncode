#!/usr/bin/env bash

set -euo pipefail

wun_opencode_dir() {
  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    printf '%s/opencode\n' "${XDG_CONFIG_HOME}"
  else
    printf '%s/.config/opencode\n' "${HOME}"
  fi
}

wun_opencode_config_path() {
  printf '%s/opencode.jsonc\n' "$(wun_opencode_dir)"
}

wun_opencode_auth_path() {
  printf '%s/auth.json\n' "$(wun_opencode_dir)"
}

wun_presets_index_path() {
  printf '%s/presets/index.json\n' "$(wun_repo_root)"
}

wun_agents_index_path() {
  printf '%s/agents/index.json\n' "$(wun_repo_root)"
}

wun_workflows_index_path() {
  printf '%s/workflows/index.json\n' "$(wun_repo_root)"
}

wun_workflow_path() {
  printf '%s/workflows/%s.json\n' "$(wun_repo_root)" "$1"
}

wun_preset_path() {
  printf '%s/presets/%s.json\n' "$(wun_repo_root)" "$1"
}

wun_template_path() {
  printf '%s/agents-templates/%s-project.md\n' "$(wun_repo_root)" "$1"
}

wun_write_state() {
  local active_preset="${1:-}"
  wun_ensure_dir "$(wun_state_dir)"
  cat >"$(wun_state_file)" <<EOF
{
  "installed": true,
  "platform": "$(wun_detect_os)",
  "activePreset": "${active_preset}"
}
EOF
}

wun_install_base_auth() {
  wun_ensure_dir "$(wun_opencode_dir)"
  cp "$(wun_repo_root)/core/auth-placeholder.json" "$(wun_opencode_auth_path)"
}

wun_backup_file_if_exists() {
  local target="$1"
  if [ -f "${target}" ]; then
    cp "${target}" "${target}.wuncode.$(wun_timestamp).bak"
  fi
}

wun_preset_list() {
  awk -F'"' '/"/ {print $2}' "$(wun_presets_index_path)"
}

wun_preset_use() {
  local preset_name="$1"
  local preset_file
  preset_file="$(wun_preset_path "${preset_name}")"

  [ -f "${preset_file}" ] || wun_fail "Preset not found: ${preset_name}"

  wun_ensure_dir "$(wun_opencode_dir)"
  wun_install_base_auth
  wun_backup_file_if_exists "$(wun_opencode_config_path)"

  local model temperature max_tokens context_window minimum_ram
  model="$(sed -nE 's/.*"model":[[:space:]]*"([^"]+)".*/\1/p' "${preset_file}")"
  temperature="$(sed -nE 's/.*"temperature":[[:space:]]*([^,]+).*/\1/p' "${preset_file}")"
  max_tokens="$(sed -nE 's/.*"maxTokens":[[:space:]]*([^,]+).*/\1/p' "${preset_file}")"
  context_window="$(sed -nE 's/.*"contextWindow":[[:space:]]*([^,]+).*/\1/p' "${preset_file}")"
  minimum_ram="$(sed -nE 's/.*"minimumRamGb":[[:space:]]*([^,]+).*/\1/p' "${preset_file}")"

  cat >"$(wun_opencode_config_path)" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "${model}",
  "temperature": ${temperature},
  "maxTokens": ${max_tokens},
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      }
    }
  },
  "wuncode": {
    "preset": "${preset_name}",
    "contextWindow": ${context_window},
    "minimumRamGb": ${minimum_ram}
  }
}
EOF

  wun_write_state "${preset_name}"
  wun_log "Applied preset ${preset_name}"
  wun_log "Model: ${model}"
  wun_log "Config: $(wun_opencode_config_path)"
}

wun_init_template() {
  local project_type="${1:-}"
  [ -n "${project_type}" ] || wun_fail "Usage: wun init <project-type>"

  local template
  template="$(wun_template_path "${project_type}")"
  [ -f "${template}" ] || wun_fail "Template not found: ${project_type}"
  [ ! -f "./AGENTS.md" ] || wun_fail "./AGENTS.md already exists"

  cp "${template}" "./AGENTS.md"
  wun_log "Created ./AGENTS.md from ${project_type} template"
}

wun_agents_list() {
  jq -r '.[] | "\(.name)\t\(.defaultPreset)\t\(.promptFile)"' "$(wun_agents_index_path)"
}

wun_workflows_list() {
  jq -r '.[]' "$(wun_workflows_index_path)"
}

wun_workflow_show() {
  local workflow_name="${1:-}"
  [ -n "${workflow_name}" ] || wun_fail "Usage: wun workflows show <name>"

  local workflow_file
  workflow_file="$(wun_workflow_path "${workflow_name}")"
  [ -f "${workflow_file}" ] || wun_fail "Workflow not found: ${workflow_name}"

  jq '.' "${workflow_file}"
}
