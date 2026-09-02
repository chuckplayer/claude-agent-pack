**Date:** 2026-09-02
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** memory/, docs/MEMORY-WRITING.md, scripts/lint-memory.sh, agents/merge-reviewer.md gate 2d
**Overrides-convention:** no
**Related-to:** docs/plans/memory-index-and-dialect-normalization.md (its ## Challenge section holds the full narrative)

## Summary

Audited `docs/plans/memory-index-and-dialect-normalization.md` — a plan to build `memory/INDEX.md`,
normalize all 51 memory files to one fenced-YAML frontmatter dialect, add `scripts/lint-memory.sh`,
and add a blocking merge-reviewer gate `2d`. Recommendation recorded: **the dialect normalization
should ship and is genuinely severable; the index, as scoped, should not.** The deciding finding is
that 22 instruction-bearing files still direct a bare `Glob("memory/**/*.md")` and are never told the
index exists, so the index's marginal value over a free glob is zero by construction for those
consumers while its cost (45 authored `description:` lines, a permanently blocking gate, a new
derived-state hazard) is paid in full. Seventeen concerns raised; twelve of the thirteen bars edited
in place. **No concern is resolved** — the operator had made no decision when the audit ended.

## Context

The operator asked for "a skill to clean/consolidate memory files", then proposed a TOC/index modelled
on `memory/architecture/repo-map.md`. `tech-lead` wrote the plan, shipping the index plus dialect
normalization and **no consolidation at all** — a deliberate reversal of the request. `tech-lead`
flagged the "does the index beat a glob?" counterargument itself and declined to write a bar for it,
so it reached this audit unexamined; that was the primary agenda. Mid-audit the operator added that
`CLAUDE.md` "also needs to skip memory files that are `resolved`", which the plan instead handles by
eliminating the value (call 5). `scripts/lint-plans.sh` had passed the plan 19/0 with no post-audit
revision, so the file was exactly as `tech-lead` first wrote it.

## Bars edited, with a distinguishing phrase from each

Recorded so a later dispatch of this agent — which carries no transcript — can compare against the
file as it then stands. **Thirteen bars exist; BAR-004 is the only one left untouched** (its two-way
bijection cross-check is sound as written). Ids listed rather than totalled:

- **BAR-001** — replaced corpus-count non-vacuity with self-test non-vacuity; phrase: *"Non-vacuity is
  proved by a self-test fixture, not by a corpus file count"* and *"must pass on an empty corpus"*.
- **BAR-002** — exposed the call-5 dependency instead of presupposing it; phrase: *"this bar's polarity
  depends on an open decision (C16c)"* and the *"(a) … (b) The corpus run must exit 0 on the status
  rule specifically"* two-half split.
- **BAR-003** — de-hardcoded the count and separated two defects; phrase: *"The expected total is
  deliberately not stated"* and *"7 of those 8 are unmatchable because of the dialect … the eighth …
  because of its value"*.
- **BAR-005** — added parsed-row-count non-vacuity; phrase: *"a row parser that matches nothing
  compares zero descriptions and passes"*.
- **BAR-006** — added the two `CLAUDE.md` entries and the absent-script degradation; phrase: *"This is
  a presence check on prose and cannot be more than that"* and *"must degrade to `not applicable` when
  `scripts/lint-memory.sh` is absent"*.
- **BAR-007** — reframed a benefit claim as an artifact-shape claim; phrase: *"a claim about the
  artifact's shape, not about any agent's behaviour or cost"* and *"This bar must not be read as
  evidence that the index is used"*.
- **BAR-008** — named the legitimate second match by file and clause; phrase: *"The search returns two
  files today and one of them is correct"*.
- **BAR-009** — named the falsifier; phrase: *"any generalising formulation — 'singletons such as' …
  fails it"* and *"A closed list of two schemas is still two schemas"*.
- **BAR-010** — removed a self-exemption escape and added the missed write site; phrase: *"`skills/memory-audit/SKILL.md` step 1 item 4 (lines 21-22)"* and *"lets the checker reclassify any
  hit as historical and enforce nothing"*.
- **BAR-011** — separated a path fact from a frontmatter field; phrase: *"the **filename** (a path fact,
  not a frontmatter field …)"*.
- **BAR-012** — replaced `--stat` with hunk-level evidence; phrase: *"the one view specified was the
  view in which scope creep is invisible"* and *"an empty diff means the migration did not run"*.
- **BAR-013** — corrected a false reversibility premise in a consent gate and widened the gate's
  sample requirement; phrases: *"but not for the reason previously stated"*, *"This plan's own
  frontmatter reads `branch: main`"*, and in `Gated:` *"the nested-`metadata:` example is
  **mandatory**"*.

Also appended, and not part of any bar: a `### Calls audit` subsection on Tier 3 falsifiability, and
the `## Challenge` narrative itself. The `## Deviations` sentinel was left exactly as written.

## Concerns Raised

