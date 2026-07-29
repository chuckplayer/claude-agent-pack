# Design Brief: ADO Delivery Pipeline (Stages 0–4)

**Date:** 2026-07-27 (revised 2026-07-29 — proposed additions cut from 4 skills + 1 agent to 3 skills + 1 agent + 2 modes on existing skills; see Scope revision)
**Status:** design settled on six points, not yet specified in full, not implemented
**Origin:** reading `<internal-repo>/docs/<delivery-playbook>.docx` — a BA/PM playbook
derived from the <internal-repo> Claims module build (June–July 2026), and mapping its five stages against
what the pack actually covers today.

**Blocked on:** workstream 2 of `obsidian-cli-and-plan-spine-brief.md` (the durable plan spine),
for two independent reasons — the shared CONVENTIONS.md path key, and `/backlog` reading the plan's
acceptance bars rather than authoring its own. See Sequencing.

**Note the chain is serial, not a parallel expansion:** workstream 2 → `/spec-intake` →
`/backlog` → `/implement` work-item mode → `/verify-spec`, each needing its predecessor's artifact
to exist before its own shape can be designed. Any slippage in workstream 2 pushes all of it, and
workstream 2 has not started as of 2026-07-29 (`docs/plans/` does not exist and no plan-path key
appears in `docs/CONVENTIONS.md`).

---

## Goal

Close the pack's coverage gap on the playbook's five-stage delivery model. The pack is strong at
Stage 1 (plan + adversarial review) and partial at Stage 3 (execution). Stages 0, 2, and 4 —
which the playbook identifies as the actual bottleneck and the actual leverage — have no coverage
at all.

The playbook's own framing: *"the bottleneck in this process is a BA/PM bottleneck, and the
leverage is almost entirely upstream of any code being written."* Two full days of Claims'
elapsed effort were pure requirements work with no feature code, and that is what made a single
subsequent day produce twenty story-level commits.

---

## Stage coverage map

| Playbook stage | Pack coverage today | Gap |
|---|---|---|
| **0 — Ground truth** (spec of record, field inventory, traceability matrix, exemplar) | `/interview-me` produces a design brief only | None of the three durable artifacts exist |
| **1 — Plan + adversarial review** | `/plan` → tech-lead → devils-advocate → codex-reviewer; `memory/decisions/` as decision log | **Covered.** Closely matches the playbook |
| **2 — Backlog decomposition** | `devops-azure` creates one work item at a time with preview-and-confirm | Largest gap. No decomposition, points-by-analogy, parallel grouping, or completeness audit |
| **3 — Parallel execution** | `/implement` runs one story's agent chain | Partial. No work-item-driven entry or board hygiene. Multi-story fan-out is **out of scope by decision**, not a gap — see Scope revision |
| **4 — Verify against spec** | `/review-pr` reviews a diff | No coverage. Nothing walks a traceability matrix |

### Failure modes from the playbook, checked against the pack

The playbook lists four things that went wrong on Claims. Two are already handled here:

- **"Verification ran against unverified builds."** `agents/merge-reviewer.md:89-110` detects and
  runs the test suite and hard-fails on failure. Residual soft spot: line 110 downgrades
  *"no test command detected"* to a warning, and engineer agents reporting "could not run tests"
  are not structurally blocked earlier in the chain.
- **"Scope pressure was constant."** A process rule (PM standing authority to defer), not tooling.

One is a direct report card on this pack:

