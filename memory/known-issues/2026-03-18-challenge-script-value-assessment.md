**Date:** 2026-03-18
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** scripts/
**Overrides-convention:** no
**Related-to:** n/a

## Summary

Pressure-tested whether the six utility scripts (check-readiness, check-updates, lint-agents, new-memory, query-memory, setup-project) and their .ps1 counterparts provide real value given Claude's native Glob, Grep, Read, Write, and Bash tools. Found that two scripts are clearly redundant, two are clearly valuable, and two are conditionally valuable.

## Context

The scripts/ directory contains 12 files (6 .sh + 6 .ps1). Five of the six are wrapped by skills that instruct Claude to shell out and interpret results. The question was whether this indirection provides value or creates unnecessary maintenance burden and failure modes.

## Concerns Raised

### query-memory.sh is redundant with Claude's native tools
- **Unresolved:** This script does case-insensitive grep with a superseded/archived filter. Claude already has Grep (with regex), Glob (for file discovery), and Read (for status checking). The CLAUDE.md already instructs all agents to skip superseded/archived files. The skill's own SKILL.md tells Claude to read matching files in full after the script runs, making the script a pure intermediary. The skill indirection adds failure modes (wrong pack path, permission errors) without adding capability.

### new-memory.sh has no skill and limited audience
- **Unresolved:** This is the only script with no corresponding skill -- Claude never invokes it. It scaffolds a memory file with a template, but the devils-advocate and tech-lead agents already write memory files directly using Write. The human CLI audience could be served by a copy-pasteable template in docs/MEMORY-WRITING.md without maintaining a script in two languages.

### sh/ps1 duplication may be unnecessary on Windows
- **Unresolved:** Every script exists in both Bash and PowerShell. Git Bash ships with Git for Windows (which Claude Code requires), so the .sh versions likely work on Windows without the .ps1 counterparts. If the .ps1 files are not needed, that is 6 files of duplicated logic with no automated parity testing.

### check-readiness.sh and check-updates.sh serve a human audience Claude cannot replace
- **Accepted risk:** These scripts check installed agent/skill state against the pack source using filesystem traversal and diff. They provide diagnostic output for humans at the terminal independent of Claude. This is a genuinely different audience. However, the skill-wrapped versions (where Claude shells out to the script) could still be replaced with inline tool usage.

### lint-agents.sh encodes a specification but has no CI pipeline yet
- **Accepted risk:** The linter validates agent frontmatter structure deterministically. It could anchor a CI gate, but no CI pipeline exists today. Its value is currently speculative as a CI artifact and modest as a manual check.

### setup-project.sh provides UX value as a one-time operation
- **Accepted risk:** The script handles conditional file copying, .gitkeep creation, and user-friendly output. While Claude could replicate this with Read+Write, the script is simpler to document and invoke for initial project setup. It runs once per project, so its maintenance cost is low relative to its UX benefit.

## Implications

- If query-memory.sh and new-memory.sh are removed (4 files total counting .ps1), the script surface shrinks by a third with no loss of capability.
- The memory-query skill would need to be rewritten to use Grep/Glob/Read directly instead of shelling out, which would likely make it more reliable.
- If .ps1 files are determined to be unnecessary, another 6 files can be removed, leaving only 4 shell scripts.
- The remaining scripts (check-readiness, check-updates, lint-agents, setup-project) should be evaluated for whether their skill wrappers should shell out or replicate the logic inline.
