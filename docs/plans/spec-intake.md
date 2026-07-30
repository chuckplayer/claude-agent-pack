---
plan_id: spec-intake
branch: feat/spec-intake
origin_skill: plan
created: 2026-07-30
---

## What ships

`/spec-intake` — Stage 0 of the ADO delivery pipeline — as a new skill, plus the `/interview-me`
hand-off that makes it discoverable. Five files, one of them new. **Two artifacts per feature, not
three.**

1. **`skills/spec-intake/SKILL.md`** (new). Accepts a file, a **directory**, or a completed
   `/interview-me` brief. Owns conversion as its own step 0, capability-probed rather than declared,
   and reports coverage at **part granularity within a file** with an omission severity the operator
   must acknowledge before any artifact is created. Emits:
   - **The spec of record** — the single authoritative artifact, hand-editable, with the field-level
     inventory as **Appendix A inside it** rather than a second synchronized file.
   - **A run manifest** — run id, source hashes, parts scanned vs omitted, acknowledgements,
     artifact paths, completion status. One mechanism serving two problems: omission reporting and
     interrupted-run recovery.

   Names the exemplar screen. Mints `REQ-nnn` ids **only after** the operator confirms the intake
   report.
2. **`skills/interview-me/SKILL.md` step 6** — the gated ask. Termination signal (b) asks; signal
   (a) does not ask and emits a one-line note that there is no Stage 0 artifact. Lands in this cut,
   never before it, because a hand-off offering an uninstalled command is worse than no offer. **The
   ask names the spec of record and its field inventory — not the traceability matrix**, which this
   cut defers; offering a deferred artifact is the same class of error as offering an uninstalled
   command.
3. **`docs/CONVENTIONS.template.md`** — a `## Spec Artifacts` section seeding both path keys beside
   the existing `## Plan Artifacts`.
4. **`README.md`** — skills-table row, the skill count (recounted, not incremented), one
   "Choosing a flow" row, and both new path keys documented beside the plan-directory key.
5. **`docs/ado-delivery-pipeline-brief.md`** — records the spec and manifest formats as resolved,
   pointing at this plan, and the **matrix format as explicitly deferred** with its reason.

**Review record.** devils-advocate raised fifteen concerns and three factual errors; codex-reviewer
followed with the registry-plus-views principle, the run manifest, the `xl/workbook.xml` probe, and
the id-minting gate. Every call below that a reviewer forced is attributed inline to whichever one
forced it. The unabridged challenge record is
`memory/known-issues/2026-07-30-challenge-spec-intake-stage-0.md` — kept there rather than inline so
each bullet below states exactly one authoritative call for gate 4a Tier 3 to look up.

## What does not ship

- **The traceability matrix.** Deferred to the cut that builds the ADO write path. This cut would
  otherwise freeze a seven-column format against **no consumer at all**, and per the brief
  `/backlog`'s input is the plan spine's acceptance bars plus a spec — **not the matrix** — so
  deferring blocks nothing downstream. The `- **Traceability directory:**` key is still seeded (see
  the calls) so the template documents all three path knobs at once.
- **A separate field-inventory file.** Folded into the spec as Appendix A. The perishability argument
  for capturing field detail at intake is unchanged; what goes away is a second file synchronized by
  hand.
- **No maintained converter script.** No file under `scripts/`. Conversion is inline, per-run,
  attempted from what the machine actually has. This is the settled markdown-canonical decision:
  markdown is canonical as step 0's *output*, and inline conversion inside a skill is not a
  maintained script.
- **No committed copy of the converted source.** Conversion output is transient; the manifest's
  source hashes are what make the run reproducible and detect a source that changed afterwards.
- **No agent is dispatched by the skill, and no agent file is edited.** `/spec-intake` is a document
  transformer, like `/smell` is a review dispatcher — no engineer, no reviewer, no `git-engineer`
  step. `/interview-me` already writes `docs/<slug>-brief.md` with no `git-engineer`.
- **No cheap regex of the sibling `.docx` parts by default.** They are reported as omitted, not
  scraped. See the calls.
- **No `--refresh` mode, and no new agent or `CLAUDE.md` edit.**

## Calls made for you

- **One authoritative registry, plus generated views that are never hand-edited.**
  *(codex-reviewer.)* The spec of record is authoritative. Anything derived from it — the deferred
  matrix, most immediately — must be **regenerated** from the spec, never edited in place. Recorded
  here as a binding constraint on the next cut, because it is what dissolves the three-way sync duty
  devils-advocate found unowned: a derived artifact that is regenerated cannot drift from its source.
  The manifest is neither registry nor view; it is a run record, written by the run and never
  hand-edited.