**Unresolved — the deciding one.** *The index has no instructed reader.* `Glob("memory/**/*.md")` is
named in 29 files, 25 instruction-bearing (15 `agents/*.md`, 7 `skills/*/SKILL.md`, plus `CLAUDE.md`,
`README.md`, `docs/AGENT-GUIDE.md`); the plan edits 3 of them. Impact: the index is enforced on the
write side of a read path nobody is directed to use. Either ~22 more files get edited — triple the
presented blast radius — or the index is dropped.

**Unresolved.** *BAR-013's consent gate rested on a false premise.* Its `Cost:` line said the branch
"is not merged to `main` by any agent"; the plan's frontmatter is `branch: main`. Bar-soundness row 6,
the BAR-015 shape. Edited, but the operator has not re-consented.

**Unresolved.** *Three wrong numbers in the one `## Risks` bullet carrying the plan's decisive
argument.* Verified independently: non-active files are 8 not 7; 7 are bold-dialect and the 8th is
nested-YAML `status: resolved`; the skip pair is instructed in 19 pack files not 20 (the 20th grep hit
is the plan itself). The argument survives; its arithmetic does not.

**Unresolved.** *Migration as specified deletes four dated facts.* Call 1's "exact key set" of eight
excludes `discovered:` (6 files, mandated by `CLAUDE.md`), `resolved:` (1 file), and
`last-updated:`/`verified-at-commit:` (`repo-map.md`) — inside a change described as "a lossless
format change [that] preserves every fact exactly". Whether extra keys are permitted is the single
most load-bearing unstated detail in the plan.

**Unresolved.** *A verifier named in the responsibility matrix fails on existing correct data.*
`2026-07-30-step-5b-passes-on-uncommitted-worktree.md` carries `**Superseded-by:** fixed in place
2026-07-30; see Revisit trigger` — prose, not a filename. No bar covers `superseded-by`, so this
surfaces during step 4, after the 51-file migration has run.

**Unresolved.** *Build step 6 contradicts BAR-010.* Step 6 leaves `/memory-audit` steps 1-3 alone;
step 1 item 4 instructs writing `**Status:** archived` — the losing dialect. If left alone, every
future hygiene run trips the new blocking gate 2d.

**Unresolved.** *Tier 1 asks engineers to append to a shared singleton mid-pipeline*, which
`CLAUDE.md` forbids for the plan file for the identical reason ("would conflict on the one file every
stage depends on"), compounded by `2026-07-15-worktree-isolation-bases-off-main.md`.

**Unresolved.** *The `resolved` question — all three routes examined.* The operator's route (add
`resolved` to the skip filter) costs 19 file edits and inverts BAR-002. Call 5 (rewrite to `archived`)
buries live guidance: that file documents `set -euo pipefail` + bare `read` aborting a script, the
`prompt`/`ASSUME_DEFAULTS` pattern, and wikilinks two **active** files. Splitting the file is correct
on the merits and out of scope — **BAR-012, the plan's own anti-scope-creep bar, fires on it.**
Recommended in-scope move: **drop call 5**, since it is the only place this plan changes a fact rather
than syntax, inside a plan whose central defence is that immutability protects facts and not syntax.
Also unaddressed by every route: `CLAUDE.md:413` and `docs/MEMORY-WRITING.md:22` both define
`known-issues/` as holding what "remain**s** unresolved", so a `resolved` file there is definitionally
misfiled.

**Unresolved.** *Call 3 relocates drift rather than removing it* — from row-vs-file (checkable) to
description-vs-reality (not), while adding a gate that makes the whole artifact look checked. Its
owner, `/memory-audit` step 5, is an on-demand skill nothing triggers.

**Unresolved.** *Gate 2d's severity is argued on one axis.* Mechanical ⇒ blocking is sound as far as it
goes, but a missing index row is a one-line append in a documentation tree, and the gate fires hardest
on agents discharging a mandatory memory-write duty at the end of a run.

**Unresolved, and noted late.** *The plan's 51-file counts are stale before implementation begins* —
this very file is the 52nd. `tech-lead` and `devils-advocate` memory writes are mandatory at plan
time, so any bar keyed to an absolute corpus count races the pack's own duties.

**Accepted as consciously made.** *Rejecting the bold-key dialect.* The plan's `## Risks` records the
rejection on YAML-parseability and Obsidian grounds and I accept it. One flaw noted: its cost
comparison weighed "20 consumer files" against "13 files migrate" while omitting the 45
`description:` lines, and those belong to the index rather than to the dialect — so the options were
not compared at equal scope.

