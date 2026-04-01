---
name: memory-audit
description: "Runs a memory hygiene pass on the project memory/ directory. Reviews all active memory files against the current codebase and archives or supersedes stale entries. Use before major feature work or when memory files feel out of date. Trigger this when someone says: clean up memory, audit memory files, memory is out of date, stale decisions, memory hygiene, are our memory files current, check if decisions are still valid. Do NOT use when searching for a specific memory entry — use /memory-query instead."
---

# Memory Audit

Run a memory hygiene pass on the project's `memory/` directory.

If `memory/` does not exist in the current project, report that and stop.

## 1. Review active files for staleness

1. Use `Glob("memory/**/*.md")` to discover all memory files.
2. Skip files with `status: superseded` or `status: archived` — these are history only.
3. For each **active** file, check whether it still accurately describes the codebase as it exists today:
   - Does it reference a service, module, or dependency that no longer exists?
   - Has the technology it covers been removed or replaced?
   - Does a more recent decision supersede it?
4. For stale files:
   - Context no longer applies → update `**Status:** archived`
   - Superseded by a newer decision → update `**Status:** superseded` and populate `**Superseded-by:**`
5. Do not delete files — history is preserved by archiving, not deletion.

## 2. Check for gaps in decision coverage

After reviewing active files, look for unrecorded decisions. Ask the user:

> "Are there major architectural decisions, known issues, or pattern choices that have been made but aren't recorded in memory? For example: a technology that was evaluated and rejected, a workaround for a platform constraint, or a deliberate deviation from the conventions."

If the user identifies gaps, offer to create new memory entries for them using the templates in `docs/MEMORY-WRITING.md`.

## 3. Report

Output a summary:
- Total active files reviewed
- Files archived (with reason)
- Files superseded (with reason and superseded-by)
- Gaps identified and whether new entries were created
- If no changes were needed, say so

## Gotchas

- **Archiving too aggressively:** A memory file that references a pattern no longer in use may still be valid if it explains *why* that pattern was abandoned. Read for intent before archiving — "we removed X because Y" is still useful context even if X is gone.
- **Missing the memory/ directory entirely:** If `memory/` does not exist, report that clearly and stop. Do not create the directory — use /setup-project to scaffold the full project structure.
- **Confusing superseded with archived:** Superseded means a newer decision replaced this one — the newer file must be cited in `Superseded-by:`. Archived means the content no longer applies at all (e.g., references a removed module). These are different statuses with different meanings.
- **Inviting the user to create too many new entries at once:** Step 2 asks about gaps, but memory files are only useful when they capture non-obvious decisions. Do not turn this into a documentation sprint. Focus on decisions that would surprise a new contributor.
