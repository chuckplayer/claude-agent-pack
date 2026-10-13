---
date: 2026-10-12
type: decision
status: active
superseded-by: n/a
scope: CLAUDE.md, docs/CLAUDE.template.md, docs/pack-development.md, references/orchestration-rules.md, scripts/setup-project.sh
overrides-convention: no
related-to: 2026-10-12-decision-install-time-reference-substitution.md
---

# CLAUDE.md is a thin import of a consumer template; long-form rules and pack-only gates live elsewhere

## Summary

The always-loaded `CLAUDE.md` (37,155 bytes) was split three ways. `docs/CLAUDE.template.md` (about 17K) holds
the rules every project needs on every dispatch and is what `setup-project.sh` copies into a consuming
project. `references/orchestration-rules.md` (about 20K) holds the long-form rationale, read on demand.
`docs/pack-development.md` (about 7.5K, not shipped) holds the four script gates for changing this pack. The
repo's own `CLAUDE.md` is now `@docs/CLAUDE.template.md` plus a short "This repository" section.

## Context

Every custom subagent loads the CLAUDE.md hierarchy unless its definition sets `omitClaudeMd`, so the file's
size is paid once per dispatch, roughly an order of magnitude above any single agent extraction. Consumers also
received this repo's script gates (lint-agents, lint-identifiers and others), which mean nothing in a project
that has none of those scripts.

## Rationale

- Rules a subagent needs on every dispatch had to stay inline, or moving them silently removes them from the
  subagent: the engineer duties including the `Departures from stated calls:` line, the memory and conventions
  read rules, plan consumption being opt-in, work-item mode being opt-in, the stall rule in short form, and the
  Obsidian capture commands the hooks depend on.
- An `@import` was chosen over an inline copy with a parity lint because it needs no duplication. The docs do
  not say outright that subagents get imports expanded, so it was tested: a custom subagent in a fresh session
  saw the imported content. See `context/2026-10-12-claude-md-imports-reach-subagents-snapshot-at-session-start.md`.
- The template cannot use the install-time token, because `setup-project.sh` copies it rather than rendering it.
  It names both install locations in plain text and says what to do if neither exists.
- Result: always-loaded text fell from 37,155 to 19,304 bytes (the template plus the import line), a 48 percent
  cut. The first estimate of 6 to 9K was not reachable without dropping the duties above.

## Alternatives Rejected

- **Marked block plus a parity lint:** duplicates 17K and adds a rule to an already large linter.
- **Extract the block from `CLAUDE.md` at setup time:** works, but removes the template file the gate triggers
  and the linter already name.
- **Keep the pack-development gates in the shipped file:** costs every consumer dispatch for rules that cannot
  apply to them.

## Implications

- Edit the rules in `docs/CLAUDE.template.md`, not `CLAUDE.md`.
- `setup-project.sh` still overwrites a consumer's `CLAUDE.md` on every run, as before; a customised file is lost.
- The lint-agents trigger is now `agents/`, `skills/`, `references/`, `CLAUDE.md` or `docs/CLAUDE.template.md`,
  stated identically in merge-reviewer gate 2a, `/implement` step 5c and `docs/pack-development.md`.
