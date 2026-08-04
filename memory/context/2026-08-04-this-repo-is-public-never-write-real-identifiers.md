**Date:** 2026-08-04
**Type:** constraint
**Status:** active
**Superseded-by:** n/a
**Scope:** global — every agent, skill, memory file, doc, plan, and commit message in this repository
**Overrides-convention:** yes
**Related-to:** n/a

## Summary

**This repository is PUBLIC on GitHub.** Never write a real organisation, project, product, repository,
document, work-item, or user identifier into any file or commit message here. On 2026-08-04 a scrub
removed **115 such references across 20 files**, and the git history had to be rewritten to match.

## The placeholder convention — use these exact tokens

| Instead of | Write |
|---|---|
| the ADO / GitHub org name | `<org>` |
| a project name | `<project-a>`, `<project-b>` |
| an internal repository | `<internal-repo>`, `<repo-b>` |
| an internal document title | describe it; **do not name or locate it** |
| an Obsidian vault root folder | `<vault-folder>` |
| an epic / work item id | `<epic-id>`, `<item-id>` |
| a machine path or username | `<user>`, or omit the entry |

Placeholders, never invented substitutes — a plausible fake org name gets mistaken for a real target.

## What this cost, so the next person does not repeat it

The scrub was mechanical; the **history rewrite was not cheap and is not fully reversible in effect**:

- Every commit SHA in the repository changed. Any external reference to an old SHA is dead.
- **A force push does NOT remove the old commits from GitHub.** Verified 2026-08-04: after the
  rewrite, `refs/heads/main` was clean in a fresh clone, yet the pre-rewrite SHAs were **still
  fetchable through the API on the parent repo**. Unreachable objects survive, and a fork in the
  network keeps them alive. Closing that needs GitHub Support, not git.
- A third-party public fork existed and **could not be cleaned at all** from inside the repo.

**So the real lesson is preventive, not remedial: the identifier must never be committed, because
committing it cannot be fully undone on a public host.**

## The rule that already existed and was not enforced

`docs/azure-devops-github-skills-brief.md` stated the constraint from the start — *"no <org>-specific
org/project names hardcoded into skill bodies"* — while **lines 18–21 of that same file listed them as
literal env-var values.** The rule was correct and nothing checked it. A stated rule with no
mechanical check is the failure mode this repository has produced repeatedly; see
`memory/known-issues/` for the same shape in four other places.

**The check now exists: `scripts/lint-identifiers.sh`, blocking on every changeset** (CLAUDE.md,
`/implement` 5e, merge-reviewer 2c). It keys on **structured positions** rather than prose, ships no
denylist for the reason above, and reads a gitignored `.identifier-denylist` for exact tokens.

Two traps it was built around, both hit for real during the audit:

- **Case-insensitive matching without `-w`.** One project name was a prefix of an ordinary English
  word that appears ~700 times in this repo, so a case-insensitive substring search matched all of
  them — **~75 false hits, twice**: once in the audit and again in the post-rewrite verification. Word
  boundaries (`-w`) kill that class outright. See [[2026-08-04-grep-iF-aborts-on-this-machine]] for why
  the matcher cannot also be case-insensitive on this machine.
- **A scan with no positive control.** Every scan needs to prove it can still see text it *should*
  match, or a broken pattern reads as a clean repo. The script self-tests two-sidedly and exits **2**
  rather than reporting a result it cannot stand behind.

**Do not use a real identifier as an example**, not even in a file explaining why not to. The first
draft of the checker used one as its self-test fixture and the structural scan could not see it,
because the script excludes itself. Use `Zzsynth` or similar.

## Provenance belongs in memory, not in a skill

The scrub also removed provenance coordinates from `skills/devops-azure/SKILL.md`
("verified against `<org>/<project>` on `<date>`"). Those now read **"verified by execution
`<date>`"** — which keeps the only signal a reader outside the tenancy can use (this claim was run,
not reasoned) and drops the coordinates. Full provenance lives in `memory/known-issues/`. Keep that
split: a skill states the rule and that it was verified; memory records where and against what.
