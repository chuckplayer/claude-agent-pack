**Date:** 2026-07-30
**Type:** finding
**Status:** active
**Superseded-by:** n/a
**Scope:** skills/spec-intake/, skills/interview-me/, docs/ado-delivery-pipeline-brief.md
**Overrides-convention:** no
**Related-to:** docs/plans/spec-intake.md

## Summary

Pressure-tested the `/spec-intake` plan (Stage 0 of the ADO delivery pipeline, branch
`feat/spec-intake`, base `main` at `73854da`) before any file was edited. The dominant finding:
**every guard in the design operates at file granularity, and the likely `.docx` failure on this
machine lives inside a file.** The PowerShell rung reads `word/document.xml` only, which does not
carry headers, footers, footnotes, endnotes, comments, or text-box content — so a requirement in a
text box yields output that is long, plausible, non-empty, and short a requirement. Read-back
detects a conversion that produced *nothing*; nothing in the design can see one that produced
*most*. The intake report will say `ingested`. Fifteen concerns recorded below. Three factual
errors were corrected in the plan file in place, and all eight acceptance bars were rewritten —
two of them named evidence that cannot be produced, and one was satisfiable by the exact failure
it exists to prevent.

## Context

The team lead dispatched devils-advocate against `docs/plans/spec-intake.md` (four files, one new
skill, eight bars) with a mandate to edit the bars and the stated calls in place, to attack the
adapt-to-variable-input shape, and to make the case for a smaller version. Nothing had been built.

## Concerns Raised

### 1. Within-file partial extraction is invisible at every guard's granularity
**Unresolved.** `word/document.xml` does not carry `word/header*.xml`, `word/footnotes.xml`,
endnotes, comments, or text boxes. Read-back (empty / whitespace / implausibly short) cannot fire on
a partial extract. The intake report's unit is the *file*, the hard rule ("adapt the method, never
silently narrow the scope") is stated at file level, and the failure is one level below both. This
is the single highest-value gap and it fires on the only rung this machine can exercise. Cheapest
honest disposition needs no parser: list the text-bearing `word/*.xml` parts found versus read, and
report unread parts as a within-file gap. Now asserted by the rewritten BAR-004.

### 2. The `.xlsx` escape hatch makes the loss invisible rather than visible
**Unresolved.** Skipping `.xlsx` is right. But Excel's Save-As-CSV exports **the active sheet
only**, silently, and a requirements workbook is normally one sheet per screen. A BA told to
"export to `.csv` and re-run" produces one CSV of six sheets and the skill correctly reports
`ingested` — the skip moves the lossy step outside the skill's field of view, converting a stated
skip into an unstated narrowing. That is worse than the failure the skip prevents, and it is not the
reversal the plan anticipated ("if `.xlsx` turns out to be the common input"). Fix costs no parser:
say export **each sheet**, and have `.csv` ingestion report rows/columns read. Related: `.csv` is
ingested with no parser and no read-back, yet quoted commas and embedded newlines are exactly the
plausible-but-wrong-table hazard cited to reject `.xlsx` — reached through the path the skip
recommends. Likelihood is higher than "eventually": a field inventory is the artifact BAs most often
already keep in Excel, and it is one of this cut's three outputs.

### 3. The no-seeding call's premise is false and its cited precedent is inverted
**Addressed in the plan file.** The call asserted "the plan spine already chose not to seed" and
"this repo's `docs/CONVENTIONS.md` is byte-identical to the template."
`docs/CONVENTIONS.template.md:25-26` ships `## Plan Artifacts` with
`- **Plan directory:** [e.g., docs/plans/]`, and `agents/tech-lead.md:55` *depends* on it having
been seeded. The two files diverge at exactly that key. The conclusion survives (this repo's
`CONVENTIONS.md` has no plan key, so the `docs/specs` fallback applies); the reasoning does not.
Second-order: not seeding makes the `^\[` guard *less* load-bearing for these keys, not more, so the
plan's claim that the two are jointly load-bearing was self-contradictory. Corrected in both
`## Calls made for you` and `## Inputs`; the seed/don't-seed decision itself is left to the human.

### 4. BAR-001's evidence named output `lint-agents.sh` does not produce
**Addressed.** `scripts/lint-agents.sh:200-201` prints only combined `<N> passed, <N> failed`; there
is no per-type count anywhere in the script. The bar asked for "0 failures with a skill count of 28."
Rewritten to use `ls -d skills/*/ | wc -l`, the method already established at
`skills/pack-review/SKILL.md:39` under an explicit "count, never carry forward a count" rule.

### 5. BAR-003 was satisfiable by the failure it exists to prevent
**Addressed.** "Confirm all three appear with dispositions" is satisfied by three *skips* — i.e. by
the silent-narrowing outcome step 4 warns about. Rewritten to require sentinel strings planted in
the `.md` and the `.docx` to appear in the written spec's `## Requirements`, so a skipped `.docx`
fails the bar.

### 6. Exercising the manual bars commits artifacts the plan puts out of scope
**Addressed in BAR-003, open for real runs.** `agents/merge-reviewer.md:476` is `git add -A`.
BAR-003 and BAR-006 emit into `docs/specs/` and `docs/traceability/`, and the path guard forbids
absolute paths and `..`, so the skill *cannot* write outside the repo by design — there is no scratch
location available. Cleanup was unowned; BAR-003's evidence now states it. The same hazard applies to
any real run whose artifacts sit uncommitted while an `/implement` pipeline finishes.

