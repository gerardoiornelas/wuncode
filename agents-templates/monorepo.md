# AGENTS.md

## Project Overview
- Monorepo with multiple packages or services.

## Repository Structure
- Identify the affected package before editing.
- Avoid cross-package churn unless required.

## Coding Standards
- Follow each package's local conventions.
- Reuse shared tooling and scripts.

## Test Commands
- Run only the affected package tests first.

## Commit Checklist
- Confirm impacted packages.
- Run scoped verification.
- Keep changes isolated to the relevant area.

## Local Model Constraints
- Narrow context to the target package.
- Avoid loading the full monorepo unless necessary.

