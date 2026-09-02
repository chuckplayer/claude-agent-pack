---
name: memory-query
description: "Search project memory files for a specific topic, decision, or constraint and return matching entries with citations. Use when you need to find what was decided about X, why Y was chosen, or whether Z is a known issue. Trigger this when someone says: what do we know about X, was there a decision about Y, check memory for Z, find the memory entry for X, what did we decide about Y, look up memory for X. Do NOT use for a full memory hygiene pass — use /memory-audit instead."
---

# Memory Query

Search the project's `memory/` directory for entries relevant to a specific topic, decision, or constraint. Returns matching entries with file paths and direct quotes.

If `memory/` does not exist in the current project, report that and stop.

## 1. Discover active memory files

```
Glob("memory/**/*.md")
```

Filter to active files only — skip any file where the frontmatter contains `status: superseded` or `status: archived`. These are history and should not be surfaced as current answers.

## 2. Read and match

**Triage on the filename first.** Filenames follow `YYYY-MM-DD-{prefix}-brief-slug.md`, so the slug
is a usable summary of the entry and every file has one. Read the full body of any file whose slug —
or whose subdirectory — suggests relevance to the query.

`description:` is an **optional** frontmatter field present in only a minority of files. Use it as a
second signal where it happens to exist; never rely on it being there, and never skip a file because
it lacks one.

Memory-file frontmatter carries no summary-name key. One was removed on 2026-09-02 because it
duplicated the filename. (This SKILL.md's own frontmatter is skill metadata, unrelated to the
memory dialect.)

Match the file to the query if it:
- Directly names the topic, technology, module, or pattern the user asked about
- Contains a decision, rationale, or constraint related to the query
- Documents a known issue or workaround for the queried area

## 3. Return results

For each matching file, output:

```
**[memory type] — [file path]**
> "[direct quote from the most relevant section]"

Summary: [one sentence describing what this memory says about the query topic]
```

Group results by memory type (decisions, architecture, context, known-issues) if multiple files match.

If no active memory files match the query, say so explicitly:

> No active memory entries found for "[query]". If a decision was made, it may not have been recorded yet — consider running /memory-audit to identify gaps.

Never hallucinate a memory entry. If the content is not in a file, it does not exist.

## Gotchas

- **Superseded and archived files are history only:** Do not surface them as current answers, even if they are relevant to the query. If a superseded file would have answered the question, note that the topic was once addressed but is now superseded and point to the `superseded-by:` file if present. That field is sometimes prose rather than a filename, so read it before citing it as a file.
- **Partial matches:** If a file mentions the topic in passing but does not contain a decision about it, include it with a note that it is contextual rather than a direct answer.
- **Multiple conflicting active files:** If two active files at the same scope contradict each other, surface both and flag the conflict rather than picking one silently.
