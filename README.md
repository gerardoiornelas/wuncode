# wuncode

`wuncode` is a local-first workflow layer for OpenCode on top of Ollama.

It does three things:

- configures OpenCode to talk to a local Ollama endpoint
- manages reusable presets, agent prompts, rules, and workflow metadata
- bootstraps project-level `AGENTS.md` files from templates

`wuncode` is a bash CLI. It is not a model runtime, package manager, or orchestration service. Ollama runs the models, OpenCode provides the interface, and `wuncode` connects the two.

## Status

This repository is currently a lightweight CLI and config bundle. The implemented command surface is:

```bash
./wun doctor
./wun ollama status
./wun ollama start
./wun preset list
./wun preset use <name>
./wun agents list
./wun workflows list
./wun workflows show <name>
./wun pull-model <model>
./wun init <project-type>
./wun update   # placeholder
```

The `update` command is present but not implemented yet.

## Requirements

- macOS or Ubuntu
- `bash`
- `curl`
- `jq`
- Ollama installed locally
- OpenCode installed separately

`wuncode` expects the Ollama OpenAI-compatible endpoint at `http://localhost:11434/v1`.

## Quick Start

1. Clone the repository.
2. Run the installer:

```bash
./install.sh
```

3. Start or verify Ollama:

```bash
~/.wuncode/wun ollama status
~/.wuncode/wun ollama start
```

4. Pull a base model and create its `-32k` variant:

```bash
~/.wuncode/wun pull-model gemma4-wuncode-base:latest
```

5. Apply a preset:

```bash
~/.wuncode/wun preset use gemma4-balanced
```

6. Create an `AGENTS.md` template inside a target project:

```bash
mkdir my-project
cd my-project
~/.wuncode/wun init python
```

7. Validate the setup:

```bash
~/.wuncode/wun doctor
```

## What The Installer Does

`install.sh` copies this repository into `~/.wuncode` if it is not already installed there, then runs a best-effort doctor check.

It does not:

- install Ollama
- install OpenCode
- add `wun` to your shell `PATH`

After installation, the stable entrypoint is usually:

```bash
~/.wuncode/wun
```

## Command Reference

### `wun doctor`

Checks:

- current platform
- Ollama installation
- Ollama API reachability
- OpenCode config presence
- auth placeholder presence
- configured model
- base and `-32k` model availability when a model is configured

### `wun ollama status`

Reports whether Ollama is installed and whether the local API is reachable.

### `wun ollama start`

- macOS: attempts to launch the Ollama app
- Ubuntu: prints the expected `systemctl` command when privilege escalation is needed

### `wun pull-model <model>`

Pulls the requested base model through Ollama, then creates a second model with a `-32k` suffix by setting `num_ctx 32768`.

Example:

```bash
./wun pull-model gemma4-wuncode-base:latest
```

This produces:

- `gemma4-wuncode-base:latest`
- `gemma4-wuncode-base:latest-32k`

### `wun preset list`

Lists available preset names from `presets/index.json`.

### `wun preset use <name>`

Writes an OpenCode config to the active config directory:

- `${XDG_CONFIG_HOME}/opencode/opencode.jsonc`, or
- `~/.config/opencode/opencode.jsonc`

It also installs a placeholder auth file and records local `wuncode` state.

### `wun agents list`

Prints the registered agent names, default presets, and prompt files from `agents/index.json`.

### `wun workflows list`

Lists workflow names from `workflows/index.json`.

### `wun workflows show <name>`

Prints the JSON definition for a workflow such as `workflows/ralph-loop.json`.

### `wun init <project-type>`

Creates `./AGENTS.md` in the current directory from one of the built-in templates:

- `python`
- `node`
- `rust`
- `monorepo`

The command fails if `AGENTS.md` already exists.

## Repository Layout

```text
.
├── agents/             # role prompts and agent registry
├── agents-templates/   # project bootstrap templates for AGENTS.md
├── commands/           # command prompt fragments and workflow instructions
├── core/               # base config defaults and auth placeholder
├── lib/                # bash implementation modules
├── presets/            # model and runtime presets
├── rules/              # reusable repository constraint documents
├── workflows/          # workflow definitions
├── install.sh          # local installer
└── wun                 # CLI entrypoint
```

## Development

Run the CLI directly from the repository while iterating:

```bash
./wun --help
./wun preset list
./wun agents list
./wun workflows show ralph-loop
```

Basic sanity checks:

```bash
bash -n wun lib/*.sh install.sh
./wun --help
```

If you have `shellcheck` installed, run it across the shell entrypoints as well.

## Design Notes

- The base model prompt should stay general and stable.
- Role-specific behavior belongs in `agents/*.md`.
- Workflow behavior belongs in `workflows/*.json`.
- Repository or language constraints belong in `rules/*.md`.
- Project bootstrap content belongs in `agents-templates/*.md`.

That separation keeps the runtime model generic while letting the local workflow layer define planner, coder, reviewer, and tester behavior explicitly.
