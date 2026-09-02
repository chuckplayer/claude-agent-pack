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
4. For stale files, edit the fenced lowercase frontmatter in place:
   - Context no longer applies → set `status: archived`
   - Superseded by a newer decision → set `status: superseded` and populate `superseded-by:` with the
     newer filename
   - The issue was fixed → set `status: resolved` and add a `resolved: YYYY-MM-DD` key

   **Write lowercase keys inside the `---` fence and nothing else.** `docs/MEMORY-WRITING.md` is the
   authority on the dialect. This step previously instructed the bold unfenced dialect
   retired on 2026-09-02, which would have made this hygiene skill the thing that broke the
   dialect on every future pass. Change only the keys named above; leave the rest of the frontmatter
   and the whole body alone.
5. Do not delete files — history is preserved by archiving, not deletion.

## 1a. Check the repo map for drift

If `memory/architecture/repo-map.md` exists, read its `verified-at-commit` stamp and run `git diff --name-only <that-sha>..HEAD`. If mapped directories have changed, added, or been removed since the stamp, do **not** archive the map — it is meant to be refreshed, not retired. Instead, flag it in the report and recommend running `/repo-map refresh`. Only archive the map if the project structure it describes has been entirely replaced.

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

## 4. Lint the dialect

Run the conformance check over the corpus, including any file this pass just edited:

```bash
bash scripts/lint-memory.sh
```

Exit `0` conforms, `1` is a finding, `2` means the checker's own self-test failed and its verdict is
worthless. **Fix any finding before reporting the pass complete** — a hygiene pass that leaves the
corpus non-conforming has not finished. Findings name the file and the rule; `docs/MEMORY-WRITING.md`
is the authority on the dialect.

**If `scripts/lint-memory.sh` is not present in the project, report this step as `not applicable` and
continue.** The script is newer than some checkouts. A missing checker is a stated gap — do not
describe it as a pass, and do not hand-roll a substitute check.

## Gotchas

- **Archiving too aggressively:** A memory file that references a pattern no longer in use may still be valid if it explains *why* that pattern was abandoned. Read for intent before archiving — "we removed X because Y" is still useful context even if X is gone.
- **Missing the memory/ directory entirely:** If `memory/` does not exist, report that clearly and stop. Do not create the directory — use /setup-project to scaffold the full project structure.
- **Confusing superseded with archived:** Superseded means a newer decision replaced this one — the newer file must be cited in `superseded-by:`. Archived means the content no longer applies at all (e.g., references a removed module). Resolved means the issue it records was fixed. These are different statuses with different meanings.
- **Inviting the user to create too many new entries at once:** Step 2 asks about gaps, but memory files are only useful when they capture non-obvious decisions. Do not turn this into a documentation sprint. Focus on decisions that would surprise a new contributor.
