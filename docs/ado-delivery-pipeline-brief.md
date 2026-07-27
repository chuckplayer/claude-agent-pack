# Design Brief: ADO Delivery Pipeline (Stages 0–4)

**Date:** 2026-07-27
**Status:** design settled on four points, not yet specified in full, not implemented
**Origin:** reading `<internal-repo>/docs/<delivery-playbook>.docx` — a BA/PM playbook
derived from the <internal-repo> Claims module build (June–July 2026), and mapping its five stages against
what the pack actually covers today.

**Blocked on:** workstream 2 of `obsidian-cli-and-plan-spine-brief.md` (the durable plan spine).
See Sequencing.

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
| **3 — Parallel execution** | `/implement` runs one story's agent chain | Partial. No work-item-driven entry, board hygiene, or multi-story fan-out |
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
  Worth a deliberate verification pass; not yet scoped.

The fourth — **ambiguous component references** — is a prompting discipline
(name the exact screen and file area, prefer screenshots to prose) and belongs in
`docs/CONVENTIONS.md` guidance rather than in a skill.

---

## Proposed additions

Four skills and one agent. Shapes are sketched, not specified — each should be re-scoped as the
one before it lands.

1. **`/spec-intake`** — Stage 0. Markdown in; three artifacts out: spec of record, field-level
   inventory, traceability matrix with every row `not started`. Names the exemplar screen.
2. **`/backlog` + `backlog-architect` agent** — Stage 2. Feature/story/task tree with acceptance
   criteria, story points estimated by analogy against a named already-delivered epic, and
   stories grouped by what can run in parallel. Includes a **mandatory second audit pass**
   ("every story has ≥1 well-defined task; name the ones that don't").
3. **`/deliver`** — Stage 3. Work-item-driven orchestration over the existing `/implement` chain,
   per story: assign + In Progress → implement → on merge-reviewer PASS, link PR, mark done, log
   hours, flip the traceability row.
4. **`/verify-spec`** — Stage 4. Walks the matrix against delivered code and the field inventory,
   reports gaps bidirectionally, opens stories for them, emits a stakeholder-readable document.

---

## Decisions settled

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

The reason is the CONVENTIONS.md path key above. Building Stage 0 first means inventing a second
path convention and then reconciling the two. It also means `/backlog`'s shape can be designed
against a plan file that actually exists rather than a specified one.

---

## Open questions

- **Batch writes conflict with `devops-azure`'s safety rule.** That skill requires preview-and-confirm
  on every write, explicitly *"even for a one-line comment"* (`skills/devops-azure/SKILL.md:108`).
  Creating a 20-story backlog under that rule is 60+ confirmations. `/backlog` needs a
  preview-the-whole-tree-once, confirm-once, execute pattern — a deliberate deviation that should be
  written down as such, not quietly worked around.
- **Stage 4 stakeholder output format** — `/visual-explainer` HTML vs. markdown vs. an actual
  `.docx`. Unresolved.
- **Verifying the decision-capture hook actually captures** — playbook failure mode #3. Not scoped.
- **Whether `/deliver` fans out across stories in parallel** or runs them sequentially. The playbook
  ran several at once; the pack's worktree isolation may or may not hold up under that. Untested.

---

## Reference

- Source playbook: `<internal-repo>/docs/<delivery-playbook>.docx`
- Prerequisite brief: `docs/obsidian-cli-and-plan-spine-brief.md` (workstream 2)
- Related: `docs/azure-devops-github-skills-brief.md`
