---
plan_id: spec-intake
branch: feat/spec-intake
origin_skill: plan
created: 2026-07-30
---

## What ships

`/spec-intake` — Stage 0 of the ADO delivery pipeline — as a new skill, plus the `/interview-me`
hand-off that makes it discoverable. Five files, one of them new:

1. **`skills/spec-intake/SKILL.md`** (new). Accepts a file, a **directory**, or a completed
   `/interview-me` brief. Owns conversion as its own step 0, capability-probed rather than declared,
   and reports coverage at **part granularity within a file**, not just per file. Reports what it
   found, ingested, partially ingested, and skipped **before writing anything**, and persists that
   same report inside the spec. Emits three artifacts in fully specified formats: a spec of record
   with permanent `REQ-nnn` ids, a field-level inventory, and a traceability matrix with every row
   `not started`. Names the exemplar screen.
2. **`skills/interview-me/SKILL.md` step 6** — the gated ask. Termination signal (b) asks; signal
   (a) does not ask and emits a one-line note that there is no Stage 0 artifact. Lands in this cut,
   never before it, because a hand-off offering an uninstalled command is worse than no offer.
3. **`docs/CONVENTIONS.template.md`** — a `## Spec Artifacts` section seeding the two new path keys
   next to the existing `## Plan Artifacts`. Added after challenge; see `## Calls made for you`.
4. **`README.md`** — skills-table row, the skill count (recounted, not incremented), one
   "Choosing a flow" row, and the two new path keys documented beside the plan-directory key.
5. **`docs/ado-delivery-pipeline-brief.md`** — moves "Exact wording of `/spec-intake`'s three
   artifacts" from Open questions to Closed, pointing at this plan.

The open question this cut exists to close — **the exact format of the three artifacts** — is
answered concretely in `## Build steps` as copy-ready blocks, not described.

**Challenge outcome.** devils-advocate raised fifteen concerns and three factual errors
(`memory/known-issues/2026-07-30-challenge-spec-intake-stage-0.md`). All three errors are verified
and corrected below. Eleven concerns are accepted and folded into the calls and build steps; one
(deferring an artifact) is escalated to the team lead as a decision point in `## Risks` with an exact
cut line; three are disclosed as unowned. Each affected call below reads as its **revised** form —
the challenge record lives in the memory file, so that gate 4a Tier 3 has exactly one stated call
per bullet to look up.

## What does not ship

- **No maintained converter script.** No file under `scripts/`. Conversion is inline, per-run,
  attempted from what the machine actually has. This is the settled markdown-canonical decision:
  markdown is canonical as step 0's *output*, and inline conversion inside a skill is not a
  maintained script.
- **No committed copy of the converted source.** Conversion output is transient (scratchpad), and
  the spec is authored from it in the same run. Trade-off stated in `## Risks`.
- **No agent is dispatched by the skill, and no agent file is edited.** `/spec-intake` is a
  document transformer, like `/smell` is a review dispatcher — it has no engineer, no reviewer, and
  no `git-engineer` step. `/interview-me` already writes `docs/<slug>-brief.md` with no
  `git-engineer`; the same precedent covers this.
- **No `.xlsx` cell-reconstruction attempt.** Skipped with a stated reason and a per-sheet export
  instruction. See `## Calls made for you`.
- **No `--refresh` mode.** Re-deriving the inventory and matrix from an amended spec is the named
  escalation for the sync duty in `## Risks`, not built here.
- **No later-stage work.** Nothing in this cut advances a matrix row past `not started`.
- **No new agent, no `CLAUDE.md` edit.** `CLAUDE.md` governs agent orchestration; this skill
  orchestrates none.

## Calls made for you

- **Two `docs/CONVENTIONS.md` keys: `- **Spec directory:**` (default `docs/specs`) and
  `- **Traceability directory:**` (default `docs/traceability`).** The matrix key is settled by the
  brief. The spec key exists so all three artifacts relocate together — one key would strand the
  spec in `docs/specs` for a team that moved the matrix. Both are resolved in one step, and both get
  the same string guard `agents/tech-lead.md` applies to the plan directory.
- **Both keys ARE seeded into `docs/CONVENTIONS.template.md`, under a new `## Spec Artifacts`
  section, and a `[e.g., ...]` value is treated as unset.** *Reversed after challenge, on a verified
  fact: the original call claimed the plan spine chose not to seed, and the opposite is true —*
  `docs/CONVENTIONS.template.md:26` *ships* `- **Plan directory:** [e.g., docs/plans/]` *under a*
  `## Plan Artifacts` *heading, and* `agents/tech-lead.md:55` *depends on it having done so.* Seeding
  therefore costs nothing new: the placeholder it creates is exactly the case the `^\[` guard already
  exists to reject, on both readers. It buys the thing README cannot — a BA editing
  `docs/CONVENTIONS.md` discovers the knob at the moment they are configuring paths. Not seeding
  would ship a template advertising a plan directory but neither Stage 0 directory.
- **Artifact filenames share one operator-confirmed slug**: `<spec_dir>/<feature>.md`,
  `<spec_dir>/<feature>-fields.md`, `<traceability_dir>/<feature>.md`. Proposed from the source
  title, confirmed once, reused verbatim in all three.
- **On collision the skill stops and asks — it never suffixes and never overwrites.** This
  deliberately inverts `agents/tech-lead.md`'s plan-file suffix rule, and the reason goes in the
  skill: a suffixed second plan is a harmless duplicate, whereas a suffixed second *spec of record*
  for one feature is the two-sources-of-truth failure that the whole markdown-canonical decision
  exists to prevent.
- **A partial artifact set is completed, never re-slugged.** *Added after challenge.* When some of
  the three paths exist and their `feature` and `intake_date` frontmatter agree, the skill offers to
  write **only the absent files**, deriving them from the existing spec, and touches no existing
  file. When the *spec* is the missing one, or when frontmatter disagrees, it stops and asks, naming
  the mismatch. This closes the hole in the collision rule's own escape hatch: "pick a new slug"
  applied to a half-written set leaves the orphan in place as a second spec of record for one
  feature — the exact failure the never-suffix rule exists to prevent.