- **The field inventory is Appendix A of the spec, not a file.** *(Team lead's decision, converging
  devils-advocate's deferral argument with the perishability counter.)* Field detail is the content
  most likely to be lost once the source goes stale, so it is captured at intake; putting it inside
  the authoritative artifact removes the second synchronized file without losing the data. Its `REQ`
  column now joins within one file, so there is no cross-file join to drift.
- **A run manifest at `<spec_dir>/<feature>.manifest.md`, written before the spec and completed after
  it.** *(codex-reviewer.)* Cheap, and it is the mechanism underneath two separate problems: omission
  reporting needs somewhere durable to record parts scanned vs omitted and the operator's
  acknowledgement, and interrupted-run recovery needs to distinguish "no run happened" from "a run
  started and did not finish". Written first with `status: in progress` precisely so an interrupted
  run leaves evidence of itself.
- **Two `docs/CONVENTIONS.md` keys, and BOTH are seeded into `docs/CONVENTIONS.template.md` under a
  new `## Spec Artifacts` section.** `- **Spec directory:**` (default `docs/specs`) is read by this
  cut; `- **Traceability directory:**` (default `docs/traceability`) is seeded and documented but
  **read by nothing until the matrix lands** — stated plainly so it is not mistaken for a live knob.
  *Reversed after challenge on a verified fact:* the original no-seeding call rested on the claim that
  the template and this repo's `docs/CONVENTIONS.md` were byte-identical. They are not —
  `docs/CONVENTIONS.template.md:26` ships `- **Plan directory:** [e.g., docs/plans/]` under
  `## Plan Artifacts`, and `agents/tech-lead.md:55` justifies its own `[`-guard by that seeding. The
  placeholder seeding creates is exactly the case both readers' `^\[` rule already rejects, so seeding
  costs nothing and buys the one thing README cannot: a BA discovers the knob while editing paths.
- **`REQ-nnn` ids are minted only after the operator confirms the intake report — never before.**
  *(codex-reviewer; nobody else raised it.)* Permanent sequential ids minted ahead of that gate
  compound the extraction gap: if a requirement was silently missed and the ids are already fixed,
  adding it later forces either out-of-order appending or the renumber this plan forbids. Minting
  after the gate makes the id space a consequence of a confirmed reading. After minting, append-only:
  never renumber, never reuse, never delete silently — withdrawals and splits are recorded.
- **Per-requirement shape is fixed at ten fields:** `ID`, `Status`, `Title`, `Statement`,
  `Source refs` (**plural**), a `Locator/evidence` per source, `Rationale/notes`, `Lineage`,
  `Conflict note` (present only when sources disagree), `Last reviewed`. *(Team lead, converging
  devils-advocate's lineage and withdrawal concern.)* Plural sources plus the conflict note answer
  "which source wins" directly, which matters because directory mode ingests several files by design —
  and the answer is *neither silently*: both locators are recorded and the disagreement is stated.
  Status vocabulary is four values and stays that way: `proposed`, `active`, `withdrawn`,
  `superseded`. Intake mints `active`.
- **Locators are never synthesized.** *(devils-advocate, sharpened by codex-reviewer.)* A locator is
  source file + extracted part + a nearby heading **only if literal** + a short verbatim quote,
  falling back to the requirement's first few verbatim words. Word's automatic heading numbers live in
  `word/numbering.xml`, so `§ 3.2` frequently exists nowhere in the conversion; an invented one is
  worse than none because it looks like checkable evidence and cannot be found in the original.
  Verbatim words stay findable with Ctrl-F.
- **Requirements are written in the source's own words where possible.** Documentation for the human,
  not an enforceable call — it names no artifact, and `agents/merge-reviewer.md:401-403` puts that
  shape permanently out of Tier 3 scope. Stated as such deliberately, because it is the mitigation for
  this cut's largest residual risk and a reader should know the gate cannot check it.
- **Unread `.docx` parts are a warning requiring explicit operator acknowledgement before any artifact
  is created — not a passive note.** *(devils-advocate found the gap; team lead made it blocking.)*
  File-level read-back detects a conversion that produced *nothing*; it cannot detect one that produced
  *most* of the document, and on the PowerShell rung that is the likely failure, because
  `word/document.xml` does not carry footnotes, endnotes, comments, headers, or footers. Omissions are
  classified by severity — **high** for footnotes, endnotes, and textbox/drawing content (prose that
  commonly carries requirements), **medium** for comments (reviewer intent, possibly unratified
  requirements), **low** for headers and footers (usually boilerplate) — and the acknowledgement is
  recorded in the manifest with a timestamp.
- **The omitted parts are not scraped by default.** *(Team lead.)* Cheaply regexing `footnotes.xml` or
  `header1.xml` yields text with no document order and no surrounding context, which can manufacture
  false requirement context. If the operator explicitly asks for it, the extracted text is labelled
  `unordered, decontextualized — verify against the original` and every requirement sourced from it
  carries that label in its locator.
- **`.xlsx` is skipped, and the skip probes `xl/workbook.xml` to name the sheets.** *(Skip endorsed by
  both reviewers; the probe is codex-reviewer's.)* The package is already unzipped, so the probe is
  free, and it converts the escape hatch from a hazard into a checklist: *"XLSX skipped; contains 6
  sheets: Login, Payments, Reserves, Rates, Notes, Audit. Export **each** sheet as its own named file
  — Excel's Save As exports only the active sheet."* Without the sheet list, "export to `.csv` and
  re-run" was worse than the failure the skip prevents: a BA exports one of six sheets and the skill
  reports `ingested`, correctly by its own definition.
- **`.csv` is parsed, not split, and is not treated as safe raw text.** Parsed with `Import-Csv`
  (quoted commas, embedded newlines, and quoted quotes are the same plausible-but-wrong-table hazard
  used to reject `.xlsx`), and the skill states what a CSV cannot carry — sheet boundaries, formulas,
  types, hidden rows, and any non-active sheet — then reports the **row and column count read**, so a
  one-sheet export of a six-sheet workbook looks wrong to the person who owns the workbook.
- **Read-back's "too short" threshold is named: fewer than 200 non-whitespace characters, or fewer
  than 1% of the source file's byte count.** *(devils-advocate: `implausibly short` named no
  threshold, so it had no lookup target.)* Either test makes the conversion **suspect** — the skill
  reports both numbers and asks before ingesting, and never ingests a suspect conversion silently.
- **Directory mode is non-recursive, warns above 20 files, and offers to narrow.** Adopts
  `skills/smell/SKILL.md:50-52` whole rather than in part — the missing cap was a third
  silent-narrowing path, since a 200-file directory naturally produces "…and 180 more" from the very
  step that exists to prevent narrowing.
- **An interrupted run resumes or completes the same slug — never a new one.** The manifest decides:
  `status: in progress` means resume, writing only what is absent and touching no existing file. A new
  slug would leave an orphaned spec of record for the same feature, which is the two-sources-of-truth
  failure the never-suffix collision rule exists to prevent, reached through its own escape hatch.
- **Artifact filenames share one operator-confirmed slug**: `<spec_dir>/<feature>.md` and
  `<spec_dir>/<feature>.manifest.md`, proposed from the source title and confirmed once.
- **On collision with a completed run the skill stops and asks — it never suffixes and never
  overwrites.** This deliberately inverts `agents/tech-lead.md`'s plan-file suffix rule: a suffixed
  second plan is a harmless duplicate, whereas a suffixed second spec of record for one feature is the
  failure the whole markdown-canonical decision exists to prevent.
- **No field ids.** `Screen` + `Field` is the natural key in Appendix A and nothing maps onto a field
  id. An id nothing consumes is ceremony — the reasoning that kept ids off `## Deviations` in cut two.

## Deviations

_Deviations not yet reviewed. The coordinating session replaces this line before
merge-reviewer runs — with `None.` if nothing diverged, or one bullet per departure.
Leave this line exactly as it is._

## Risks

- **Conversion capability is the one thing this cut cannot prove by reading a file.** On this machine
  `unzip` is present and `xmllint`, `bsdtar`, `pandoc`, `markitdown`, and `libreoffice`/`soffice` are
  all absent, so the `.docx` path will exercise the PowerShell rung and nothing else. The ladder's
  upper rungs ship untested by construction. BAR-004 covers the ladder's *shape*; only a machine with
  `pandoc` proves rung 1.
- **Part-granularity coverage plus a blocking acknowledgement narrows the partial-conversion hole; it
  does not close it.** Naming unread parts catches content in a part the rung never opened. It does not
  catch content mangled *within* a part it did open — a tag-strip of `word/document.xml` flattens
  tables and can run cell text together. The locator rule and verbatim wording are what make that
  residue spot-checkable, and neither is enforceable.
- **The acknowledgement gate can be satisfied without being read.** An operator can acknowledge
  high-severity omissions reflexively. The manifest timestamps the acknowledgement, so the record
  survives into the PR diff; nothing forces comprehension.
- **The converted source is not committed, so extraction fidelity is not independently reviewable.** A
  reviewer cannot diff the spec against what the `.docx` said. The manifest's source hashes narrow this
  to *"the spec was produced from this exact byte sequence"*, which is provenance rather than fidelity.
  Escalation if it bites: a committed `<spec_dir>/<feature>.sources/` class.
- **The manifest is a third file class with one reader — the skill itself.** Its recovery branch is the
  only consumer until `/verify-spec` lands. That is a write path with a thin read path, this pack's
  signature failure class, accepted knowingly because the read path exists *in this cut* (BAR-006
  exercises it) rather than three cuts out.
- **Deferring the matrix means Stage 0 ships without the artifact Stage 4 walks.** Accepted: the matrix
  is fully re-derivable from the spec's `REQ` list whenever its consumer exists, and the
  registry-plus-views call binds the next cut to regenerate rather than hand-author it. The cost is
  that `/verify-spec` cannot be prototyped against a real matrix until then.
- **A seeded key that nothing reads is a small honesty risk.** `- **Traceability directory:**` will sit
  in every freshly-onboarded `docs/CONVENTIONS.md` with no artifact behind it. Mitigated by README and
  the template saying so; BAR-007 checks the wording.
- **The intake report is a prose instruction, not a mechanical gate**, and it is generated by the same
  model that did the ingesting. A run that ingests a subset and reports completeness is undetectable.
  Persisting the report in the spec and the manifest narrows it; nothing enforces it.
- **`/interview-me` step 6 grows a third branch.** The risk is over-interviewing on signal (a), which
  the skill's own gotcha warns against. The mitigation is the asymmetry: (b) asks, (a) notes once and
  proceeds. Getting that backwards makes the skill worse, so it is BAR-005.
- **The four manual bars are single samples of nondeterministic prose behaviour** — concern 9 of the
  plan-spine challenge, unchanged and unclosable here. The `git hash-object` snapshots are the best
  available mitigation, per
  `memory/context/2026-07-30-agent-output-must-be-attributable-to-be-evidence.md`, and they matter
  because BAR-006 deliberately reuses BAR-003's slug and therefore its filenames.
- **The skill file is long.** Nine steps, two format blocks, and a conversion table make it one of the
  larger `SKILL.md` files. Length is the cost of the formats being copy-ready instead of described,
  which is the point of the cut.

## Out of scope

- **The traceability matrix format**, and with it `/backlog`, `backlog-auditor`, `/verify-spec`,
  `/implement` work-item mode, and `devops-azure` batch write mode.
- A separate field-inventory file, and a `--refresh` mode that regenerates derived views. The second
  becomes relevant only when a derived view exists.
- Stage 4's stakeholder-readable output format (`/visual-explainer` vs. markdown vs. `.docx`) — still
  the brief's one remaining proposal-level open question.
- Any change to `CLAUDE.md`, `install.sh`, or `scripts/`.
- Writing anything to ADO, reading ADO, or any `az` invocation.
- Committing or PR-ing the *emitted artifacts* (as opposed to this cut's own files). The operator
  commits them, exactly as they commit an `/interview-me` brief.
- A committed `<spec_dir>/<feature>.sources/` class. Named in `## Risks` as an escalation.

---

## Inputs

- `docs/ado-delivery-pipeline-brief.md` — the design record. Load-bearing: the `/spec-intake` scope
  check (:174-228), the markdown-canonical decision **including its 2026-07-29 refinement at
  :271-291** (the decision and its refinement sit in one section and read as a contradiction if the
  second half is skipped), the matrix decision (:292-310), Open questions (:330-337), and `:93`,
  `:161`, `:162-168` — `/backlog` does **not** write to ADO; `devops-azure` batch mode does, which is
  part of why the matrix is deferred.
- `skills/interview-me/SKILL.md` — step 4 termination signals (:46-51) are what the ask gates on; step
  6 (:73-79) is the edit site; the "Don't over-interview" gotcha (:86) is why signal (a) does not ask.
- `skills/smell/SKILL.md` — precedent for resolving a variable input target in a numbered step 1, with
  an include/exclude filter, a confirm-the-list rule, **and the 20-file cap at :50-52**. All four
  adopted; the first draft adopted three.
- `README.md` — "Choosing a flow" table (:56-65), skills table and its spelled-out count (:71), "Plan
  Spine" (:256-286), and `:260` for where the plan-directory key is documented.
- `scripts/lint-agents.sh` — skill frontmatter contract: `name` must equal the parent directory name
  (:125-126), `description` ≤ 1024 chars (:142-143), valid fields are
  `name description license compatibility metadata allowed-tools` (:19), body non-empty (:166). Its
  only summary output is a combined `<N> passed, <N> failed` at :200-201 — **no per-type count** — so a
  skill count must come from `ls -d skills/*/ | wc -l`. `install.sh:83` globs `skills/*/`, so a new
  skill needs no registration.
- `skills/pack-review/SKILL.md:35-43` — "count, never carry forward a count", with the recount recipe
  and the incident that motivated it. Governs BAR-001 and BAR-008.
- `docs/CONVENTIONS.template.md:25-26` — ships `## Plan Artifacts` with
  `- **Plan directory:** [e.g., docs/plans/]`. The template and this repo's `docs/CONVENTIONS.md` are
  therefore **not** byte-identical; they diverge at exactly that key. The first draft asserted the
  opposite and built the no-seeding call on it. Provenance, recorded so the claim is not re-inherited:
  the assertion was true earlier on 2026-07-30 and was invalidated by the template being seeded later
  the same day. `agents/tech-lead.md:55` depends on that seeding.
- `docs/CONVENTIONS.md` — every value is an unfilled `[e.g., ...]` placeholder and no
  `- **Plan directory:**` key is present, so the `docs/plans` fallback applies to this plan file.
- `agents/tech-lead.md` — the `Reject when the value` guard table, which step 1 **points at** rather
  than copies.
- `agents/merge-reviewer.md:476` — the commit step is `git add -A`, which is why the manual bars run in
  a scratch project outside this repo. `:401-403` — the Tier 3 checkable-call definition, which is why
  one call above is labelled documentation.
- `docs/plans/plan-spine-deviations.md` — precedent for the plan shape, and for the finding that no
  agent description covers prompt-file editing.
- `memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md` — blank output is tool breakage,
  not a result. Drives the read-back rule.
- `memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md` — `${...}` and unquoted spaces
  are destroyed at the native-command boundary; trust `$LASTEXITCODE`, not `$?`; invoke Git Bash by
  literal path. Drives the conversion invocation rules and BAR-001's evidence command.
- `memory/known-issues/2026-07-30-challenge-spec-intake-stage-0.md` — this plan's challenge record:
  fifteen concerns, three factual errors, the bar rewrites whose methods are preserved below.
- `memory/known-issues/2026-07-30-challenge-durable-plan-spine-first-cut.md` — concern 12's actor/file
  reconciliation method, applied below on two axes.
- Plan directory resolution: `docs/CONVENTIONS.md` has no `- **Plan directory:**` key, so the
  `docs/plans` fallback applies. All guard conditions pass.

## Build steps

Responsibility matrix first, per concern 12's method — **on two axes.** The first block enumerates
transitions *inside* a run; the second answers what the first structurally cannot: for each artifact,
who edits it after the run that created it?

```
Event: target is resolved (file | directory | /interview-me brief), and run state is read
Writer: none                                     Reader: skill step 1
Mutator: none                                    Verifier: the manifest, when one exists
Failure behavior: ambiguous target -> ask, never guess (smell step 1 precedent)
Persisted state: none

Event: directory is surveyed
Writer: none                                     Reader: skill step 2
Mutator: none                                    Verifier: operator
Failure behavior: over 20 files -> warn and offer to narrow; never truncate the list
Persisted state: none — becomes the intake report's "found" column

Event: a source file is converted
Writer: skill step 3, to the scratchpad          Reader: skill step 7 (authors the spec from it)
Mutator: none                                    Verifier: read-back — empty test, the two-part
                                                 short test, and the part-coverage enumeration
Failure behavior: empty -> skip; suspect -> ask; parts omitted -> severity + acknowledgement
Persisted state: none in the repo yet; recorded in the manifest at step 6

Event: omissions are acknowledged
Writer: the operator, in conversation            Reader: skill step 4
Mutator: none                                    Verifier: step 4 refuses to proceed without it
Failure behavior: no acknowledgement -> no id is minted and no artifact is written
Persisted state: the manifest's per-part `acknowledged:` timestamp, written at step 6

Event: REQ ids are minted
Writer: skill step 5                             Reader: the spec, then everything downstream
Mutator: none                                    Verifier: none — permanence starts here
Failure behavior: minting before step 4's gate -> a missed requirement forces a forbidden
        renumber. The ordering is structural: step 5 cannot run before step 4.
Persisted state: none until step 7

Event: manifest is opened
Writer: skill step 6                             Reader: skill step 1 of a LATER run (recovery)
Mutator: skill step 8 completes it               Verifier: source hashes on the next run
Failure behavior: written before the spec deliberately, so an interrupted run leaves evidence
Persisted state: <spec_dir>/<feature>.manifest.md, status `in progress`, uncommitted

Event: spec of record is written (including Appendix A)
Writer: skill step 7                             Reader: /backlog, the human in a PR, later stages
Mutator: the operator, by hand — it is authoritative
Verifier: none
Failure behavior: a completed spec exists -> stop and ask; never suffix, never overwrite
Persisted state: <spec_dir>/<feature>.md, uncommitted

Event: manifest is completed
Writer: skill step 8                             Reader: a later run's recovery branch
Mutator: none                                    Verifier: none
Failure behavior: left `in progress` -> the next run offers to resume, the safe default
Persisted state: manifest at status `complete`, with artifact paths

Event: /interview-me terminates
Writer: none                                     Reader: the user
Mutator: none                                    Verifier: none
Failure behavior: signal (b) without the ask -> silent Stage 0 gap; signal (a) with the ask
        -> re-imposed ceremony the user just declined. Both are wrong; BAR-005 covers both.
Persisted state: none — an ask and a note, owned by skills/interview-me/SKILL.md step 6

Event: a user must choose between the two skills
Writer: none                                     Reader: the routing layer
Mutator: none                                    Verifier: none
Failure behavior: overlapping descriptions -> a coin flip at routing time
Persisted state: both `description` fields. Split on a property of the *input*: requirements
        in a human's head -> /interview-me; in a document -> /spec-intake.
```

Second axis — **who edits each artifact after its run?**

```
Duty: amend the spec of record (add, retire, split, or merge a requirement)
Owner: the operator, by hand. It is the authoritative registry, so hand editing is correct
       rather than a gap. The `Status:` and `Lineage:` fields exist so an amendment is legible.

Duty: keep a derived view in step with the spec
Owner: DISSOLVED, not unowned. No derived view ships. When the matrix lands it is REGENERATED
       from the spec per the registry-plus-views call — never hand-edited, so it cannot drift.
       This replaces the three-way hand-sync duty devils-advocate found unowned.

Duty: advance a matrix row past `not started`
Owner: OUT OF SCOPE with the matrix itself. NOT /backlog, which emits a tree and does not write
       to ADO (brief :93, :161) — the ADO ID writer is devops-azure batch mode.

Duty: recover from an interrupted run
Owner: skill step 1's manifest-driven branch. Resume or complete the same slug; never a new one.

Duty: detect that a source changed after intake
Owner: skill step 1, comparing current file hashes against the manifest's recorded hashes.
       Previously nobody's; the manifest makes it a lookup rather than a judgement.

Duty: keep emitted artifacts out of this cut's own commit
Owner: BAR-003 and BAR-006 run in a scratch project OUTSIDE this repo — the disposition
       plan-spine BAR-003 used — so nothing is created under this repo's docs/ to sweep.
       agents/merge-reviewer.md:476 is `git add -A`; if a bar is nonetheless run in-repo its
       artifacts must be deleted first. Step 9 warns the operator of the same hazard for a real
       run whose artifacts sit uncommitted while an /implement pipeline finishes.
```

Duty/file diff: every owner in both blocks holds a file in the edit set
(`skills/spec-intake/SKILL.md`, `skills/interview-me/SKILL.md`) except the operator, the dissolved
sync duty, and the out-of-scope matrix duties — each disclosed with its consequence.

### Step 1 — `skills/spec-intake/SKILL.md` (new file)

Frontmatter: `name: spec-intake` (must equal the directory name), and a `description` under 1024
characters carrying (a) the three accepted input shapes, (b) the input-property routing rule
(requirements *in a document* → here; *in a human's head* → `/interview-me`), (c) the trigger phrases a
BA would actually say, and (d) `Do NOT use when the requirements are only in someone's head — use
/interview-me first.` **Neither `.docx` nor `.xlsx` may appear in the description at all** — say
"attempts inline conversion using whatever the machine has, and reports what it could not convert." It
must not name a traceability matrix.

Nine numbered steps:

**1. Resolve the target, the output path, and the run state.** File path(s), a directory, an
`/interview-me` brief (`docs/*-brief.md`, recognised by its `## Design Brief` heading and treated as
already-markdown), or nothing supplied → ask. Resolve `spec_dir` from `docs/CONVENTIONS.md`
(`- **Spec directory:**`), defaulting to `docs/specs`, applying **the same guard
`agents/tech-lead.md` applies to the plan directory — point at that file's rejection table, do not
reproduce its rows**, since a second copy is the staleness bug the pointer avoids. Propose a
kebab-case `<feature>` slug and confirm it once. Then branch on run state:

| Found | Action |
|---|---|
| no manifest, no spec | fresh run — proceed |
| manifest `status: in progress` | **resume**: write only what is absent, touch no existing file, never mint a new slug |
| manifest `status: complete` and spec present | **stop and ask** — amend the spec by hand; a second slug would create a second spec of record |
| spec present, no manifest | **stop and ask**; offer to write a manifest recording that provenance is unknown |
| manifest present, source hashes differ from those recorded | **stop and say so** — the sources changed since intake; the operator decides whether this is an amendment or a new feature |

**2. Survey before transforming.** Directory mode lists every file with its extension and size,
non-recursively, and names each subdirectory with its file count so the operator can opt in. Above
**20 files**, warn and offer to narrow to a subdirectory or an explicit list — `/smell`'s cap, adopted
whole. Never truncate with "…and N more"; that is silent narrowing produced by the step that exists to
prevent it. Do not filter silently — a file that will be skipped still appears here.

**3. Convert (step 0), capability-probed.** Probe, then attempt; never declare support. Include this
table verbatim:

| Input | Attempt, in order | If no rung works |
|---|---|---|
| `.md`, `.markdown`, `.txt` | none needed — ingest as-is (**preferred input**) | n/a |
| `/interview-me` brief | none needed | n/a |
| `.csv` | parse with `Import-Csv` (never a naive split on `,`), render as a markdown table, report rows × columns read, and state what a CSV cannot carry | skip — `CSV could not be parsed` |
| `.docx` | 1. `pandoc -f docx -t markdown` when `pandoc` resolves — reads all parts. 2. PowerShell: copy out of the Word lock, `[System.IO.Compression.ZipFile]::ExtractToDirectory`, strip tags from `word/document.xml`, **then enumerate the remaining text-bearing parts and report them as omitted with a severity** | skip — `no .docx converter available on this machine` |
| `.xlsx` | not converted — but **probe `xl/workbook.xml` and name the sheets** | skip — `XLSX skipped; contains N sheets: <names>. Export **each** sheet as its own named file — Excel's Save As exports only the active sheet — then re-run` |
| `.pdf`, `.pptx`, `.msg`, images | not attempted | skip, naming the type |

Invocation rules, stated with their reason: invoke Git Bash by literal path
(`C:\Program Files\Git\bin\bash.exe`), never `(Get-Command bash)`; do not embed `${...}` or unquoted
spaces in a string handed to a native executable; trust `$LASTEXITCODE`, not `$?`; hash sources with
`Get-FileHash -Algorithm SHA256`.

**Read-back, three tests:**

1. **Empty** — no non-whitespace output → tool breakage, not a result. Skip with that reason.
2. **Suspect** — fewer than 200 non-whitespace characters, or fewer than 1% of the source's byte
   count. Report both numbers and ask before ingesting. Never ingest a suspect conversion silently.
3. **Coverage** — on rung 2, enumerate the text-bearing parts present in the package and name those
   not read, each with a severity: **high** — `word/footnotes.xml`, `word/endnotes.xml`, and
   textbox/drawing content; **medium** — `word/comments.xml`; **low** — `word/header*.xml`,
   `word/footer*.xml`. Any omission makes the file `partially ingested`.

State two limits in the file: these tests cannot see content mangled *inside* a part that was read;
and the omitted parts are **not scraped by default**, because text pulled from comments or headers
arrives unordered and decontextualized and can manufacture false requirement context. If the operator
asks for them, label the result `unordered, decontextualized — verify against the original` and carry
that label into the locator of every requirement sourced from it.

**4. Report, acknowledge, then confirm — the gate.** Emit found / ingested / partially ingested /
skipped, with a reason per non-`ingested` file and the omitted parts listed high severity first. Say
the stale-original sentence out loud: *"The markdown I write becomes the spec of record. The originals
become frozen inputs — edits made to them afterwards will not appear in the spec."* State the hard
rule: **adapt the method, never silently narrow the scope.** Pointed at three `.docx` and one `.md`,
ingesting only the markdown without saying so is the worst available outcome — the BA believes
everything was captured and Stage 4 later verifies against a spec missing most of its input. A skipped
file is a stated outcome, not an omission; so is a partially read one.

**Require two things before proceeding:** explicit acknowledgement of every high- and medium-severity
omission, and explicit confirmation of the report as a whole. Without both, no id is minted and no
artifact is written.

**5. Mint the `REQ-nnn` ids — only now.** State the reason in the file: minting before step 4's gate
means a silently missed requirement can only be added later by appending out of order or renumbering,
and renumbering is forbidden because downstream joins on the id. After minting, append-only — never
renumber, never reuse, never delete silently.

**6. Open the manifest** at `<spec_dir>/<feature>.manifest.md`, before writing the spec, so an
interrupted run leaves evidence of itself:

````markdown
---
run_id: 2026-07-30T14-22-claims-intake
feature: claims-intake
status: in progress          # in progress | complete | abandoned
started: 2026-07-30T14:22
completed: n/a
artifacts: []
sources:
  - path: docs/source/requirements.docx
    sha256: 9f2b1c...
    kind: docx
    method: powershell-zipfile-extract
    disposition: partially ingested
    parts_scanned: [word/document.xml]
    parts_omitted:
      - part: word/footnotes.xml
        severity: high
        acknowledged: 2026-07-30T14:26
      - part: word/header1.xml
        severity: low
        acknowledged: 2026-07-30T14:26
  - path: docs/source/rates.xlsx
    sha256: 1c8e44...
    kind: xlsx
    disposition: skipped
    reason: XLSX skipped — export each sheet as its own named file and re-run
    sheets: [Login, Payments, Reserves, Rates, Notes, Audit]
---

# Intake run: claims-intake

Written by `/spec-intake`. **Not hand-edited** — it records what one run saw. The spec of
record is the authoritative artifact; this file is its provenance.
````

**7. Write the spec of record** to `<spec_dir>/<feature>.md`:

````markdown
---
feature: claims-intake
spec_status: intake
exemplar: "Claims > Loss Notice detail"
intake_date: 2026-07-30
manifest: docs/specs/claims-intake.manifest.md
---

# Spec of record: Claims Intake

**This file is the spec of record and the single authoritative artifact.** The sources listed in
the manifest are frozen inputs as of `intake_date`; edits made to them afterwards are not
reflected here. Anything derived from this file is regenerated, never hand-edited.

## Intake report

| File | Disposition | Reason |
|---|---|---|
| requirements.docx | **partially ingested** | `word/footnotes.xml` (high) and `word/header1.xml` (low) present but not read — acknowledged 14:26 |
| fields.md | ingested | already markdown |
| rates.xlsx | **skipped** | 6 sheets: Login, Payments, Reserves, Rates, Notes, Audit — export each as its own file and re-run |
| mockup.png | **skipped** | image, not a text document |

## Scope

Two or three sentences. What this feature covers, and what it explicitly does not.

## Requirements

### REQ-001 — Date of loss is recorded

- **Status:** active
- **Statement:** The claim handler records the date of loss on the Loss Notice.
- **Source refs:**
  - `requirements.docx` · `word/document.xml` · heading "Loss Notice" · "the claim handler
    records the date of loss"
  - `fields.md` · "Date of loss — required, not future"
- **Rationale / notes:** Drives the reserve calculation.
- **Lineage:** —
- **Last reviewed:** 2026-07-30

### REQ-002 — Claim number is generated and immutable

- **Status:** active
- **Statement:** A claim number is generated on first save and cannot be changed afterwards.
- **Source refs:**
  - `requirements.docx` · `word/document.xml` · "A claim number is generated on first save"
  - `fields.md` · "Claim number — generated, editable by supervisors"
- **Conflict note:** `fields.md` allows supervisor edits; `requirements.docx` says immutable.
  Not resolved at intake — see Open questions.
- **Lineage:** —
- **Last reviewed:** 2026-07-30

## Exemplar

Claims > Loss Notice detail — the screen later work is patterned on. Named because it
exercises validation, a generated key, and a child collection in one place.

## Open questions

- REQ-002: which source governs — is the claim number immutable, or supervisor-editable?

## Appendix A — Field inventory

| Screen | Field | Type | Required | Source / derivation | Validation | REQ |
|---|---|---|---|---|---|---|
| Loss Notice detail | Date of loss | date | yes | user entry | not later than today | REQ-001 |
| Loss Notice detail | Claim number | string(20) | yes | generated on first save | unique | REQ-002 |

### Not captured at intake

- Claims > Reserves tab — named in REQ-007 but its fields are not enumerated in any source.
````

Rules stated alongside the block: the ten per-requirement fields, with `Conflict note` present only
when sources disagree and `Lineage` carrying `split_from` / `merged_from` / `supersedes` /
`superseded_by`. Status is one of `proposed`, `active`, `withdrawn`, `superseded`; intake mints
`active`. Ids are permanent and append-only. **Every `Source refs` entry is source file + extracted
part + a nearby heading only if literal + a short verbatim quote**, falling back to the requirement's
first few verbatim words; never a synthesized section number, because Word's automatic heading numbers
live in `word/numbering.xml` and an invented `§ 3.2` looks like evidence while being unfindable in the
original. Conflicting sources are both recorded and raised in `## Open questions` — never silently
resolved. Appendix A always ships, because field detail is the most perishable content in the source; a
source with no field detail yields an empty table and a populated `### Not captured at intake`. If the
source names no exemplar, ask; if the operator does not know, write
`exemplar: none — not identified at intake` rather than omitting the key.

**8. Complete the manifest and confirm the exemplar.** Set `status: complete`, `completed:`, and
`artifacts:`. Then restate the exemplar screen and why, so the operator can correct it before the spec
is used downstream.

**9. Report and hand off.** List the paths written; restate the skipped and partially ingested files a
second time, deliberately, because those lines are the ones most likely to be skimmed. Note that the
operator commits the artifacts, and warn that artifacts left uncommitted in a repo where an
`/implement` pipeline is running will be swept into that pipeline's commit by merge-reviewer's
`git add -A`. State that the spec is authoritative and hand-editable, and that a traceability matrix is
not produced by this version. Offer `/plan` next; name `/backlog` as the eventual Stage 2 entry point
and say plainly that it does not exist yet.

**Gotchas** to include: a `.docx` open in Word is file-locked, so copy before extracting; a conversion
that returns nothing means the tool broke, not that the document was empty; a conversion that returns
*most* of a document is the failure read-back cannot see, which is why omitted parts are acknowledged
rather than noted; never pick a second slug for a feature that already has a spec — amend it, because
two specs of record for one feature is the failure this skill exists to prevent; `/spec-intake` is not
a review — it transcribes and inventories, it does not judge whether the requirements are good;
requirements only in someone's head belong in `/interview-me` first.

### Step 2 — `skills/interview-me/SKILL.md` step 6

Add a third hand-off branch, gated on step 4's existing signals and no others:

- **Signal (b), all branches resolved** → **ask**, once:
  *"Do you want a spec of record for this — requirements captured with source locators and a field
  inventory — or just build it?"* On yes, route to `/spec-intake` with the written brief path as the
  input. Name the artifacts, not the pipeline, because the artifacts are what the user is choosing
  between — and name only artifacts this cut ships, which is why the traceability matrix is absent
  from the wording.
- **Signal (a), user said "let's go" / "implement it"** → **do not ask.** Note once, in one line:
  *"No Stage 0 artifact for this, so `/verify-spec` will have nothing to check it against later."*
  Then proceed to `/implement`.

State in the file *why* the mechanism differs from the other two branches: `/plan` vs. `/implement` is
inferable from interview state, whereas whether work is a tracked deliverable is an organizational fact
no interview content answers. Add a gotcha: **do not ask on signal (a)** — the user just declined
ceremony, and re-imposing it contradicts "Don't over-interview" directly above.

### Step 3 — `docs/CONVENTIONS.template.md`

Add, adjacent to the existing `## Plan Artifacts` section at :25-26:

```markdown
## Spec Artifacts
- **Spec directory:** [e.g., docs/specs/]
- **Traceability directory:** [e.g., docs/traceability/]
```

Both seeded deliberately, matching the plan key, so the template documents all three path knobs at
once. The placeholder this creates is the case both readers' `^\[` rule already rejects.

### Step 4 — `README.md`

Skills-table row for `/spec-intake`; the spelled-out count at :71 updated from a **fresh recount**
(`ls -d skills/*/ | wc -l`), never by incrementing the printed number, per
`skills/pack-review/SKILL.md:35-43`; a "Choosing a flow" row (*Holding a requirements document* |
`/spec-intake` | Planning | *Transcribes it into an authoritative spec of record with a field
inventory*). Document both new keys where the plan-directory key is described at :260, stating that an
unfilled `[e.g., ...]` value counts as unset and that **`- **Traceability directory:**` is reserved for
a deferred artifact and is read by nothing today**.

### Step 5 — `docs/ado-delivery-pipeline-brief.md`

Record the spec-of-record and manifest formats as resolved, pointing at `docs/plans/spec-intake.md`,
and the **traceability matrix format as explicitly deferred** to the cut that builds the ADO write path
— with the reason: freezing seven columns against no consumer is how an emitted artifact goes stale,
and `/backlog`'s input is the plan spine's bars plus a spec, not the matrix. Leave the Stage 4
output-format question open. In scope from the start, deliberately: cut two shipped this same edit as an
unplanned deviation because a design record left asserting a resolved question as open is a fresh
staleness bug.

### Sequencing

Steps 1 and 2 are one coupled edit — the sequencing constraint is that they land together, and a single
writer with both files in context is how that is guaranteed. Steps 3, 4, and 5 follow and may run in
parallel with each other.

## Acceptance bars

- BAR-001: `skills/spec-intake/SKILL.md` exists, `name` matches the directory, and its `description` carries the input-property routing rule plus the `Do NOT use ... use /interview-me first` pointer without promising `.docx`/`.xlsx` support or naming a traceability matrix
  Evidence: manual -> `& "C:\Program Files\Git\bin\bash.exe" scripts/lint-agents.sh` exits 0 and its last line reads `<N> passed, 0 failed`; separately `ls -d skills/*/ | wc -l` returns 28 — lint-agents.sh prints no per-type count (`scripts/lint-agents.sh:200-201` prints only the combined totals), so the count comes from the method at `skills/pack-review/SKILL.md:39`. Then grep the `description` for the literals `in a document` and `use /interview-me first`, and confirm none of `.docx`, `.xlsx`, or `matrix` appears in it at all — a substring absence is checkable where "does not promise support" is not
- BAR-002: both artifact formats are specified as fenced copy-ready blocks — the spec with `REQ-nnn` ids, all ten per-requirement fields, plural `Source refs`, a `Conflict note` on the example whose sources disagree, and `## Appendix A — Field inventory` with its seven columns; the manifest with `run_id`, `status`, per-source `sha256`, `parts_scanned`, `parts_omitted` carrying `severity` and `acknowledged`, and `sheets` on the skipped `.xlsx`
  Evidence: files -> skills/spec-intake/SKILL.md steps 6 and 7. Check by literal, not by impression: each block is inside a fence; the spec block contains `REQ-001`, `Status: active`, two `Source refs` entries under one requirement, `Conflict note:`, `Lineage:`, `Last reviewed:`, and an `## Appendix A` heading whose table header row splits into exactly 7 cells; the manifest block contains `run_id:`, `status: in progress`, `sha256:`, `parts_scanned:`, `severity: high`, `acknowledged:`, and `sheets:`. No traceability-matrix block appears anywhere in the file
- BAR-003: the skill reports found / ingested / partially ingested / skipped before any write, **blocks on acknowledgement of every high- and medium-severity omission**, and the `.docx`'s own content reaches `## Requirements` — a run that reports dispositions while skipping the `.docx` must not satisfy this bar
  Evidence: manual -> in a scratch project outside this repo (so `agents/merge-reviewer.md:476`'s `git add -A` cannot sweep the output), a directory holding (a) `notes.md` containing `SENTINEL-MD-0730`, (b) `requirements.docx` whose body contains `SENTINEL-DOCX-0730` and whose **footnote** contains `SENTINEL-FOOT-0730`, (c) `mockup.png`. Run /spec-intake. Confirm the run **stops for acknowledgement** naming `word/footnotes.xml` at severity high, and that `git status --short` shows nothing under `<spec_dir>` at that moment. Acknowledge and confirm, then grep the written spec for both body sentinels inside `## Requirements`, for the `.png` skip reason in `## Intake report`, and the manifest for `word/footnotes.xml` with `severity: high` and a non-empty `acknowledged:`. `SENTINEL-FOOT-0730` must be **absent** from the spec — it proves the omission is real rather than narrated. Record `git hash-object <spec_dir>/<feature>.md` for BAR-006
- BAR-004: the conversion ladder is probe-then-attempt with a per-format fallback reason; `.xlsx` is skipped with a sheet list probed from `xl/workbook.xml` and per-sheet export wording; `.csv` is parsed and reports rows × columns with a statement of what it cannot carry; read-back is three named tests; and the file states both of read-back's limits
  Evidence: files -> skills/spec-intake/SKILL.md step 3. Every row of the conversion table has a non-empty "If no rung works" cell; the `.xlsx` row contains `xl/workbook.xml` and the literal `each` sheet wording; the `.csv` row names `Import-Csv` and the file states `hidden rows` and `non-active` among what a CSV cannot carry; the invocation rules name `C:\Program Files\Git\bin\bash.exe`, `$LASTEXITCODE`, and `Get-FileHash`; the short test names both `200` and `1%`; the coverage test names `word/footnotes.xml`, `word/endnotes.xml`, `word/comments.xml`, and `word/header*.xml` with a severity each; and both limit statements are present, including the refusal to scrape omitted parts by default
- BAR-005: `/interview-me` step 6 asks the artifacts question on termination signal (b) and, on signal (a), emits the one-line no-Stage-0 note **without** asking — and the ask names only artifacts this cut ships
  Evidence: files -> skills/interview-me/SKILL.md step 6 and its new gotcha. Four lookup targets, all in that file: the signal-(b) branch contains a question naming the spec of record and the field inventory and the string `/spec-intake`, and **does not contain** `traceability matrix`; the signal-(a) branch contains the note text and the words `do not ask`; and a gotcha under `## Gotchas` states the same prohibition beside the existing `Don't over-interview` gotcha. Note the limit: files evidence establishes that the file instructs this, not that a live run obeys it
- BAR-006: run state drives recovery — a completed run stops and asks, an interrupted run resumes the same slug, a changed source is detected by hash, and no path ever overwrites an existing spec
  Evidence: manual -> with BAR-003's artifacts in place, re-run /spec-intake on that slug; confirm it stops, names the existing paths, writes nothing (`git status --short`), and `git hash-object <spec_dir>/<feature>.md` still matches BAR-003's recorded value — an unchanged hash distinguishes "declined to write" from "rewrote identical content". Then set the manifest's `status:` back to `in progress` and re-run: confirm it offers to **resume the same slug** rather than proposing a new one, and that the spec's hash is still unchanged afterwards. Finally append a byte to `notes.md` and re-run: confirm it reports the source-hash mismatch against the manifest instead of proceeding silently
- BAR-007: `- **Spec directory:**` resolves with a documented default and is guarded by a **pointer** to `agents/tech-lead.md`'s rejection table rather than a copy of its rows; both keys are seeded in the template; and README states that the traceability key is reserved for a deferred artifact
  Evidence: files -> skills/spec-intake/SKILL.md step 1, docs/CONVENTIONS.template.md, README.md. Step 1 contains the literals `- **Spec directory:**`, `docs/specs`, and a reference to `agents/tech-lead.md`, and does **not** reproduce that file's `Reject when the value` table — a duplicated table is the staleness bug the pointer avoids, so its presence fails the bar. The template contains a `## Spec Artifacts` section with both keys as `[e.g., ...]` placeholders. README documents both keys at :260 with the `[e.g., ...]`-is-unset rule, and says the traceability key is read by nothing today
- BAR-008: README's skill count matches a fresh recount, a `/spec-intake` row appears in both tables and mentions no matrix, and the brief records the spec and manifest formats as resolved **and the matrix format as deferred**
  Evidence: files -> README.md skills table and flow table, docs/ado-delivery-pipeline-brief.md. `ls -d skills/*/ | wc -l` returns 28 and README.md:71 reads `Twenty-eight` — recount rather than carry the number forward, per `skills/pack-review/SKILL.md:42-43`. Grep README for a `/spec-intake` row in the skills table *and* in the "Choosing a flow" table, neither naming a traceability matrix. Grep the brief for the artifact-format entry under `### Closed since the first draft`, confirm it is absent from `## Open questions`, and confirm a separate statement deferring the matrix format with its reason
- BAR-009: `REQ-nnn` ids are minted only after the intake gate, and the file states the append-only discipline with its reason
  Evidence: files -> skills/spec-intake/SKILL.md. The minting step is numbered **after** the report-acknowledge-confirm step, not before; its prose names the failure it prevents (a missed requirement forcing out-of-order appending or a renumber); and the append-only rule states never renumber, never reuse, never delete silently. Structural ordering is what makes this checkable — a prose-only assertion placed before the gate fails the bar

## Model Overrides

None. Steps 1 and 2 meet two escalation criteria — a new pattern not in the codebase (two new artifact
formats and a seeded convention section) and cascade risk across the routing surface — but no engineer
agent is dispatched, for the reason established in `docs/plans/plan-spine-deviations.md`: no agent
description covers prompt-file editing, and stretching one to fit would make its description a lie,
which is this repo's first design pattern. The coordinating session performs the edits and the review
lenses run against them. If that call is reversed and an engineer is dispatched after all, escalate it
to `opus` on those two criteria.
