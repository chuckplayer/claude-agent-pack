**Date:** 2026-07-01
**Type:** pattern
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** n/a
**Last-updated:** 2026-07-30
**Verified-at-commit:** 389f40a

# Repo Map

Directory-level map of the Claude Agent Pack. One entry per meaningful directory
with its key files. Maintained by `/repo-map`; read by `/onboard`, tech-lead,
`/plan`, `/refactor`, and `/scaffold`. Refresh when `git diff` shows drift from
`Verified-at-commit`.

## agents/
Sub-agent definitions, 19 files (one `.md` per agent). Each file's frontmatter `description`
is the routing contract tech-lead matches against.
- `tech-lead.md` — decomposition + routing brain; also writes the plan file and its acceptance bars.
- `merge-reviewer.md` — final pipeline gate; the only agent that commits. Owns gate 4a (plan bars and the three Deviations tiers).
- `git-engineer.md` — branch setup, commit, push/PR (Modes A–D).
- `obsidian-writer.md` — the only agent that writes to the Obsidian vault; owns the three-rung transport chain.

## skills/
One directory per slash command, 27 in total; each holds a `SKILL.md`. Entry points for
user-invoked workflows. Only the build and review flows orchestrate agents; the rest are
single-purpose.
- `implement/SKILL.md` — full pipeline orchestrator; also owns the worktree policy and the plan-adoption rule.
- `plan/SKILL.md` — decomposition and pressure-testing; creates the plan file and hands its `plan_id` forward.
- `onboard/SKILL.md` — read-only codebase orientation; consumes `repo-map.md`.
- `repo-map/SKILL.md` — maintains this map (generate/refresh/verify).

## scripts/
Hook implementations (pure Node.js, Windows + POSIX safe) and shell tooling. The five
`obsidian-*-hook.js` files are the only ones `install.sh` copies to `~/.claude/scripts/`.
- `obsidian-stop-hook.js` — folds session journal/decisions/state into the vault on Stop/SessionEnd; writes `_current.md`, session logs, and `memory-snapshot.md`. Has a test suite (`obsidian-stop-hook.test.js`, 131 tests) — the pack's only automated tests.
- `setup-project.sh` — copies CLAUDE.md/docs/ and creates the `memory/` and `docs/plans/` subdirs.
- `lint-agents.sh` — validates agent/skill frontmatter and body; run manually, no CI.
- `check-readiness.sh`, `check-updates.sh` — install verification used by `/system-check`; `check-updates` also detects installed-vs-repo drift and retired files.

## memory/
Project memory, taxonomy under `decisions/`, `architecture/`, `context/`, `known-issues/`.
Agents read active files before acting; `superseded`/`archived` are history only. Density is
in `known-issues/` — platform quirks and pipeline defects found by running the pack.
- `architecture/repo-map.md` — this file. A singleton living document, deliberately undated (see the exception in `docs/MEMORY-WRITING.md`) because it is refreshed in place rather than written once.

## docs/
Team-facing reference read by agents before acting, plus accumulated design briefs and
dated `claude-agent-pack-review-*.md` files from `/pack-review`.
- `CONVENTIONS.md` — team standards; precedence rules in CLAUDE.md govern overrides. Also holds the optional `- **Plan directory:**` key.
- `MEMORY-WRITING.md` — frontmatter spec every memory writer follows.
- `CONVENTIONS.template.md` — seed copied by setup-project when no conventions exist.

## docs/plans/
Plan artifacts written by tech-lead and consumed by `/implement` and merge-reviewer's gate 4a.
Committed alongside the implementation and never deleted, so this directory accumulates like
`memory/decisions/`. Consumption is opt-in by `plan_id` — nothing globs this directory.
Created eagerly by `setup-project.sh`; agents create it lazily on first write.

## Root
Pack installation and metadata.
- `install.sh` / `uninstall.sh` — register hooks and env vars in `~/.claude/settings.json`; `install.sh --yes` runs non-interactively.
- `CLAUDE.md` — agent orchestration rules, plan-spine rules, engineer responsibilities, and Obsidian capture instructions.
- `README.md` — flow selection, gate authority, and the pack's design patterns.
- `VERSION` — pack version stamp checked by `check-updates.sh`.
- `.claude/settings.local.json` — project-scoped permission allowlist. The only tracked file under `.claude/`; machine-level settings live in `~/.claude/settings.json`.
