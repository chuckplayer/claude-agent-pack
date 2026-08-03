**Date:** 2026-07-01
**Type:** pattern
**Status:** active
**Superseded-by:** n/a
**Scope:** global
**Overrides-convention:** no
**Related-to:** n/a
**Last-updated:** 2026-08-03
**Verified-at-commit:** aa410a8

# Repo Map

Directory-level map of the Claude Agent Pack. One entry per meaningful directory
with its key files. Maintained by `/repo-map`; read by `/onboard`, tech-lead,
`/plan`, `/refactor`, and `/scaffold`. Refresh when `git diff` shows drift from
`Verified-at-commit`.

## agents/
Sub-agent definitions, 20 files (one `.md` per agent). Each file's frontmatter `description`
is the routing contract tech-lead matches against. A new file here is **not dispatchable in the
session that created it** — `install.sh` copies these to `~/.claude/agents/` and the harness
enumerates that directory at session start; edits to an installed file are likewise not re-read
mid-session (see `memory/known-issues/`).
- `tech-lead.md` — decomposition + routing brain; also writes the plan file and its acceptance bars. Sole authority on the plan-directory rejection table (other files point at it rather than copying rows). Requires a responsibility matrix whenever a plan assigns a duty to another agent, then diffs owners against the edited file set to surface unowned duties.
- `merge-reviewer.md` — final pipeline gate; the only agent that commits. Owns gate 4a (plan bars and the three Deviations tiers).
- `git-engineer.md` — branch setup, commit, push/PR (Modes A–D).
- `obsidian-writer.md` — the only agent that writes to the Obsidian vault; owns the three-rung transport chain.
- `backlog-auditor.md` — audits a `/backlog` decomposition tree across seven dimensions; dispatched by `/backlog` and nothing else. Read-only, and holds no `Bash`, so it cannot compute a hash — `/backlog` passes current hashes at dispatch and the agent does a string comparison. Mirrors `tech-lead → devils-advocate`: the skill that built the artifact is not the check on it.

## skills/
One directory per slash command, 29 in total; each holds a `SKILL.md`. Entry points for
user-invoked workflows. Only the build and review flows orchestrate agents; the rest are
single-purpose. `hotfix/`, `debug/`, `refactor/`, and `scaffold/` each state their plan-spine
exemption in-file — they pass no `plan_id`, so they are exempt by construction rather than by rule.
`backlog/` is outside the plan spine for a different reason: it never invokes merge-reviewer at all,
so there is no gate in its path to exempt.
- `implement/SKILL.md` — full pipeline orchestrator; also owns the worktree policy and the plan-adoption rule.
- `plan/SKILL.md` — decomposition and pressure-testing; creates the plan file and hands its `plan_id` forward.
- `onboard/SKILL.md` — read-only codebase orientation; consumes `repo-map.md`.
- `repo-map/SKILL.md` — maintains this map (generate/refresh/verify).
- `spec-intake/SKILL.md` — Stage 0 document intake; emits a spec of record plus a run manifest. Dispatches no agents, but is the pack's only skill that ingests untrusted third-party files, so it carries its own input-hardening rules.
- `backlog/SKILL.md` — Stage 2 decomposition; turns a spec of record into `<spec_dir>/<feature>.backlog.md`, then dispatches `backlog-auditor` over it. The tree is a **registry, not a derived view**: hand-editable everywhere and never regenerated, so the skill's only write path is create and it stops and asks when a tree already exists. Creates nothing in any tracker and never asks about one — absence of an `external_refs` entry is the record that no tracker holds the item.
- `devops-azure/SKILL.md` — one-off Azure Boards/Repos operations via the `az` CLI, **plus `## 8. Batch write mode`**, which creates work items from a `/backlog` tree in one pass and is the sole writer of the tree's `external_refs:` field. Section 8 is where the file's own preview-and-confirm rule is amended **once, deliberately** (one confirmation per batch, with per-item result reporting as the compensating control); every other write still confirms individually. Creates only — never state, assignment, or closure — and offers no rollback. Each item is tagged twice: a per-item key and a bare feature **anchor** tag, because `[System.Tags] CONTAINS` matches whole tags rather than substrings (see `memory/known-issues/`).

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
in `known-issues/` — 19 files of platform quirks, pipeline defects found by running the pack, and
per-plan challenge records written by devils-advocate during `/plan`. Several record behaviour found
by *executing* acceptance bars rather than reviewing them: agent files not being re-read within a
session, `backlog-auditor` severities varying run-to-run on byte-identical input, and
`[System.Tags] CONTAINS` being whole-tag membership rather than substring matching — the last caught
a shipped design that would have duplicate-created every work item on every run.
- `architecture/repo-map.md` — this file. A singleton living document, deliberately undated (see the exception in `docs/MEMORY-WRITING.md`) because it is refreshed in place rather than written once.

