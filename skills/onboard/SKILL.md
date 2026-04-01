---
name: onboard
description: "Generate a structured orientation for a codebase. Reads the project, memory, and conventions to produce a mental model: architecture, key entry points, data flow, and known gotchas. Use when joining a project, returning after time away, or onboarding a new contributor. Trigger this when someone says: orient me, explain this codebase, how does this project work, I am new here, give me an overview, help me understand the architecture, catch me up. Do NOT use to document conventions — use /conventions instead. Do NOT use to plan a task — use /plan instead."
---

# Onboard

Produce a structured orientation for this codebase. This skill is read-only — it makes no changes.

## 1. Collect project context

Read the following in parallel:

- `README.md` (or `readme.md`) at the project root
- `docs/CONVENTIONS.md` if it exists
- `CLAUDE.md` at the project root if it exists
- All files in `memory/**/*.md` (skip any with `status: superseded` or `status: archived`)

## 2. Explore the codebase structure

Use Glob and Grep to map the project. Tailor the exploration to what you find — not all projects have all layers:

**Structure:**
- Top-level directories and their apparent purpose
- Solution/project files (`.sln`, `package.json`, `pyproject.toml`, etc.)
- Key configuration files (`appsettings.json`, `.env.example`, `vite.config.ts`, etc.)

**Entry points:**
- API controllers or route definitions
- Background jobs or scheduled tasks
- Frontend pages or top-level components
- Main program entry point

**Data layer:**
- Database context or ORM configuration
- Migration files (count and rough date range)
- Key entities or models

**Frontend (if present):**
- Component structure
- State management (stores, composables)
- API client layer

## 3. Identify key patterns

From what you've read, identify:
- The architectural style (layered, CQRS, modular monolith, microservices, etc.)
- Naming conventions actually in use (may differ from CONVENTIONS.md)
- Testing approach (unit, integration, e2e — what framework, where tests live)
- Anything flagged in memory as a known issue or non-obvious constraint

## 4. Produce the orientation document

> **Depth target:** Aim for the level of detail a developer new to this project could use to make their first commit within two hours. If a section would require deep explanation to be useful, flag it in step 5 instead of expanding it here — a pointer to the right file is more useful than an incomplete explanation.

Output a structured orientation using this format:

```
# Project Orientation: <project name>

## What this project does
<1–3 sentences>

## Architecture overview
<Describe the major layers and how they connect. Include a simple text diagram if helpful.>

## Key entry points
<List the most important files a new contributor would need to find first.>

## Data flow
<Trace a representative request or operation from entry point to data store and back.>

## Where to find things
| Concern | Location |
|---------|----------|
| API endpoints | ... |
| Business logic | ... |
| Database models | ... |
| Tests | ... |
| Frontend components | ... |

## Conventions and standards
<Summarize the most important rules from CONVENTIONS.md and memory. Flag any gaps or inconsistencies between documented conventions and actual code.>

## Known gotchas
<List anything from memory/known-issues/ or from code patterns that would surprise a newcomer.>

## Suggested first tasks
<2–3 low-risk starting points for someone new to this codebase.>
```

## 5. Flag gaps

After the orientation, note:
- What you could not determine from reading (e.g., no README, no CONVENTIONS.md, no memory files)
- Any apparent inconsistencies between documentation and actual code
- Areas where a human familiar with the project should fill in missing context

## Gotchas

- **No README or CONVENTIONS.md:** Do not invent documentation. If these files are missing, say so clearly in step 5 and suggest running /setup-project and /conventions to create them. The orientation should reflect what actually exists.
- **Memory files out of sync with code:** Memory records what was true at the time they were written. Always verify a memory claim against the current code before stating it as fact. If a memory file says "we use X" but the code uses Y, report the discrepancy rather than picking one.
- **Depth target mismatch:** The goal is "first commit in two hours," not a comprehensive architecture document. If you find yourself writing three paragraphs about a single module, that's a pointer to a reference file, not inline content. Keep it navigable.
- **This skill is read-only:** Do not create, modify, or delete any files during onboarding. If you identify something that should be documented, recommend /conventions or /memory-audit — do not write it yourself.