- **Requirement ids are `REQ-001`-style, three digits, sequential, and permanent.** The matrix,
  ADO items, and Stage 4's gap-walk all join on them, so a renumber silently rewrites history.
- **Each requirement carries an optional `Status:` line that expresses both retirement and
  lineage.** *Added after challenge — `withdrawn` was previously representable in the matrix and
  nowhere in the artifact this plan calls canonical.* Omitted means live. Otherwise
  `Status: withdrawn 2026-08-02 — split into REQ-009, REQ-010` or
  `Status: live — supersedes REQ-002`. One optional line, two duties: a reader of the spec alone can
  tell a live requirement from a retired one, and an ADO item joined to a retired id has a forward
  link. Costs one line in the step 5 block now; every already-emitted spec lacks it if added later.
- **No field ids.** `Screen` + `Field` is the natural key and nothing downstream maps onto a field
  id. Same reasoning that kept ids off `## Deviations` in cut two: an id nothing consumes is
  ceremony.
- **Every requirement carries at least one `Source:` locator, and the locator must be a string
  literally present in the conversion output** — a heading line that survived, or the requirement's
  first several verbatim words. *Revised after challenge.* The original example (`§ 3.2`) is
  frequently unproducible on the only rung this machine has: Word's automatic heading numbers live in
  `word/numbering.xml`, not as literal text in `word/document.xml`, so on an auto-numbered source
  there is no `3.2` anywhere in the conversion and the locator gets omitted or invented. An invented
  section number is worse than none — it looks like checkable evidence and cannot be found in the
  original. Verbatim words stay findable with Ctrl-F in the `.docx`. `Source:` may repeat; when two
  sources conflict, **both** locators are recorded and the conflict goes to `## Open questions`,
  never silently resolved in favour of one.
- **Requirements are written in the source's own words where possible.** Documentation for the
  human, not an enforceable call — it names no artifact, and `agents/merge-reviewer.md:401-403` puts
  that shape permanently out of Tier 3 scope. Stated as such deliberately, because it is the
  mitigation for this cut's largest risk and a reader should know the gate cannot check it.
- **`.xlsx` is skipped by default rather than best-effort extracted, and the skip message says
  export EACH SHEET to its own `.csv`.** `sharedStrings.xml` index resolution plus cell-ref parsing
  with no real parser produces a *plausible but wrong* table, and per
  `memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md` the dangerous property of a
  broken conversion is that it reports a result rather than an error. *Per-sheet wording added after
  challenge:* Excel's Save-As-CSV exports the **active sheet only**, silently, and a requirements
  workbook is normally one sheet per screen — so "export to `.csv` and re-run" moved the lossy step
  outside the skill's field of view and turned a stated skip into an unstated narrowing.
- **`.csv` is parsed, not split, and its ingestion reports rows × columns.** *Added after
  challenge.* Quoted commas, embedded newlines, and quoted quotes are the same
  plausible-but-wrong-table hazard used to reject `.xlsx`, reached through the path the skip
  recommends — so `.csv` gets a real reader (`Import-Csv`) and a read-back that states what it read.
  A one-sheet export of a six-sheet workbook is then visible as a row count the BA can recognise as
  too small.
- **A conversion is read back before it counts as ingested, and read-back reports coverage at part
  granularity.** *Scope widened after challenge — this was the most consequential concern.*
  File-level read-back detects a conversion that produced *nothing*; it cannot detect one that
  produced *most of the document*, and on the PowerShell rung that is the likely failure, because
  `word/document.xml` does not carry headers, footers, footnotes, endnotes, or comments. A
  requirement in a footnote yields output that is long, plausible, non-empty, and short a
  requirement — and every other guard in this design (the intake report, the hard rule, the
  disposition column) operates at file granularity, so nothing could see it. The fix needs no
  parser: **enumerate the text-bearing parts present in the package, name which were read, and
  report unread parts as a within-file gap.** Rung 1 (`pandoc`) reads all parts and reports so;
  rung 2 must enumerate.
- **Dispositions are ternary: `ingested`, `partially ingested`, `skipped`.** *Added after
  challenge.* A binary vocabulary forced a partly-read file to report `ingested`, which was correct
  by its own definition and wrong in substance.
- **Read-back's "too short" threshold is named: fewer than 200 non-whitespace characters, or fewer
  than 1% of the source file's byte count.** *Added after challenge — `implausibly short` named no
  threshold, so it had no lookup target.* A conversion tripping either test is **suspect**: the skill
  reports the numbers and asks before ingesting, and never ingests a suspect conversion silently.
- **Directory mode is non-recursive by default, lists at most 25 files, and says so.**
  Subdirectories are listed with their file counts and the operator chooses. *Cap added after
  challenge:* `skills/smell/SKILL.md:50-52` — the precedent this step cites — carries a 20-file cap,
  and without one, a 200-file directory naturally produces "…and 180 more", which is silent narrowing
  produced by the step that exists to prevent it. Above the cap the skill states the total and stops
  to have the target narrowed; it never truncates a list as a fait accompli.
- **The matrix documents its own writers in its own body, and names `devops-azure` batch mode as the
  ADO ID writer.** *Corrected after challenge:* `/backlog` "emits a reviewed tree; does not write to
  ADO" (`docs/ado-delivery-pipeline-brief.md:93` and `:161`) — the ADO write is `devops-azure`'s new
  batch mode (`:162-168`). The original text would have shipped a wrong statement about who advances
  the artifact, in the artifact itself.
