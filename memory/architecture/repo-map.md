---
date: 2026-07-01
type: pattern
status: active
superseded-by: n/a
scope: global
overrides-convention: no
related-to: n/a
last-updated: 2026-08-04
verified-at-commit: b7f59f2
---

# Repo Map

Directory-level map of the Claude Agent Pack. One entry per meaningful directory
with its key files. Maintained by `/repo-map`; read by `/onboard`, tech-lead,
`/plan`, `/refactor`, and `/scaffold`. Refresh when `git diff` shows drift from
`Verified-at-commit`.

> **Re-stamped 2026-08-04 after a history rewrite, not after a normal refresh.** The previous stamp
> pointed at a commit that **no longer exists** — an identifier scrub rewrote all 172 commits, so every
> SHA changed and the stamp dangled. `/repo-map`'s rule for an unreachable stamp is to regenerate
> fully; a surgical re-stamp was taken instead because the diff *is* known: the scrub replaced
> identifier strings and altered no directory structure, and the only structural change since was
> untracking `.claude/settings.local.json`, corrected under **Root** below. **Any future dangling stamp
> without that guarantee should regenerate rather than re-stamp.**

## agents/
Sub-agent definitions, 20 files (one `.md` per agent). Each file's frontmatter `description`
is the routing contract tech-lead matches against. A new file here is **not dispatchable in the
session that created it** — `install.sh` copies these to `~/.claude/agents/` and the harness
enumerates that directory at session start; edits to an installed file are likewise not re-read
mid-session (see `memory/known-issues/`).
- `tech-lead.md` — decomposition + routing brain; also writes the plan file and its acceptance bars. Sole authority on **two** tables other files cite rather than copy: the plan-directory rejection table, and the **`### Bar soundness` table (6 rows)** naming the ways a bar passes while the property it checks is false. That table defines its own scope, so no other file describes it. Requires a responsibility matrix whenever a plan assigns a duty to another agent, then diffs owners against the edited file set to surface unowned duties.
- `merge-reviewer.md` — final pipeline gate; the only agent that commits. Owns gate 4a (plan bars and the three Deviations tiers), plus gates **2a** (`lint-agents.sh`), **2b** (the obsidian hook suite) and **2c** (`lint-identifiers.sh`, which fires on **every** changeset), all of which it runs itself rather than trusting a report. Deliberately never runs `lint-plans.sh` — it is forbidden from putting a plan path into a shell command, so gate 4a uses `Grep`/`Read`.
- `devils-advocate.md` — the only check on bar quality, applying tech-lead's bar-soundness table. Writes its narrative findings into the plan as a `## Challenge` section **before composing its reply**, so a subagent stall cannot take the judgement with it; leaves the `## Deviations` sentinel alone.
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
- `implement/SKILL.md` — full pipeline orchestrator; also owns the worktree policy and the plan-adoption rule. Runs `lint-plans.sh` at **two** blocking points (step 2 adoption, step 3 after a devils-advocate edit) and the two script gates at 5c/5d.
- `plan/SKILL.md` — decomposition and pressure-testing; creates the plan file and hands its `plan_id` forward. Runs `lint-plans.sh` blocking at step 2 (after tech-lead writes) and step 3 (after devils-advocate edits).
- `onboard/SKILL.md` — read-only codebase orientation; consumes `repo-map.md`.
- `repo-map/SKILL.md` — maintains this map (generate/refresh/verify).
- `spec-intake/SKILL.md` — Stage 0 document intake; emits a spec of record plus a run manifest. Dispatches no agents, but is the pack's only skill that ingests untrusted third-party files, so it carries its own input-hardening rules.
- `backlog/SKILL.md` — Stage 2 decomposition; turns a spec of record into `<spec_dir>/<feature>.backlog.md`, then dispatches `backlog-auditor` over it. The tree is a **registry, not a derived view**: hand-editable everywhere and never regenerated, so the skill's only write path is create and it stops and asks when a tree already exists. Creates nothing in any tracker and never asks about one — absence of an `external_refs` entry is the record that no tracker holds the item.
- `devops-azure/SKILL.md` — one-off Azure Boards/Repos operations via the `az` CLI, **plus `## 8. Batch write mode`**, which creates work items from a `/backlog` tree in one pass and is the sole writer of the tree's `external_refs:` field. Section 8 is where the file's own preview-and-confirm rule is amended **once, deliberately** (one confirmation per batch, with per-item result reporting as the compensating control); every other write still confirms individually. Creates only — never state, assignment, or closure — and offers no rollback. Each item is tagged twice: a per-item key and a bare feature **anchor** tag, because `[System.Tags] CONTAINS` matches whole tags rather than substrings (see `memory/known-issues/`).

