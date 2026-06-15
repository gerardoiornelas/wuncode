# Contributing

## Development Flow

1. Clone the repository.
2. Make changes in place and run the CLI directly with `./wun`.
3. Sanity-check the affected command paths before opening a PR.

## Recommended Checks

- `bash -n wun lib/*.sh install.sh`
- `./wun --help`
- `./wun preset list`
- `./wun agents list`
- `./wun workflows list`

If `shellcheck` is installed locally, run it against `wun`, `install.sh`, and `lib/*.sh`.

## Project Conventions

- Keep the project shell-first. Do not introduce Node, Python, or Rust tooling unless the repository actually needs it.
- Prefer small library functions in `lib/` over expanding the top-level `wun` dispatcher.
- Keep templates, presets, rules, and workflow metadata data-driven in their existing directories.
- Update `README.md` when command behavior or installation steps change.