- **"Automatic decision-capture silently failed."** All 193 Claims session logs recorded
  *"Decisions: none captured"* while 29 decision documents were written by hand — undetected for
  the entire project because humans compensated. That is this pack's Obsidian decision hook.
  **Investigated and fixed 2026-07-29 (commit `5410ff8`)** — two independent defects, both
  silent:
  1. `~/.claude/current-session-id` is a single global file that every concurrent session
     overwrites on every prompt submission, and the CLAUDE.md capture command resolved the
     session id by reading it. Under two or more live sessions, decisions were filed into
     whichever session last took a turn. Observed directly: the file read one session id and,
     two minutes later, a different one, while `$CLAUDE_CODE_SESSION_ID` stayed correct
     throughout. Capture now resolves from the env var, which is per-session and cannot race.
  2. Nothing ever read `session-decisions-unknown.txt`, the literal filename the command's own
     fallback wrote to — a write path with no read path. 480 bytes of decisions had been
     stranded there since 2026-07-01. `readDecisions` now reads every candidate file, merges
     them, and clears each contributor (it was first-hit-wins, which also dropped decisions
     silently whenever two files had content).

The fourth — **ambiguous component references** — is a prompting discipline
(name the exact screen and file area, prefer screenshots to prose) and belongs in
`docs/CONVENTIONS.md` guidance rather than in a skill.

---

## Proposed additions

**Revised 2026-07-29.** Three skills, one agent, and two modes on existing skills. Shapes are
sketched, not specified — each should be re-scoped as the one before it lands.

1. **`/spec-intake`** — Stage 0. Markdown in; three artifacts out: spec of record, field-level
   inventory, traceability matrix with every row `not started`. Names the exemplar screen.
   *Not yet re-examined against `/interview-me`; see Open questions.*
2. **`/backlog` + `backlog-auditor` agent** — Stage 2, narrowed to reasoning only. Feature/story/
   task tree, story points estimated by analogy against a named already-delivered epic, and
   stories grouped by what can run in parallel. **Acceptance criteria are read from the plan
   spine's acceptance bars, not invented here.** Emits a reviewed tree; does not write to ADO.
3. **`/verify-spec`** — Stage 4. Walks the matrix against delivered code and the field inventory,
   reports gaps bidirectionally, opens stories for them, emits a stakeholder-readable document.
4. **Work-item mode on `/implement`** (replaces the proposed `/deliver`) — Stage 3.
5. **Batch write mode on `devops-azure`** — the only new ADO write surface `/backlog` needs.

`/deliver` as a separate skill is **cancelled, not deferred.** See the two scope decisions below.

---

## Decisions settled

### Scope revision (2026-07-29): `/deliver` cancelled, folded into `/implement` as a mode

`/deliver` decomposed into five responsibilities. Four fit `/implement` directly:

| `/deliver` responsibility | Fits `/implement`? |
|---|---|
| Read the story from ADO as task input | Yes — a step 0 ahead of git-engineer |
| Assign + set In Progress | Yes — same step 0 |
| On merge-reviewer PASS: link PR, mark done, log hours | Yes — a step 10c |
| Flip the traceability row | Yes — same step 10c |
| **Fan out across multiple stories** | **No** |

The four that fit are pre-flight input resolution and post-PASS side effects, and `/implement`
already carries two of the latter — step 10b (Obsidian capture) and step 11 (git-engineer push/PR).
Mode-gating is an established idiom in the pack: `git-engineer` already runs Modes A/B/C.

**The multi-story fan-out is dropped deliberately.** Three reasons:

- **It contradicts a settled decision.** Dynamic Workflows — the mechanism that does fan-out
  properly — was declined on 2026-07-27
  (`memory/decisions/2026-07-27-decision-decline-dynamic-workflows-for-implement.md`). A bespoke
  fan-out inside `/deliver` reintroduces exactly what that record rejected, minus the engine.
- **It stacks on an active bug.** `/implement` assumes one feature branch and one merge-reviewer
  commit; N stories means N branches and N pipelines, each dispatching `isolation: "worktree"`
  engineers. Worktree misbasing is already the pack's live worktree hazard
  ([[2026-07-15-worktree-isolation-bases-off-main]]), and concurrency multiplies it.
- **The playbook's parallelism was human.** Several sessions at once, not a skill fanning out.
  Notably, that same concurrency pattern is what broke the decision-capture hook — the global
  `current-session-id` file raced between sessions (fixed 2026-07-29, commit `5410ff8`).

