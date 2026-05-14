**Date:** 2026-03-18
**Last-updated:** 2026-05-14
**Type:** finding
**Status:** archived
**Superseded-by:** n/a
**Scope:** scripts/
**Overrides-convention:** no
**Related-to:** n/a

> All unresolved items from this session were closed by 2026-05-14. See
> individual concerns below. Archived — agents may skip this file.

## Summary

Pressure-tested whether the six utility scripts (check-readiness, check-updates, lint-agents, new-memory, query-memory, setup-project) and their .ps1 counterparts provide real value given Claude's native Glob, Grep, Read, Write, and Bash tools. Found that two scripts are clearly redundant, two are clearly valuable, and two are conditionally valuable.

## Context

The scripts/ directory contains 12 files (6 .sh + 6 .ps1). Five of the six are wrapped by skills that instruct Claude to shell out and interpret results. The question was whether this indirection provides value or creates unnecessary maintenance burden and failure modes.

## Concerns Raised

### query-memory.sh is redundant with Claude's native tools
- **Resolved (2026-05-14):** Script removed from the repository. The memory-query skill now uses Glob/Grep/Read inline without shelling out.

### new-memory.sh has no skill and limited audience
- **Resolved (2026-05-14):** Script removed from the repository. The tech-lead and devils-advocate agents write memory files directly using Write. Template guidance lives in docs/MEMORY-WRITING.md.

### sh/ps1 duplication — resolved
- **Resolved (2026-03-19):** The six utility .ps1 files were removed. Git Bash runs .sh scripts on Windows without issue.
- **Amendment (2026-05-14):** `obsidian-stop-hook.sh` and `obsidian-stop-hook.ps1` were subsequently added and then superseded by `obsidian-stop-hook.js` (pure Node.js, no shell dependency). Both `.sh` and `.ps1` hook files have been removed. The `.js` file is the canonical hook.

### check-readiness.sh and check-updates.sh serve a human audience Claude cannot replace
- **Accepted risk:** These scripts check installed agent/skill state against the pack source using filesystem traversal and diff. They provide diagnostic output for humans at the terminal independent of Claude. This is a genuinely different audience. However, the skill-wrapped versions (where Claude shells out to the script) could still be replaced with inline tool usage.

### lint-agents.sh encodes a specification but has no CI pipeline yet
- **Accepted risk:** The linter validates agent frontmatter structure deterministically. It could anchor a CI gate, but no CI pipeline exists today. Its value is currently speculative as a CI artifact and modest as a manual check.

### setup-project.sh provides UX value as a one-time operation
- **Accepted risk:** The script handles conditional file copying, .gitkeep creation, and user-friendly output. While Claude could replicate this with Read+Write, the script is simpler to document and invoke for initial project setup. It runs once per project, so its maintenance cost is low relative to its UX benefit.

## Implications (updated 2026-05-14)

- query-memory.sh and new-memory.sh have been removed. Script count reduced.
- .ps1 files were removed in March 2026; obsidian-stop-hook.sh and .ps1 were
  added then removed again in May 2026, replaced by obsidian-stop-hook.js.
- Only .sh scripts remain: check-readiness, check-updates, lint-agents, setup-project.
- check-updates.sh now also checks obsidian-stop-hook.js (added May 2026).
- The accepted-risk scripts (check-readiness, check-updates, lint-agents,
  setup-project) remain in place — their human-audience value is confirmed.