### 7. `/backlog` is misassigned as the matrix's ADO ID writer
**Unresolved.** The responsibility matrix and the matrix artifact's self-documenting-writers line
both name `/backlog` as the ADO ID writer. `docs/ado-delivery-pipeline-brief.md:93` and `:161` state
`/backlog` "emits a reviewed tree; **does not write to ADO**" — the ADO write is `devops-azure`'s new
batch mode (`:162-168`). `/backlog` never holds an ADO id. The real writer is one cut further out
than the three named, so the matrix's read path is four cuts away, not three, and the artifact's own
body will ship a wrong statement about who advances it.

### 8. `withdrawn` is unrepresentable in the spec of record
**Unresolved.** "A dropped requirement becomes `withdrawn`" is load-bearing for the permanent-id
call, but the spec block's `## Requirements` entries carry an id, a sentence, and a `Source:` — no
status field. `withdrawn` can be written in the matrix and nowhere in the artifact the plan calls
canonical. A reader of the spec alone cannot distinguish a live requirement from a withdrawn one.

### 9. Permanence without lineage
**Unresolved.** Ids are permanent and never reused, but no field records that REQ-009 was split out
of REQ-002, or that REQ-004 came from two sources — the format shows one `Source:` line per
requirement. ADO items already joined to REQ-002 then point at a requirement with no forward link,
and nothing states which source wins when two sources describe the same requirement differently.
An optional `Supersedes:` / `Split-into:` line costs one line in the step 5 block now; added later,
every already-emitted spec lacks it.

### 10. Interrupted-run recovery is unowned, and the only escape hatch causes the failure the
### collision rule prevents
**Unresolved.** Step 1 stops and asks on *any* of the three paths existing — correct — but the
gotcha's only sanctioned recoveries are hand-editing or picking a new slug. A run interrupted
between step 5 and step 7 leaves a spec with no matrix; a new slug then leaves the orphan in place
as a second spec of record for the same feature, which is exactly the two-sources-of-truth failure
the never-suffix rule exists to prevent. The stop-and-ask inversion of `agents/tech-lead.md`'s
suffix rule is itself sound and well-reasoned; the gap is the absent disposition for a partial
artifact set. BAR-006 now exercises the partial case.

### 11. Keeping the three artifacts in sync after intake is unowned
**Unresolved.** Amendments are hand edits across three files joined by REQ ids, with "one row per
REQ, no exceptions" enforced by nothing after step 7, and the fields table carrying its own `REQ`
column as a third drift surface.

### 12. The `Source: § 3.2` locator is likely unproducible on the only working rung
**Unresolved.** Word's automatic heading numbers live in `word/numbering.xml`, not as literal text
in `word/document.xml`, so on an auto-numbered source there is no `3.2` anywhere in the PowerShell
rung's output. The model must omit the locator or invent it — and an invented section number is
worse than none, because it looks like checkable evidence and cannot be found in the original. This
undercuts the stated mitigation for not committing the converted source. Suggested disposition:
require the locator to be copied from text present in the conversion, falling back to the
requirement's first verbatim words.

### 13. Two stated calls have non-falsifiable halves, and one of them is load-bearing
**Addressed by labeling.** Of twelve calls, ten name a concrete lookup target and are genuinely
checkable by gate 4a Tier 3 — the team lead's read was right. Two halves are not:
*"written in the source's own words where possible rather than paraphrased"* (a quality claim with
an escape clause, permanently out of Tier 3 scope per `agents/merge-reviewer.md:401-403`) and
*"implausibly short"* (no threshold, so no lookup target). The first matters because it is the
stated mitigation for this cut's largest risk. Both now labeled in place as documentation for the
human rather than enforceable decisions.

### 14. The `smell` step-1 precedent is half-adopted
**Unresolved.** `skills/smell/SKILL.md:50-52` carries a size cap (warn and offer to narrow above 20
files). Step 2 here has no cap, and "lists every file with its extension and size" is performed by a
model with no bound — a 200-file directory naturally yields "…and 180 more", silent narrowing
produced by the step that exists to prevent it.

### 15. Scope: the field inventory is the strongest deferral candidate
**Unresolved.** Its only reader is `/verify-spec`'s field-level gap walk — the *last* cut in the
chain. The matrix at least has a named reader in the next cut. Deferring the inventory removes one
format block, one build step, the `## Not captured at intake` rule, part of BAR-002, and the fields
table's `REQ` drift surface. Counter, which is real: field detail is the content most likely to be
lost once the source goes stale, so capturing it at intake has value even with no reader.

## Implications

- **Highest-value unaddressed question:** what signal, at *sub-file* granularity, tells the operator
  that a document was partially read? Everything else in this design is honest about scope; this one
  path is not, and it is the path this machine will take.
- **The manual bars are one sample of nondeterministic prose behaviour**, the same limit recorded as
  concern 9 of [[2026-07-30-challenge-durable-plan-spine-first-cut]]. BAR-003 and BAR-006 now record
  a `git hash-object` between runs per
  [[2026-07-30-agent-output-must-be-attributable-to-be-evidence]], because BAR-006 deliberately
  reuses BAR-003's slug and therefore its filename — an unchanged hash is what separates "declined
  to write" from "rewrote identical content".
- **A materially smaller version exists:** spec of record + intake report only. Those have a real
  reader on the first run (a human) and no unbuilt consumer. The matrix's seven columns are being
  frozen now by a session with no consumer to validate them against, and its first actual writer
  turns out to be `devops-azure` batch mode — the last component in the chain. Freezing a format
  against unbuilt readers is how every already-emitted artifact becomes stale the moment a reader
  deviates.
- Concern 12 of [[2026-07-30-challenge-durable-plan-spine-first-cut]]'s reconciliation method was
  applied by tech-lead and it worked for events *inside* a run — all ten transitions reconcile
  against a file. It did not catch duties arising *between* runs (amendment, withdrawal, lineage,
  interrupted-run recovery) or a duty assigned to a component that by decision cannot hold it. The
  method needs a second axis: for each artifact, who edits it after the run that created it?