## scripts/
Hook implementations (pure Node.js, Windows + POSIX safe) and shell tooling. The five
`obsidian-*-hook.js` files are the only ones `install.sh` copies to `~/.claude/scripts/`.
**Three checks in this directory are now blocking pipeline gates rather than manual tools** — the two
linters below and the hook test suite. The shift happened 2026-08-03/04, after an audit found each one
already existed while nothing invoked it.
- `obsidian-stop-hook.js` — folds session journal/decisions/state into the vault on Stop/SessionEnd; writes `_current.md`, session logs, and `memory-snapshot.md`. Its suite `obsidian-stop-hook.test.js` (131 tests) is the pack's only automated tests, and is **gated at merge-reviewer 2b** — triggered by those two hook filenames only, **not** by `scripts/`, since it covers neither the three other `obsidian-*.js` hooks nor any `.sh` script.
- `lint-agents.sh` — validates agent/skill frontmatter and body across `agents/` and `skills/`. **Blocking gate** (`/implement` 5c, merge-reviewer 2a); 49 checks. A malformed `description` *is* the routing contract, so a file failing this may be undispatchable however sound its body.
- `lint-plans.sh` — validates a plan's **structure** (frontmatter keys, `## Acceptance bars`, `## Deviations`, unique bar ids, typed `Evidence:`, and `Gated:` implying `Cost:`). Blocking at three call sites, all in the **coordinating session** — merge-reviewer deliberately does not run it. Takes **explicit paths only and never globs** the plan directory, and the path must be a discrete argument, never interpolated into a shell string. Its substantive rules trigger on **structured fields, never prose words** — both the `Gated:` check and the sentinel check were written or corrected for exactly that.
- `lint-identifiers.sh` — scans the tree for real organisation, project, host, user-path and email identifiers where the placeholder convention requires a placeholder. **This repository is public.** **Blocking gate on _every_ changeset** (`/implement` 5e, merge-reviewer 2c) — the only one of the three with no path trigger, because an identifier can be introduced by any file. Ships **no in-repo denylist** (a list of forbidden strings would have to contain them); exact tokens come from a gitignored `.identifier-denylist`, **word-boundary matched**, so a denylisted token embedded in a larger string is invisible to it. **Self-tests before scanning and exits 2** — distinct from a finding's exit 1 — if any rule fails to fire on a violating fixture.
- `setup-project.sh` — copies CLAUDE.md/docs/ and creates the `memory/` and `docs/plans/` subdirs.
- `check-readiness.sh`, `check-updates.sh` — install verification used by `/system-check`; `check-updates` also detects installed-vs-repo drift and retired files.

## memory/
Project memory, taxonomy under `decisions/`, `architecture/`, `context/`, `known-issues/`.
Agents read active files before acting; `superseded`/`archived` are history only — 7 files carry those
statuses. Density is in `known-issues/` — 24 files of platform quirks, pipeline defects found by
running the pack, and per-plan challenge records written by devils-advocate during `/plan`.
**The highest-value entries all record behaviour found by *executing* something rather than reviewing
it**: agent files not being re-read within a session, `backlog-auditor` severities varying run-to-run
on byte-identical input, `[System.Tags] CONTAINS` being whole-tag membership (which caught a shipped
design that would have duplicate-created every work item on every run), and the ADO board-degradation
claim turning out narrower and louder than three revisions of prose had asserted. The counterpart
lesson lives in `context/` and `known-issues/` together: on this machine a shell check has several
independent ways to *lie* — lost output, mangled arguments, a CLI returning blank with exit 0, and
`az devops invoke` silently serving a sibling route — so **an unexpected negative means suspect the
invocation before the subject.**
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
Holds 5 plans. `backlog.md` is the largest by a wide margin and doubles as the worked example of a
plan whose bars caught real defects — its `## Deviations` records bars that failed and were fixed
rather than amended.
`devops-azure-batch-write.md` is the counter-example worth reading beside it: 17 bars, and its
`## Deviations` records **ten** departures plus **three bars amended with cause**, including one bar
whose evidence was unproducible and one whose premise a live probe falsified. Its lesson is that a
bar can pass while the property it exists to check is false — four of its bars had that shape.
`bar-cost-and-first-run.md` is the third case: a plan whose **change 2 was withdrawn entire**, twice
redesigned and twice falsified by execution, with its two dead bars kept struck-through rather than
deleted. It is the record of what a withdrawn design meant to promise — and of the fact that findings
embedded only in a withdrawn bar go out with it.
**A merged plan is never retro-edited**, which is why every plan here predates and passes
`lint-plans.sh` without alteration: the `Cost:` rule keys on a `Gated:` field none of them carry.

## Root
Pack installation and metadata.
- `install.sh` / `uninstall.sh` — register hooks and env vars in `~/.claude/settings.json`; `install.sh --yes` runs non-interactively.
- `CLAUDE.md` — agent orchestration rules, plan-spine rules, engineer responsibilities, and Obsidian capture instructions. Its `backlog-auditor` routing section deliberately explains why `/backlog` is *not* one of the four plan-spine-exempt skills, since the two exemptions have different causes and get conflated. The same section records that `/devops-azure` batch write mode is the only writer of `external_refs:` and enters no gate — stated there rather than in a routing list, because the routing sections govern agents and batch mode is not one. Also holds **"A stage is complete when it reports, not when its agent stops"**: seven agents in one session finished correctly and went idle without reporting, so the file now forbids inferring a verdict from process state and prefers a re-runnable check over a trusted report — which is why the three script gates exist and why merge-reviewer holds `Bash`.
- `README.md` — flow selection, gate authority, the pack's design patterns, and the "Plan Spine" section documenting the three artifact-path keys and their defaults. Its spelled-out agent and skill counts are always recounted, never incremented.
- `VERSION` — pack version stamp checked by `check-updates.sh`.
- `.claude/` — **holds no tracked files.** `settings.local.json` was untracked 2026-08-04: it published one machine's permission allowlist, including an AD username, to a public repo. `.gitignore` had listed it from the start but the entry was inert, because gitignore does not apply to an already-tracked file. Machine-level settings live in `~/.claude/settings.json`.