- **The field inventory always ships, even when the source has no field detail** — with an explicit
  `## Not captured at intake` section naming the screens whose fields the source did not enumerate.
  The reason to capture it now is **perishability**: field detail is the content most likely to be
  lost once the source goes stale, and this design deliberately lets the source go stale. (The
  weaker original reason — that an absent file is indistinguishable from a field-free source — only
  bites once something reads the file, which is three cuts out.)

## Deviations

_Deviations not yet reviewed. The coordinating session replaces this line before
merge-reviewer runs — with `None.` if nothing diverged, or one bullet per departure.
Leave this line exactly as it is._

## Risks

- **DECISION POINT FOR THE TEAM LEAD — should the traceability matrix ship in this cut?**
  devils-advocate argues for deferring both the matrix and the field inventory, on the grounds that
  freezing seven-column formats against readers that do not exist is how emitted artifacts go stale
  the moment the first real consumer deviates. The argument is sound, and the ADO-ID correction
  strengthens it: the matrix's first real writer is `devops-azure` batch mode, the *last* component
  in the chain. **My recommendation is to defer the matrix and keep the field inventory**, which
  inverts devils-advocate's specific pairing while accepting its test, on one asymmetry it raised but
  did not follow through: the matrix's initial state is **fully re-derivable** from the spec's `REQ`
  list at any later date, so deferring it loses nothing recoverable; the field inventory is
  **perishable**, extracted from a source this design deliberately lets go stale and never commits,
  so deferring it loses data. Deferring the matrix also removes the largest unowned duty in the plan.
  This is a scope reduction of a design the brief settled as three artifacts, so it is the lead's
  call, not mine. **Exact cut line if approved:** drop build step 1's numbered step 7, the matrix
  clause of BAR-002, BAR-006's `<traceability_dir>` half, the two matrix rows of the responsibility
  matrix, and the `- **Traceability directory:**` key (from step 1, the template, and README).
  Nothing else changes; the spec's frontmatter simply carries no `fields:`/matrix cross-reference.
- **Conversion capability is the one thing this cut cannot prove by reading a file.** On this
  machine `unzip` is present and `xmllint`, `bsdtar`, `pandoc`, `markitdown`, and
  `libreoffice`/`soffice` are all absent, so the `.docx` path will exercise the PowerShell rung and
  nothing else. The ladder's upper rungs ship untested by construction. BAR-004 covers the ladder's
  *shape*; only a machine with `pandoc` proves rung 1.
- **Part-granularity coverage narrows the partial-conversion hole; it does not close it.** Naming
  unread parts catches content in a part the rung never opened. It does not catch content mangled
  *within* a part it did open — a tag-strip of `word/document.xml` flattens tables and can run cell
  text together. That residue is what the `Source:`-locator rule and verbatim wording exist to make
  spot-checkable, and neither is enforceable.
- **The converted source is not committed, so extraction fidelity is not independently
  reviewable.** A reviewer reading the spec cannot diff it against what the `.docx` actually said.
  Escalation if this bites: add `<spec_dir>/<feature>.sources/` as a fourth artifact class —
  deliberately held back here as scope.
- **Keeping the three artifacts in sync after intake is unowned.** Amendments are hand edits across
  files joined by `REQ` ids, with "one row per REQ" enforced by nothing after the run ends. Named
  escalation: a `--refresh` mode that re-derives the inventory and matrix from an amended spec. Not
  built. Deferring the matrix (decision point above) removes one of the two drift surfaces.
- **The matrix has no writer for any transition past `not started` until `devops-azure` batch mode,
  `/implement` work-item mode, and `/verify-spec` land** — four cuts out, not three. A matrix can sit
  at all-`not started` indefinitely with nothing detecting it. This is the write-path-with-no-read-path
  class this pack has recorded twice today, shipped knowingly. It is the substance of the decision
  point above.
- **Two new convention keys have exactly one reader each.** If `/verify-spec` resolves them
  independently later, that is two resolvers per path — the duplication concern 12 of
  `memory/known-issues/2026-07-30-challenge-durable-plan-spine-first-cut.md` raised against
  `plan_dir`. Naming `skills/spec-intake/SKILL.md` as the single stated authority now is cheaper than
  reconciling later.
- **The intake report is a prose instruction, not a mechanical gate**, and it is generated by the
  same model that did the ingesting. A run that ingests a subset and reports completeness is
  undetectable. Persisting the report in the spec narrows this — a wrong claim survives into the PR
  diff where a human can see it — but nothing enforces it.
- **`/interview-me` step 6 grows a third branch.** The risk is over-interviewing on signal (a),
  which the skill's own gotcha warns against. The mitigation is the asymmetry: (b) asks, (a) notes
  once and proceeds. Getting that backwards makes the skill worse, so it is BAR-005.
- **The four manual bars are single samples of nondeterministic prose behaviour** — concern 9 of the
  plan-spine challenge, unchanged and unclosable here. The `git hash-object` snapshots are the best
  available mitigation, per
  `memory/context/2026-07-30-agent-output-must-be-attributable-to-be-evidence.md`, and they matter
  because BAR-006 deliberately reuses BAR-003's slug and therefore its filenames.
- **The skill file is long.** Nine steps, three format blocks, and a conversion table make it one of
  the larger `SKILL.md` files. Length is the cost of the formats being copy-ready instead of
  described, which is the point of the cut.

## Out of scope

- `/backlog`, `backlog-auditor`, `/verify-spec`, `/implement` work-item mode, and `devops-azure`
  batch write mode. All are later stages in the same brief, all sequenced after this one.
- Stage 4's stakeholder-readable output format (`/visual-explainer` vs. markdown vs. `.docx`) —
  still the brief's one remaining proposal-level open question, untouched here.