**Addressed within the audit.** *Severability of normalization from the index.* Tested and confirmed
real, with three cheap-to-cut couplings (row-append prose in steps 1-2; `lint-memory.sh` losing its
bijection half; `description:` being required *only* as the index row's hook). Severing removes 45 of
the plan's 45 units of judgement work. Bars that stand alone: BAR-001, 002, 003, 010, 011, 012, 013.
Bars that fall with the index: BAR-004, 005, 006, 007, 008, 009.

**Addressed within the audit — an auditor error, recorded not hidden.** The first draft of concern 1
mis-transcribed its own grep ("25 of them `agents/*.md` … eight `skills/*/SKILL.md`"). Corrected in
place to 15 agents / 7 skills / 3 top-level, with the correction left visible in the plan. The 29
total and the conclusion were unaffected. Recorded because this plan's `## Risks` contains three count
errors of the same kind and the auditor producing a fourth in the same pass is the relevant data point:
**derive counts or list ids; do not restate them.**

## Implications

- **If a later dispatch is asked whether these edits survived a revision, compare against the bar list
  above by substance, not wording.** Reword is legitimate; disappearance is the signal. "I cannot
  confirm" is the correct answer if the phrases are absent — do not silently re-add them, because the
  frequency of silent overwrite is itself the thing worth knowing (see the 2026-08-05 loss of three
  clauses to a stale-snapshot whole-file write).
- **The index and the normalization are separate decisions and should be decided separately.** The
  normalization fixes a verified defect at a bounded cost; the index does not yet have a demonstrated
  consumer. Anyone reviving this plan should resolve concern 1 first — every other index concern is
  downstream of it.
- **`status: resolved` is a live distinction in this corpus, not a stray value.** Before any future
  cut buries or rewrites it, read
  `2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md` for content rather than
  status: it is the repo's record of a shell constraint affecting all seven `scripts/*.sh`, and
  `CLAUDE.md` itself records that this pack has re-shipped regressions of bugs already fixed once.
- **The corpus's diagnosis in `## What does not ship` is incomplete rather than wrong.** It holds that
  the problems are misfiling and dialects, not redundancy. At least one file is also *under*-divided.
  The conclusion (do not consolidate) is unaffected and arguably strengthened; the deferral of
  consolidation "until after the index exists" rests on a weaker base than it appears to.
- **An auditor correcting a consent-gate cost can introduce a new one.** See the survival-check
  section below: my first correction to BAR-013's `Cost:` line replaced an understatement with an
  overstatement, and bar-soundness row 6 fails in both directions. Re-derive a cost against the
  system that will bear it, not against the plan's own frontmatter.

## Post-revision survival check, same day

The operator revised the plan after this audit and re-asked whether the edits survived. **Answer:
all seven surviving bars kept their substance; nothing was silently lost.** Direction changed to
**normalization only** — the index, gate 2d, the 45 descriptions and **BAR-004 through BAR-009 were
deleted deliberately** on the no-instructed-reader finding. Also adopted: key set is a **minimum at
seven keys** (C16b), **call 5 dropped** so `status: resolved` stands (C16e), `description:` optional,
and all absolute corpus counts restated as relations (C17). Surviving ids deliberately not
renumbered: 001, 002, 003, 010, 011, 012, 013, plus new **BAR-014**. `## Challenge` confirmed intact
verbatim, including its now-dangling references to BAR-004–009 and to "51 files" — correct, since it
is a dated audit record and not a live spec.

**Two further edits made during the survival check** — record these too, for the same reason as the
list above:

- **BAR-014** (new, never audited before) — subject said "**at least one** instructed invoker" while
  its evidence required all three sites, so the weaker statement would have passed with two sites
  missing; and the degradation half was asserted as a category against one instance
  (bar-soundness row 2). Phrases: *"both making this bar able to fail where it previously could
  not"* and *"`/memory-audit` is installed globally and will run in projects that have `memory/` but
  no `scripts/lint-memory.sh`"*.
- **BAR-013 `Cost:` — corrected a second time, in the opposite direction.** The first correction
  (mine) replaced a false quarantine claim with "the only remedy is a revert commit on `main`". That
  over-corrected: `CLAUDE.md` requires git-engineer to run before any engineer agent and to offer a
  branch when on `main`, and merge-reviewer never merges to `main` — so a feature branch is the
  normal path. Now states **neither** as settled and requires the presenter to read the actual branch
  at confirmation time. Phrase: *"row 6 twice over … in **both** directions the table warns about"*.
  **Lesson worth carrying: an auditor correcting a row-6 cost can introduce a row-6 cost.** The
  table says both directions fail, and the corrected sentence failed the other one.

**Type vocabulary — a correction of mine, in the other direction.** My calls audit flagged call 4's
`type:` vocabulary as covered by no bar. tech-lead then found the vocabulary itself was wrong: the
corpus holds **seven** values, not five — `context` and `platform quirk` were missed. Verified
independently. The vocabulary was left **open** with BAR-002 stating the value is unenforced, and
**that satisfies my finding**: my objection was to a *silent* gap, and a declared one is a different
thing. Closing an incorrect vocabulary would have been worse — it would have forced rewriting two
files' `type:` values, i.e. changing facts, in a cut whose thesis is losslessness. **One residual
recorded as unresolved:** call 4 documents all seven observed values as the *recommended* set, which
blesses `platform quirk` (one file, contains a space) and `context` (one file, duplicates a directory
name) as spec. Recommend documenting the five as recommended and the two as observed-but-unenforced,
so the follow-on cut is not inheriting two probable one-offs as sanctioned vocabulary.