## docs/
Team-facing reference read by agents before acting, plus accumulated design briefs. The dated
`claude-agent-pack-review-*.md` files from `/pack-review` were **all removed in `2f1f99a`** and the
directory currently holds none — but the scheduled task still drops a new untracked one daily, which
matters because merge-reviewer commits with `git add -A`.
- `ado-delivery-pipeline-brief.md` — the delivery-pipeline design record spanning Stage 0 (`/spec-intake`), Stage 2 (`/backlog`), and the **now-shipped** tracker-write stage. Documents the item-id join key, the reciprocal key written back into a tracker (`System.Tags`, with the four rejected alternatives), and why `external_refs` alone fixes the steady state but not the crash state. Stage 2 is now `Covered`; the traceability matrix is still unbuilt but **no longer blocked**.
- `CONVENTIONS.md` — team standards; precedence rules in CLAUDE.md govern overrides. **It does not define any of the three artifact-path keys** — only `CONVENTIONS.template.md` ships them, unfilled — so every reader falls back to the documented defaults (`docs/plans`, `docs/specs`). Two plans record that resolution explicitly.
- `MEMORY-WRITING.md` — frontmatter spec every memory writer follows.
- `CONVENTIONS.template.md` — seed copied by setup-project when no conventions exist. Ships all three artifact-path keys as `[e.g., ...]` placeholders, which every reader treats as unset.

## docs/plans/
Plan artifacts written by tech-lead and consumed by `/implement` and merge-reviewer's gate 4a.
Committed alongside the implementation and never deleted, so this directory accumulates like
`memory/decisions/`. Consumption is opt-in by `plan_id` — nothing globs this directory.
Created eagerly by `setup-project.sh`; agents create it lazily on first write.
Each plan's `## Deviations` section is written by the coordinating session at `/implement` step 10,
never by tech-lead (which leaves a sentinel) and never by an engineer.
Holds 4 plans. `backlog.md` is the largest by a wide margin and doubles as the worked example of a
plan whose bars caught real defects — its `## Deviations` records bars that failed and were fixed
rather than amended.
`devops-azure-batch-write.md` is the counter-example worth reading beside it: 17 bars, and its
`## Deviations` records **ten** departures plus **three bars amended with cause**, including one bar
whose evidence was unproducible and one whose premise a live probe falsified. Its lesson is that a
bar can pass while the property it exists to check is false — four of its bars had that shape.

## Root
Pack installation and metadata.
- `install.sh` / `uninstall.sh` — register hooks and env vars in `~/.claude/settings.json`; `install.sh --yes` runs non-interactively.
- `CLAUDE.md` — agent orchestration rules, plan-spine rules, engineer responsibilities, and Obsidian capture instructions. Its `backlog-auditor` routing section deliberately explains why `/backlog` is *not* one of the four plan-spine-exempt skills, since the two exemptions have different causes and get conflated. The same section records that `/devops-azure` batch write mode is the only writer of `external_refs:` and enters no gate — stated there rather than in a routing list, because the routing sections govern agents and batch mode is not one.
- `README.md` — flow selection, gate authority, the pack's design patterns, and the "Plan Spine" section documenting the three artifact-path keys and their defaults. Its spelled-out agent and skill counts are always recounted, never incremented.
- `VERSION` — pack version stamp checked by `check-updates.sh`.
- `.claude/settings.local.json` — project-scoped permission allowlist. The only tracked file under `.claude/`; machine-level settings live in `~/.claude/settings.json`.