- Any change to `CLAUDE.md`, `install.sh`, or `scripts/`.
- Writing the artifacts to ADO, reading ADO, or any `az` invocation.
- Committing or PR-ing the *emitted artifacts* (as opposed to this cut's own files). The operator
  commits them, exactly as they commit an `/interview-me` brief.
- A fourth artifact class for committed conversion output, and a `--refresh` mode. Both named in
  `## Risks` as escalations; neither built.

---

## Inputs

- `docs/ado-delivery-pipeline-brief.md` — the design record. Load-bearing sections: the
  `/spec-intake` scope check (:174-228), the markdown-canonical decision **including its
  2026-07-29 refinement at :271-291** (the decision and its refinement sit in one section and read
  as a contradiction if the second half is skipped), the matrix decision (:292-310), and Open
  questions (:330-337). Also `:93`, `:161`, and `:162-168` — `/backlog` does **not** write to ADO;
  `devops-azure` batch mode does. Verified; the plan's first draft got this wrong.
- `skills/interview-me/SKILL.md` — step 4 termination signals (:46-51) are what the ask gates on;
  step 6 (:73-79) is the edit site; the "Don't over-interview" gotcha (:86) is why signal (a) does
  not ask.
- `skills/smell/SKILL.md` — precedent for a skill resolving a variable input target in a numbered
  step 1, with an include/exclude filter, a confirm-the-list rule, **and a size cap at :50-52**.
  Adopt all four; the first draft adopted three and the missing cap was a silent-narrowing path.
- `README.md` — "Choosing a flow" table (:56-65), skills table and its spelled-out count (:71),
  "Plan Spine" (:256-286) for the convention-key precedent, `:260` for where the plan-directory key
  is documented.
- `scripts/lint-agents.sh` — skill frontmatter contract: `name` must equal the parent directory
  name (:125-126), `description` ≤ 1024 chars (:142-143), valid fields are
  `name description license compatibility metadata allowed-tools` (:19), body must be non-empty
  (:166). Its only summary output is a combined `<N> passed, <N> failed` at :200-201 — **there is no
  per-type count**, so a skill count must be produced by `ls -d skills/*/ | wc -l`. `install.sh:83`
  globs `skills/*/`, so a new skill needs no registration.
- `skills/pack-review/SKILL.md:35-43` — "count, never carry forward a count", with the `ls -d
  skills/*/ | wc -l` recipe and the incident that motivated it. Governs BAR-001 and BAR-008.
- `docs/CONVENTIONS.template.md:25-26` — ships `## Plan Artifacts` with
  `- **Plan directory:** [e.g., docs/plans/]`. **The template and this repo's `docs/CONVENTIONS.md`
  are therefore not byte-identical** — they diverge at exactly that key. The first draft asserted the
  opposite and drew the no-seeding call from it; both are corrected. `agents/tech-lead.md:55` depends
  on the template seeding that key.
- `docs/CONVENTIONS.md` — every value is an unfilled `[e.g., ...]` placeholder and no
  `- **Plan directory:**` key is present, so the `docs/plans` fallback applies to this plan file.
- `agents/tech-lead.md` — the `Reject when the value` guard table, which step 1 **points at** rather
  than copies.
- `agents/merge-reviewer.md:476` — the commit step is `git add -A`, which is why the manual bars run
  in a scratch project outside this repo. `:401-403` — the Tier 3 checkable-call definition, which is
  why two call halves above are labelled documentation.
- `docs/plans/plan-spine-deviations.md` — precedent for the plan shape, and for the finding that no
  agent description covers prompt-file editing.
- `memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md` — blank output is tool
  breakage, not a result. Drives the read-back rule.
- `memory/context/2026-07-30-powershell-mangles-native-exe-arguments.md` — `${...}` and unquoted
  spaces are destroyed at the native-command boundary; trust `$LASTEXITCODE`, not `$?`; invoke Git
  Bash by literal path. Drives the conversion invocation rules and BAR-001's evidence command.
- `memory/known-issues/2026-07-30-challenge-spec-intake-stage-0.md` — this plan's own challenge
  record: fifteen concerns, three factual errors, the rewritten bars.
- `memory/known-issues/2026-07-30-challenge-durable-plan-spine-first-cut.md` — concern 12's
  actor/file reconciliation method, applied below and extended with a second axis.
- Plan directory resolution: `docs/CONVENTIONS.md` has no `- **Plan directory:**` key, so the
  `docs/plans` fallback applies. All guard conditions pass. `docs/plans/spec-intake.md` did not
  exist, so no suffix was needed.

## Build steps

Responsibility matrix first, per concern 12's method — **on two axes.** The first block enumerates
transitions *inside* a run. The second answers a question the first structurally cannot: for each
artifact, **who edits it after the run that created it?** The challenge found five duties in that
second axis, one of them misassigned rather than absent, which is why the axis is now explicit.

```
Event: target is resolved (file | directory | /interview-me brief)
Writer: none                                     Reader: skill step 1
Mutator: none                                    Verifier: operator confirms the resolved list
Failure behavior: ambiguous target -> ask, never guess (smell step 1 precedent)
Persisted state: none

Event: directory is surveyed
Writer: none                                     Reader: skill step 2
Mutator: none                                    Verifier: operator
Failure behavior: over 25 files -> state the total and stop; never truncate the list
Persisted state: none — becomes the intake report's "found" column

Event: a source file is converted
Writer: skill step 3, to the scratchpad          Reader: skill step 5 (authors the spec from it)
Mutator: none                                    Verifier: read-back — emptiness, the two-part
                                                 short test, and the part-coverage enumeration
Failure behavior: empty -> skip; suspect -> ask; parts unread -> `partially ingested`
Persisted state: none in the repo; the spec's `## Intake report` and `sources:` carry the record

Event: intake report is presented
Writer: skill step 4, to chat                    Reader: the operator
Mutator: none                                    Verifier: explicit operator confirmation
Failure behavior: no confirmation -> no artifact is written at all
Persisted state: none yet — re-emitted into the spec at step 5

Event: spec of record is written
Writer: skill step 5                             Reader: /backlog, /verify-spec, the human in a PR
Mutator: none                                    Verifier: none
Failure behavior: spec exists -> stop and ask; never suffix, never overwrite
Persisted state: <spec_dir>/<feature>.md, uncommitted, including `## Intake report`

Event: field inventory is written
Writer: skill step 6                             Reader: /verify-spec's field-level gap walk
Mutator: none                                    Verifier: none
Failure behavior: no field detail in source -> file still ships with `## Not captured at intake`
Persisted state: <spec_dir>/<feature>-fields.md, uncommitted

Event: traceability matrix is written
Writer: skill step 7                             Reader: devops-azure batch mode, /verify-spec
Mutator: none in this cut                        Verifier: none
Failure behavior: every row `not started`; no row may be written at any other value
Persisted state: <traceability_dir>/<feature>.md, uncommitted

Event: a partial artifact set is found at step 1
Writer: skill step 1 — absent files only         Reader: the operator
Mutator: none — an existing file is never touched
Verifier: frontmatter `feature` + `intake_date` must agree across the files that exist
Failure behavior: spec missing, or frontmatter disagrees -> stop and ask, naming the mismatch
Persisted state: only the previously absent path(s)

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
Duty: advance a matrix row past `not started`
Owner: OUT OF SCOPE, four cuts away — devops-azure batch mode (ADO ID), /implement work-item
       mode (in progress | implemented), /verify-spec (verified). NOT /backlog, which emits a
       tree and does not write to ADO (brief :93, :161). Disclosed in the artifact body and in
       ## Risks; it is the substance of the decision point.

Duty: retire a requirement, and record lineage on a split or merge
Owner: the operator, by hand, in the spec's `Status:` line (step 5). Previously unowned AND
       unrepresentable — `withdrawn` could be written in the matrix and nowhere in the spec.

Duty: keep spec, inventory, and matrix in sync after intake
Owner: UNOWNED. Hand edits across files joined by REQ ids; nothing enforces "one row per REQ"
       after the run. Escalation named in ## Risks: a `--refresh` mode. Step 9 tells the
       operator the ordering (spec first, then derived files) so at least the sequence is stated.

Duty: recover from an interrupted run
Owner: skill step 1's partial-set branch (above). Previously unowned, and the gotcha's
       sanctioned recovery ("pick a new slug") produced the failure the collision rule prevents.

Duty: keep emitted artifacts out of this cut's own commit
Owner: BAR-003 and BAR-006 run in a scratch project OUTSIDE this repo — the same disposition
       plan-spine BAR-003 used — so nothing is created under this repo's docs/ to sweep.
       agents/merge-reviewer.md:476 is `git add -A`; if a bar is nonetheless run in-repo, its
       artifacts must be deleted before merge-reviewer. Step 9 warns the operator of the same
       hazard for a real run whose artifacts sit uncommitted during an /implement pipeline.
```

Duty/file diff: every owner in both blocks holds a file in the edit set
(`skills/spec-intake/SKILL.md`, `skills/interview-me/SKILL.md`) except the operator, the two
explicitly unowned duties, and the out-of-scope row-advance duty — each disclosed with its
consequence rather than left implicit.

### Step 1 — `skills/spec-intake/SKILL.md` (new file)

Frontmatter: `name: spec-intake` (must equal the directory name), and a `description` under 1024
characters that carries (a) the three accepted input shapes, (b) the input-property routing rule
(requirements *in a document* → here; *in a human's head* → `/interview-me`), (c) the trigger phrases
a BA would actually say, and (d) `Do NOT use when the requirements are only in someone's head — use
/interview-me first.` **Neither `.docx` nor `.xlsx` may appear in the description at all** — say
"attempts inline conversion using whatever the machine has, and reports what it could not convert."

Nine numbered steps:

**1. Resolve the target and the output paths.** File path(s), a directory, an `/interview-me`
brief (`docs/*-brief.md`, recognised by its `## Design Brief` heading and treated as
already-markdown), or nothing supplied → ask. Resolve `spec_dir` and `traceability_dir` from
`docs/CONVENTIONS.md` (`- **Spec directory:**`, `- **Traceability directory:**`), defaulting to
`docs/specs` and `docs/traceability`. Apply **the same guard `agents/tech-lead.md` applies to the
plan directory — point at that file's rejection table, do not reproduce its rows**, since a second
copy is the staleness bug the pointer exists to avoid. Propose a kebab-case `<feature>` slug, confirm
it once, reuse it in all three filenames. Then branch on what exists:

| Found | Action |
|---|---|
| none of the three paths | proceed |
| all three | **stop and ask**, naming them |
| some, `feature` + `intake_date` agree, spec present | offer to write **only the absent** paths, derived from the existing spec; touch no existing file |
| some, spec absent | **stop and ask** — the spec cannot be derived from the others |
| some, frontmatter disagrees | **stop and ask**, naming the mismatch |

**2. Survey before transforming.** Directory mode lists every file with its extension and size,
non-recursively, and names each subdirectory with its file count so the operator can opt in. Cap the
listing at **25 files**: above that, state the total and stop to have the target narrowed — never
truncate with "…and N more", which is silent narrowing produced by the step that exists to prevent
it. Do not filter the list silently; a file that will be skipped still appears here.

**3. Convert (step 0), capability-probed.** Probe, then attempt; never declare support. Include this
table verbatim:

| Input | Attempt, in order | If no rung works |
|---|---|---|
| `.md`, `.markdown`, `.txt` | none needed — ingest as-is (**preferred input**) | n/a |
| `/interview-me` brief | none needed | n/a |
| `.csv` | parse with `Import-Csv` (never a naive split on `,`), render as a markdown table, and report rows × columns read | skip — `CSV could not be parsed` |
| `.docx` | 1. `pandoc -f docx -t markdown` when `pandoc` resolves — reads all parts. 2. PowerShell: copy out of the Word lock, `[System.IO.Compression.ZipFile]::ExtractToDirectory`, strip tags from `word/document.xml`, **then enumerate the other text-bearing parts and report which went unread** | skip — `no .docx converter available on this machine` |
| `.xlsx` | not attempted | skip — `.xlsx extraction is unreliable. Export **each sheet** to its own .csv — Excel's Save As exports only the active sheet — then re-run` |
| `.pdf`, `.pptx`, `.msg`, images | not attempted | skip, naming the type |

Invocation rules, stated in the file with their reason: invoke Git Bash by literal path
(`C:\Program Files\Git\bin\bash.exe`), never `(Get-Command bash)`; do not embed `${...}` or unquoted
spaces in a string handed to a native executable; trust `$LASTEXITCODE`, not `$?`.

**Read-back, three tests, all stated in the file:**

1. **Empty** — no non-whitespace output → tool breakage, not a result. Skip with that reason.
2. **Suspect** — fewer than 200 non-whitespace characters, or fewer than 1% of the source's byte
   count. Report both numbers and ask before ingesting. Never ingest a suspect conversion silently.
3. **Coverage** — on rung 2, enumerate the text-bearing parts present in the package
   (`word/document.xml`, `word/header*.xml`, `word/footer*.xml`, `word/footnotes.xml`,
   `word/endnotes.xml`, `word/comments.xml`) and name the ones not read. Any unread part makes the
   file `partially ingested`, with the part names as the reason.

State read-back's own limit in the file: these tests catch a conversion that produced nothing, one
that produced implausibly little, and one that skipped whole parts. They do **not** catch content
mangled inside a part that was read.

**4. Report, then confirm.** Emit found / ingested / **partially ingested** / skipped, with a reason
per non-`ingested` file, and say the stale-original sentence out loud: *"The markdown I write becomes
the spec of record. The originals become frozen inputs — edits made to them afterwards will not
appear in the spec."* State the hard rule in the file, in these terms: **adapt the method, never
silently narrow the scope.** Pointed at three `.docx` and one `.md`, ingesting only the markdown
without saying so is the worst available outcome — the BA believes everything was captured and
Stage 4 later verifies against a spec missing most of its input. A skipped file is a stated outcome,
not an omission; so is a partially read one. Require explicit confirmation before step 5.

**5. Write the spec of record** to `<spec_dir>/<feature>.md`:

````markdown
---
feature: claims-intake
spec_status: intake
exemplar: "Claims > Loss Notice detail"
intake_date: 2026-07-30
sources:
  - path: docs/source/requirements.docx
    kind: docx
    method: powershell-zipfile-extract
    converted: 2026-07-30
  - path: docs/source/fields.md
    kind: md
    method: none — already markdown
    converted: n/a
---

# Spec of record: Claims Intake

**This file is the spec of record.** The sources above are frozen inputs as of `intake_date`;
edits made to them afterwards are not reflected here.

## Intake report

| File | Disposition | Reason |
|---|---|---|
| requirements.docx | **partially ingested** | PowerShell ZipFile extract — `word/footnotes.xml` and `word/header1.xml` present but not read |
| fields.md | ingested | already markdown |
| rates.xlsx | **skipped** | .xlsx extraction unreliable — export each sheet to its own .csv and re-run |
| mockup.png | **skipped** | image, not a text document |

## Scope

Two or three sentences. What this feature covers, and what it explicitly does not.

## Requirements

- **REQ-001** — The claim handler records the date of loss on the Loss Notice.
  Source: requirements.docx — "The claim handler records the date of loss"
- **REQ-002** — A claim number is generated on first save and is immutable thereafter.
  Source: requirements.docx — "A claim number is generated on first save"
  Source: fields.md — "Claim number — generated, immutable"
  Status: withdrawn 2026-08-02 — split into REQ-009, REQ-010

## Exemplar

Claims > Loss Notice detail — the screen later work is patterned on. Named because it
exercises validation, a generated key, and a child collection in one place.

## Open questions

- REQ-002: the source does not say whether the generated claim number is per-year or global.
````

Rules stated alongside the block: ids are `REQ-nnn`, sequential, three digits, permanent — never
deleted, never renumbered, never reused, because the matrix and ADO join on them. Retirement and
lineage go in the optional `Status:` line; omitted means live. Every requirement carries at least one
`Source:` locator, and **the locator must be a string literally present in the conversion output** —
a surviving heading, or the requirement's first several verbatim words. Never an invented section
number: Word's automatic heading numbers are not literal text in `word/document.xml`, so `§ 3.2` is
usually unproducible and an invented one looks like evidence while being unfindable. `Source:` may
repeat; conflicting sources are both recorded and the conflict is raised in `## Open questions`.
Prefer the source's own sentence to a paraphrase. If the source names no exemplar, ask; if the
operator does not know, write `exemplar: none — not identified at intake` rather than omitting the
key.

**6. Write the field inventory** to `<spec_dir>/<feature>-fields.md`:

````markdown
---
feature: claims-intake
spec: docs/specs/claims-intake.md
intake_date: 2026-07-30
---

# Field inventory: Claims Intake

| Screen | Field | Type | Required | Source / derivation | Validation | REQ |
|---|---|---|---|---|---|---|
| Loss Notice detail | Date of loss | date | yes | user entry | not later than today | REQ-001 |
| Loss Notice detail | Claim number | string(20) | yes | generated on first save | unique; immutable | REQ-002 |

## Not captured at intake

- Claims > Reserves tab — named in REQ-007 but its fields are not enumerated in any source.
````

The file always ships, because field detail is the most perishable content in the source and this
design lets the source go stale. A source with no field detail produces a table with no rows and a
populated `## Not captured at intake`.

**7. Write the traceability matrix** to `<traceability_dir>/<feature>.md`:

````markdown
---
feature: claims-intake
spec: docs/specs/claims-intake.md
fields: docs/specs/claims-intake-fields.md
intake_date: 2026-07-30
---

# Traceability matrix: Claims Intake

Requirement → implementation → verified. **This file owns requirement coverage; ADO owns work
item state and hours. The `ADO ID` column is the only join between them.**

Status: `not started` → `in progress` → `implemented` → `verified`, plus `withdrawn`.
Every row starts at `not started`.

Rows are advanced by `devops-azure` batch mode (ADO ID), `/implement` work-item mode
(in progress, implemented), and `/verify-spec` (verified). **None of those three exists yet —
until they do, advance rows by hand.**

| REQ | Requirement | Fields | ADO ID | Implementation | Status | Verified |
|---|---|---|---|---|---|---|
| REQ-001 | Record date of loss | Loss Notice detail: Date of loss | — | — | not started | — |
| REQ-002 | Generate immutable claim number | Loss Notice detail: Claim number | — | — | not started | — |
````

One row per `REQ`, no exceptions — a requirement with no row is invisible to Stage 4.

**8. Confirm the exemplar.** Restate the named exemplar screen and why, so the operator can correct
it before the artifacts are used downstream.

**9. Report and hand off.** List the paths written, restate the skipped and partially ingested files
(a second time, deliberately — those lines are the ones most likely to be skimmed), and note that
the operator commits the artifacts. Warn that uncommitted artifacts sitting in a repo where an
`/implement` pipeline is running will be swept into that pipeline's commit by merge-reviewer's
`git add -A`. State the amendment ordering: edit the spec first, then the derived files, because
nothing verifies the join afterwards. Offer `/plan` next; name `/backlog` as the eventual Stage 2
entry point and say plainly that it does not exist yet.

**Gotchas** to include: a `.docx` open in Word is file-locked, so copy before extracting; a
conversion that returns nothing means the tool broke, not that the document was empty; a conversion
that returns *most* of a document is the failure read-back cannot see, which is why unread parts are
reported; do not re-run intake on a feature whose full artifact set already exists — amend it (never
pick a second slug, which would create a second spec of record for one feature); `/spec-intake` is
not a review — it transcribes and inventories, it does not judge whether the requirements are good;
requirements only in someone's head belong in `/interview-me` first.

### Step 2 — `skills/interview-me/SKILL.md` step 6

Add a third hand-off branch, gated on step 4's existing signals and no others:

- **Signal (b), all branches resolved** → **ask**, once:
  *"Do you want a spec of record and traceability matrix for this, or just build it?"* On yes, route
  to `/spec-intake` with the written brief path as the input. Name the artifacts, not the pipeline —
  the artifacts are what the user is choosing between.
- **Signal (a), user said "let's go" / "implement it"** → **do not ask.** Note once, in one line:
  *"No Stage 0 artifact for this, so `/verify-spec` will have nothing to check it against later."*
  Then proceed to `/implement`.

State in the file *why* the mechanism differs from the other two branches: `/plan` vs. `/implement`
is inferable from interview state, whereas whether work is a tracked deliverable is an
organizational fact no interview content answers. Add a gotcha: **do not ask on signal (a)** — the
user just declined ceremony, and re-imposing it contradicts "Don't over-interview" directly above.

### Step 3 — `docs/CONVENTIONS.template.md`

Add, adjacent to the existing `## Plan Artifacts` section at :25-26:

```markdown
## Spec Artifacts
- **Spec directory:** [e.g., docs/specs/]
- **Traceability directory:** [e.g., docs/traceability/]
```

Seeded deliberately, matching the plan key. The placeholder this creates is the case both readers'
`^\[` rule already rejects.

### Step 4 — `README.md`

Skills-table row for `/spec-intake`; the spelled-out count at :71 updated from a **fresh recount**
(`ls -d skills/*/ | wc -l`), never by incrementing the printed number, per
`skills/pack-review/SKILL.md:35-43`; a "Choosing a flow" row (*Holding a requirements document* |
`/spec-intake` | Planning | *Transcribes it into a spec, field inventory, and traceability matrix*).
Document both new keys where the plan-directory key is described at :260, including that an unfilled
`[e.g., ...]` value counts as unset.

### Step 5 — `docs/ado-delivery-pipeline-brief.md`

Move "Exact wording of `/spec-intake`'s three artifacts" from Open questions to Closed since the
first draft, pointing at `docs/plans/spec-intake.md`. Leave the Stage 4 output-format question open.
In scope from the start, deliberately: cut two shipped this same edit as an unplanned deviation
because a design record left asserting a resolved question as open is a fresh staleness bug.

### Sequencing

Steps 1 and 2 are one coupled edit — the sequencing constraint is that they land together, and a
single writer with both files in context is how that is guaranteed. Steps 3, 4, and 5 follow, and may
run in parallel with each other.

## Acceptance bars

- BAR-001: `skills/spec-intake/SKILL.md` exists, `name` matches the directory, and its `description` carries the input-property routing rule plus the `Do NOT use ... use /interview-me first` pointer without promising `.docx`/`.xlsx` support
  Evidence: manual -> `& "C:\Program Files\Git\bin\bash.exe" scripts/lint-agents.sh` exits 0 and its last line reads `<N> passed, 0 failed`; separately `ls -d skills/*/ | wc -l` returns 28 — lint-agents.sh prints no per-type count (`scripts/lint-agents.sh:200-201` prints only the combined totals), so the count comes from the method at `skills/pack-review/SKILL.md:39`. Then grep the `description` for the literals `in a document` and `use /interview-me first`, and confirm neither `.docx` nor `.xlsx` appears in it at all — a substring absence is checkable where "does not promise support" is not
- BAR-002: all three artifact formats are specified as fenced copy-ready blocks — spec with `REQ-nnn` ids, repeatable `Source:` locators, an optional `Status:` line carrying retirement and lineage, and `sources:`/`exemplar:`/`intake_date` frontmatter; field inventory with its seven columns and `## Not captured at intake`; matrix with its seven columns, its five-value status vocabulary including `withdrawn`, and its self-documented writers naming `devops-azure` rather than `/backlog`
  Evidence: files -> skills/spec-intake/SKILL.md steps 5, 6, and 7. Check by literal, not by impression: each block is inside a fence; the spec block contains `REQ-001`, two `Source:` lines on one requirement, a `Status: withdrawn`, `sources:`, `exemplar:`, `intake_date:`; the fields block's header row splits into exactly 7 cells and the file contains `## Not captured at intake`; the matrix block's header row splits into exactly 7 cells, the status line names all five of `not started`/`in progress`/`implemented`/`verified`/`withdrawn`, and the writers paragraph names `devops-azure`, `/implement`, `/verify-spec`, the words `None of those three exists yet`, and **not** `/backlog`
- BAR-003: the skill reports found / ingested / partially ingested / skipped with a reason per non-ingested file **before** any write, requires explicit confirmation, re-emits the same table into the spec as `## Intake report`, and the `.docx`'s own content reaches `## Requirements` — a run that reports three dispositions while skipping the `.docx` must **not** satisfy this bar
  Evidence: manual -> in a scratch project outside this repo (so `agents/merge-reviewer.md:476`'s `git add -A` cannot sweep the output), a directory holding (a) `notes.md` containing the sentinel `SENTINEL-MD-0730`, (b) `requirements.docx` whose body contains `SENTINEL-DOCX-0730` and whose footnote contains `SENTINEL-FOOT-0730`, (c) `mockup.png`. Run /spec-intake. At the report, confirm all three files appear with dispositions and `git status --short` shows nothing under `<spec_dir>`/`<traceability_dir>`. After confirming, grep the written spec for **both** body sentinels inside `## Requirements`, for the `.png` skip reason inside `## Intake report`, and for `word/footnotes.xml` named as unread — the footnote sentinel is there to make the partial-read path observable rather than theoretical. Record `git hash-object <spec_dir>/<feature>.md` for BAR-006
- BAR-004: the conversion ladder is probe-then-attempt with a per-format fallback reason; read-back is three named tests (empty, the two-part short threshold, part coverage); and the file states read-back's own limit — that it cannot see content mangled inside a part it did read
  Evidence: files -> skills/spec-intake/SKILL.md step 3. Every row of the conversion table has a non-empty "If no rung works" cell; the `.xlsx` row contains the literal `each sheet`; the `.csv` row names `Import-Csv`; the invocation rules name the literals `C:\Program Files\Git\bin\bash.exe` and `$LASTEXITCODE`; the short test names both `200` and `1%`; the coverage test names at least `word/footnotes.xml` and `word/header*.xml`; and the limit paragraph is present
- BAR-005: `/interview-me` step 6 asks the artifacts question on termination signal (b) and, on signal (a), emits the one-line no-Stage-0 note **without** asking
  Evidence: files -> skills/interview-me/SKILL.md step 6 and its new gotcha. Three lookup targets, all in that file: the signal-(b) branch contains a question naming both artifacts and the string `/spec-intake`; the signal-(a) branch contains the note text and the words `do not ask`; and a gotcha under `## Gotchas` states the same prohibition, alongside the existing `Don't over-interview` gotcha it derives from. Note the limit: files evidence establishes that the file instructs this, not that a live run obeys it
- BAR-006: a second run on an existing feature slug never suffixes and never overwrites — it stops and asks when the full set exists, and when the set is **partial** it offers to write only the absent path, leaving the existing spec byte-identical
  Evidence: manual -> with BAR-003's artifacts in place, re-run /spec-intake on that slug; confirm it stops, names the existing paths, writes nothing (`git status --short`), and that `git hash-object <spec_dir>/<feature>.md` still matches BAR-003's recorded value — an unchanged hash is what distinguishes "declined to write" from "rewrote identical content". Then delete `<traceability_dir>/<feature>.md` only and re-run: confirm it names which paths it found, offers to write just the missing matrix, and after confirmation the spec's hash is *still* unchanged. Finally corrupt the spec's `intake_date` and re-run: confirm it stops on the frontmatter mismatch instead of completing
- BAR-007: both new convention keys resolve with a documented default, are seeded in the template, an unfilled `[e.g., ...]` value is treated as unset, and the guard is stated as a **pointer** to `agents/tech-lead.md`'s rejection table rather than a second copy of its rows
  Evidence: files -> skills/spec-intake/SKILL.md step 1, docs/CONVENTIONS.template.md, README.md. Step 1 contains the literals `- **Spec directory:**`, `- **Traceability directory:**`, `docs/specs`, `docs/traceability`, and a reference to `agents/tech-lead.md`; it does **not** reproduce that file's `Reject when the value` table — a duplicated table is the staleness bug the pointer avoids, so its presence fails the bar. The template contains a `## Spec Artifacts` section with both keys. README documents both keys and the `[e.g., ...]`-is-unset rule where the plan-directory key is described at README.md:260
- BAR-008: README's skill count matches a fresh recount, a `/spec-intake` row appears in both tables, and the brief's artifact-format question is listed under Closed and no longer under Open questions
  Evidence: files -> README.md skills table and flow table, docs/ado-delivery-pipeline-brief.md Open questions. `ls -d skills/*/ | wc -l` returns 28 and README.md:71 reads `Twenty-eight` — recount rather than carry the number forward, per `skills/pack-review/SKILL.md:42-43`. Grep README for a `/spec-intake` row in the skills table *and* in the "Choosing a flow" table; grep the brief for the artifact-format string under `### Closed since the first draft` and confirm it is absent from `## Open questions`

## Model Overrides

None. Steps 1 and 2 meet two escalation criteria — a new pattern not in the codebase (three new
artifact formats and two new convention keys) and cascade risk across the routing surface — but no
engineer agent is dispatched, for the reason established in `docs/plans/plan-spine-deviations.md`:
no agent description covers prompt-file editing, and stretching one to fit would make its
description a lie, which is this repo's first design pattern. The coordinating session performs the
edits and the review lenses run against them. If that call is reversed and an engineer is dispatched
after all, escalate it to `opus` on those two criteria.
