---
name: wiki
description: >
  Help and discovery entry point for the LLM wiki skill family. Use when
  unsure which wiki command to use, or when someone says "wiki help", "how
  do I use the wiki", "what wiki commands are there", "wiki?", "show me wiki
  options". Routes to the correct skill based on intent. Also use as a
  fallback when a wiki operation does not clearly map to init, ingest, query,
  or lint.
---

# Wiki Help

The wiki skill family maintains a persistent, LLM-curated knowledge base stored
as markdown files on disk — a compounding artifact where every source you add
and every question you ask makes the base richer.

## The four skills

| Skill | Use when |
|---|---|
| `/wiki-init` | Starting a new wiki for a domain (vacation, research, etc.) |
| `/wiki-ingest` | Adding a source document, article, or notes to an existing wiki |
| `/wiki-query` | Asking a question against the wiki |
| `/wiki-lint` | Running a health check — orphaned pages, broken links, stale content |

## 1. Identify intent

Ask the user one question: **"What are you trying to do?"**

Listen for these patterns:

- "start", "create", "set up", "initialize", "new wiki" → `/wiki-init`
- "add", "ingest", "read", "process", "file", "put this in" → `/wiki-ingest`
- "ask", "search", "what does my wiki say", "query", "find" → `/wiki-query`
- "check", "lint", "health", "audit", "clean up", "orphan" → `/wiki-lint`

## 2. Route and hand off

Once intent is clear, tell the user which skill handles it and invoke it. For
example: "That's an ingest — starting `/wiki-ingest` now."

If the intent is ambiguous after one question, present the table above and ask
which row fits.

## Gotchas

- **Do not attempt the operation yourself.** This skill only identifies intent
  and routes. The other four skills handle execution.
- **"I want to do multiple things"** — Route to the most urgent one first.
  Wiki operations are sequential by design; back-to-back ingests on the same
  vault must not run in parallel.
- **No vault exists yet** — If the user mentions a domain but has no vault,
  route to `/wiki-init` before anything else.