Consequence accepted: the human invokes `/implement` once per story. In exchange the severe
`/implement`-vs-`/deliver` routing collision disappears rather than being papered over with
`Do NOT use` prose, and no new skill is added.

### Scope revision (2026-07-29): `/backlog` stays a skill; `devops-azure` gains a batch mode

The alternative considered was folding `/backlog` into `devops-azure` entirely. Rejected — wrong
seam. Of `/backlog`'s five responsibilities, exactly one is an ADO operation:

| Responsibility | Nature |
|---|---|
| Feature/story/task tree | Reasoning |
| Points by analogy vs. a delivered epic | Reasoning + ADO reads |
| Group by parallelizability | Reasoning |
| Completeness audit | Reasoning |
| Bulk-create the tree | **ADO write** |

`devops-azure` is a CLI-transport skill end to end — setup verification, operation classification,
targeting, runtime schema discovery, safe writes. It contains no reasoning workflow. Folding
decomposition into it would put a BA workflow inside an API shell, and worse, would force the
preview-and-confirm rule to be relaxed *inside the file that owns the rule*
(`skills/devops-azure/SKILL.md:108`, "even for a one-line comment"). That is the one place a
deliberate deviation must not happen quietly.

So the split is:

- **`/backlog` owns the reasoning** and emits a reviewed tree artifact.
- **`devops-azure` gains an explicit batch write mode** — whole-tree preview, one confirmation,
  **per-item result reporting**, and a hard cap on tree size. Amended once, deliberately, in the
  file that owns the rule. This supersedes the framing in Open questions below, which treated the
  60+ confirmations as a rule to work around: it is a safety rule meeting an operation it was
  never designed for. A mid-run `az` failure leaves a *partially created backlog*, which is worse
  than either outcome the current rule protects against — so per-item reporting is the load-bearing
  part, not the single confirmation.
