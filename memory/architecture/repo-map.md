**Date:** 2026-07-01
**Type:** pattern
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** n/a
**Last-updated:** 2026-07-01
**Verified-at-commit:** 00cfdf8

# Repo Map

Directory-level map of the Claude Agent Pack. One entry per meaningful directory
with its key files. Maintained by `/repo-map`; read by `/onboard`, tech-lead,
`/plan`, `/refactor`, and `/scaffold`. Refresh when `git diff` shows drift from
`Verified-at-commit`.

## agents/
Sub-agent definitions (one `.md` per agent). Each file's frontmatter `description`
is the routing contract tech-lead matches against.
- `tech-lead.md` — decomposition + routing brain; read first for any multi-agent task.
- `merge-reviewer.md` — final pipeline gate; merges worktrees and commits to the feature branch.
- `git-engineer.md` — branch setup, commit, push/PR (Modes A–D).
- `obsidian-writer.md` — the only agent that writes to the Obsidian vault (capture/recap).

## skills/
One directory per slash command; each holds a `SKILL.md`. Entry points for user-invoked workflows.
- `implement/SKILL.md` — full pipeline orchestrator; also owns the worktree policy.
- `onboard/SKILL.md` — read-only codebase orientation; consumes `repo-map.md`.
- `repo-map/SKILL.md` — maintains this map (generate/refresh/verify).
- `setup-project/SKILL.md` — scaffolds the pack structure into a target repo.

## scripts/
Hook implementations (pure Node.js, Windows + POSIX safe) and shell tooling.
- `obsidian-stop-hook.js` — folds session journal/decisions/state into the vault on Stop/SessionEnd; writes `_current.md`, session logs, and `memory-snapshot.md`.
- `setup-project.sh` — copies CLAUDE.md/docs/ and creates `memory/` subdirs.
- `lint-agents.sh` — validates agent/skill frontmatter and body; CI gate.
- `check-readiness.sh`, `check-updates.sh` — install verification used by `/system-check`.

## memory/
Project memory, taxonomy under `decisions/`, `architecture/`, `context/`, `known-issues/`.
Agents read active files before acting; `superseded`/`archived` are history only.
- `architecture/2026-07-01-arch-repo-map.md` — this file.

## docs/
Team-facing reference read by agents before acting.
- `CONVENTIONS.md` — team standards; precedence rules in CLAUDE.md govern overrides.
- `MEMORY-WRITING.md` — frontmatter spec every memory writer follows.
- `CONVENTIONS.template.md` — seed copied by setup-project when no conventions exist.

## Root
Pack installation and metadata.
- `install.sh` / `uninstall.sh` — register hooks and env vars in `~/.claude/settings.json`.
- `CLAUDE.md` — agent orchestration rules and Obsidian capture instructions.
- `VERSION` — pack version stamp checked by `check-updates.sh`.
