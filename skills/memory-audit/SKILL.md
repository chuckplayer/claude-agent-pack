---
name: memory-audit
description: Runs a memory hygiene pass on the project's memory/ directory. Reviews all active memory files against the current codebase and archives or supersedes stale entries. Use before major feature work or when memory files feel out of date.
---

# Memory Audit

Run a memory hygiene pass on the project's `memory/` directory.

If `memory/` does not exist in the current project, report that and stop.

Steps:
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
6. Output a summary: total active files reviewed, files archived, files superseded, and a brief reason for each change. If no changes were needed, say so.