- **The agent is reframed as `backlog-auditor`, not `backlog-architect`.** The skill decomposes;
  the agent independently audits the tree ("every story has ≥1 well-defined task; name the ones
  that don't"). That mirrors `tech-lead → devils-advocate`, an idiom the pack already runs, and
  keeps the audit genuinely independent rather than self-review by the thing that built the tree.

### Acceptance criteria come from the plan spine, not from `/backlog` (2026-07-29)

Workstream 2 has `tech-lead` writing acceptance bars "concrete enough that a stranger could check
them," `devils-advocate` pressure-testing them, `test-engineer` writing tests against them, and
`merge-reviewer` gating on them. If `/backlog` invents its own acceptance criteria, the pack ships
**two competing definitions of done for the same work** — and because this brief sequences
`/backlog` after the spine, the collision is guaranteed rather than hypothetical.

`/backlog` therefore reads the bars and attaches them to stories. It does not author criteria.
This is a second reason the plan spine must land first, independent of the CONVENTIONS.md path key
argued under Sequencing.

### Markdown is canonical for every Stage 0 artifact; no committed Office extractor

**Supersedes an earlier decision in the same session** to build the extractor as `scripts/*.sh`.

The extractor would have been the most brittle piece of `/spec-intake`. Probed on this machine:
`unzip` is present in Git Bash, but `xmllint`, `bsdtar`, `pandoc`, `markitdown`, and
`libreoffice`/`soffice` are all missing. So the XML→text step would be `sed`/`perl` regex with no
real parser, `.xlsx` would need `sharedStrings.xml` index resolution plus cell-ref parsing, and
because the Bash tool fails silently on this machine
(`memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md`) it would need the same
stdout-plus-read-back verification rule that `obsidian-writer` carries.

That is a large, permanent, silently-failing surface for an operation that happens roughly **once
per feature** and has a working manual escape hatch. This session read the source `.docx` with
three throwaway PowerShell calls (copy out of the Word lock, `ZipFile::ExtractToDirectory`, regex
strip of `document.xml`) and the output was fully usable, tables included.

So: conversion is **ad-hoc and inline**, triggered by a human, never a maintained script.
`/spec-intake` accepts markdown only.

Two consequences accepted deliberately:

- **The converted markdown becomes the spec; the original goes stale.** This must be stated out
  loud at intake or it recreates the two-sources-of-truth failure that prerequisite #1 exists to
  prevent. `/spec-intake` records the source path and conversion date in the spec's frontmatter.
- **Stage 4 still owes the business a presentable document.** The playbook generated a Word file
  specifically so it could go to stakeholders. This is an output problem, and `/visual-explainer`
  likely serves it better than Word.

**Open counter-argument, not resolved:** the playbook is written *for BAs and PMs*, and
prerequisite #1's owner is the BA. Requirements arrive from stakeholders as Word and Excel
regardless. Markdown-canonical moves that boundary-crossing cost onto a human rather than removing
it. Accepted for now because the cost is small and infrequent; revisit if intake volume grows.

### Traceability matrix lives in `docs/`, joined to ADO by work item ID

Authority is split explicitly:

- **The matrix owns** requirement → implementation → verified.
- **ADO owns** work item state and hours.
- **The ID column is the only join.**

This is what makes the Stage 4 gap-walk possible, and it is why the matrix cannot live inside ADO.
`/verify-spec` reconciles and reports drift in both directions:

- Matrix row with no ADO ID → requirement never decomposed (a Stage 0→2 leak)
- ADO item with no matrix row → scope creep

Format is a **markdown table**, not CSV — the playbook wants a stakeholder-readable artifact at
Stage 4, and the matrix should be reviewable in a PR diff.

Path is `docs/traceability/<feature>.md` by default, overridable via a `docs/CONVENTIONS.md` key —
**the same mechanism workstream 2 defines for `docs/plans/`.** Two artifacts, one convention.

### Sequencing: plan spine first

Workstream 2 of `obsidian-cli-and-plan-spine-brief.md` lands before any of this. It is already
approved and specified as an 8-file first cut, and workstream 1 shipped at `66b60c1`.

There are now two reasons, either of which is sufficient:

1. **The CONVENTIONS.md path key above.** Building Stage 0 first means inventing a second path
   convention and then reconciling the two.
2. **`/backlog` reads the plan's acceptance bars** rather than authoring criteria (2026-07-29
   decision above). Building `/backlog` first would mean authoring criteria that the spine then
   duplicates — the two-definitions-of-done collision.

It also means `/backlog`'s shape can be designed against a plan file that actually exists rather
than a specified one.

---

## Open questions

- **`/spec-intake` vs. `/interview-me` routing.** Different inputs (a document vs. a conversation)
  but the same delivery stage, so "turn these requirements into something actionable" matches both.
  Not yet examined — the 2026-07-29 pass covered only `/deliver` and `/backlog`. Needs either
  explicit `Do NOT use` disambiguation in both descriptions or, as happened with `/deliver`, a
  finding that it should not be a separate skill at all.
- **Stage 4 stakeholder output format** — `/visual-explainer` HTML vs. markdown vs. an actual
  `.docx`. Unresolved.

### Closed since the first draft

- **Batch writes vs. `devops-azure`'s safety rule** — resolved by the 2026-07-29 scope revision: an
  explicit batch write mode in `devops-azure` itself, with per-item result reporting. The original
  framing (a deviation `/backlog` should document) was the wrong shape; the rule is amended in the
  file that owns it.
- **Verifying the decision-capture hook actually captures** — done 2026-07-29, two defects found and
  fixed. See failure mode #3 above.
- **Whether `/deliver` fans out across stories in parallel** — moot. `/deliver` is cancelled and the
  fan-out is dropped by decision.

---

## Reference

- Source playbook: `<internal-repo>/docs/<delivery-playbook>.docx`
- Prerequisite brief: `docs/obsidian-cli-and-plan-spine-brief.md` (workstream 2)
- Related: `docs/azure-devops-github-skills-brief.md`
