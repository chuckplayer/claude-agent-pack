---
name: obsidian
description: >
  Use when unsure which Obsidian command to use, or when someone says "obsidian
  help", "log something to Obsidian", "what obsidian commands are there",
  "obsidian?". Routes to the correct skill based on intent. Also use as a
  fallback when an Obsidian operation does not clearly map to capture, log,
  daily, search, or brief.
---

# Obsidian Help

The Obsidian skill family writes and reads Claude session context directly into
your Obsidian vault — captures, session logs, daily activity notes, and
search across everything Claude has logged. Every note written follows a
consistent folder layout under `Claude/` so the vault stays clean and
navigable.

## The five skills

| Skill | Use when |
|---|---|
| `/obsidian-brief` | Loading project context before starting work — synthesizes recent notes without a search query (read-only, not persisted) |
| `/obsidian-recap` | Writing a synthesized daily recap of the project's work to the vault (persisted) |
| `/obsidian-capture` | Saving a note, decision, or thought to the vault right now |
| `/obsidian-daily` | Viewing today's Claude activity note |
| `/obsidian-search` | Finding past session logs or captures by keyword |

> Session notes are written automatically by the Stop/SessionEnd hooks — there is
> no manual "log this session" command. To turn those raw session notes into a
> readable narrative, use `/obsidian-recap`.

## 1. Identify intent

Ask the user one question: **"What are you trying to do?"**

Listen for these patterns:

- "brief", "catch me up", "context", "what have we been working on", "load context" → `/obsidian-brief`
- "recap", "daily recap", "wrap up the day", "summarize today", "end-of-day summary" → `/obsidian-recap`
- "capture", "save", "note", "jot", "quick note", "save this" → `/obsidian-capture`
- "today", "daily", "what did I do today", "daily note" → `/obsidian-daily`
- "find", "search", "look up", "what did I log about" → `/obsidian-search`

## 2. Route and hand off

Once intent is clear, tell the user which skill handles it and invoke it. For
example: "That's a daily recap — starting `/obsidian-recap` now."

If the intent is ambiguous after one question, present the table above and ask
which row fits.

## Gotchas

- **Do not attempt the operation yourself.** This skill only identifies intent
  and routes. The other skills handle execution.
- **"I want to do multiple things"** — Route to the most urgent one first.
  Obsidian write operations on the same vault must not run in parallel; the
  daily note append has a single owner.
- **OBSIDIAN_VAULT_PATH not set** — If the user has not configured the vault
  path, all four skills will detect this and prompt them to run `install.sh`.
  Route to whichever skill the user intended — it will handle the missing env
  var gracefully.
