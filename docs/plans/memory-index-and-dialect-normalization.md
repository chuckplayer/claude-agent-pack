---
plan_id: memory-index-and-dialect-normalization
branch: main
origin_skill: plan
created: 2026-09-02
---

## Revision

**Revised 2026-09-02, after `devils-advocate`'s audit and operator decisions. Read this before the
rest — the plan's direction changed.** The `plan_id` is unchanged and now describes more than the
plan does; the index half is gone.

**What changed, and why:**

1. **Direction: normalization only.** `memory/INDEX.md`, gate 2d, the 45 authored `description:`
   lines and the file-to-row bijection are all out. `scripts/lint-memory.sh` still ships with its
   **dialect-conformance half only.** **BAR-004 through BAR-009 are deleted.**

   **The index is deferred, not refuted.** Its premise stands — `status`, `type` and `scope` are
   genuinely not recoverable from a filename. It fails on one verified fact: **it had no instructed
   reader.** `Glob("memory/**/*.md")` is instructed in **25** files; the plan edited **3**, leaving
   **22** that would have kept globbing and never learned the index existed. Return conditions are
   recorded in `## What does not ship` — all 25 read sites edited, plus a bar asserting no
   instruction-bearing file still directs a bare glob. **Do not re-derive this from scratch.**
2. **The required key set is a MINIMUM at seven keys**, not a closed schema at eight. Extra keys are
   permitted; `discovered:`, `resolved:`, `last-updated:` and `verified-at-commit:` all survive. The
   closed reading would have **deleted four dated facts** from a migration advertised as lossless.
   `description:` becomes **optional** — it existed only to be the index row's hook.
3. **`status: resolved` stays.** The reclassification to `archived` is dropped: it was the only place
   this plan changed a fact rather than a syntax, inside a plan whose central defence is that
   immutability protects facts and not syntax. **The operator's alternative — adding `resolved` to
   the skip filter — is also declined**, and the reason is on the record: the file documents
   `set -euo pipefail` plus a bare `read` at EOF aborting a script (a permanent constraint over the
   seven `scripts/*.sh`), the `prompt <varname> <text>` / `ASSUME_DEFAULTS` pattern any new prompt
   must follow, and it links two **active** files as the same defect class. Skipping it would bury
   live guidance in a repo whose own `CLAUDE.md` records re-shipped regressions. It would also have
   cost 19 file edits and inverted BAR-002. **Consequence: the `status:` vocabulary is not closed at
   three in this cut** — four values exist and the script accepts all four.
4. **`type:`'s value vocabulary is left open, and this is a new finding from the revision.** The
   original call closed it at five values as "the union of both dialects". Verified 2026-09-02: the
   corpus holds **seven** — `context` and `platform quirk` were missed. Closing it at five would
   force rewriting two files' `type:`, i.e. changing a fact. Presence is barred; **the value is
   deliberately unenforced and BAR-002 says so.**
5. **Audit findings folded in:** three corrected numbers in the decisive `## Risks` bullet (8 non-active
   not 7; 7-of-8 unmatchable by dialect with the 8th unmatchable by *value*; 19 instructing files not
   20); all absolute corpus counts restated as **relations**, since the audit's own required memory
   write made the corpus 52 before any build step ran; **build step 5 now edits
   `skills/memory-audit/SKILL.md` step 1 item 4**, resolving its contradiction with BAR-010 in the
   bar's favour; the `superseded-by` **resolution** check removed in favour of presence-only, because
   one file's legitimate prose value would have failed the corpus on day one; and the two grep-hazard
   memory files added to `## Inputs`.
6. **BAR-014 added** — the script's invoker and its degradation-when-absent property. With gate 2d
   gone nothing else covered either, and a linter nothing runs is the failure this pack already had
   with `obsidian-stop-hook.test.js`.

**Surviving bar ids are unchanged on purpose** — BAR-001, 002, 003, 010, 011, 012, 013, plus the new
014. The gaps at 004-009 are correct and traceable to the audit; `scripts/lint-plans.sh` requires
uniqueness, not contiguity. `## Deviations` and `## Challenge` were not touched by this revision.

## What ships

**Frontmatter dialect normalization, and nothing built on top of it.** One artifact, one script, and
four lockstep edits. **No index, no new gate, no new skill.**

1. **One frontmatter dialect** across every `*.md` file under `memory/`: fenced lowercase YAML with
   seven required keys and **extra keys permitted**. Today there are three mutually incompatible
   dialects, which is why no script can read this corpus and why the pack's own documented skip
   filter does not work on a single non-active file (see Risks — that is the one verified defect this
   cut fixes).
2. **`scripts/lint-memory.sh`** — self-testing, in the established mould of `lint-agents.sh` /
   `lint-identifiers.sh` / `lint-plans.sh`, **with its dialect-conformance half only**. It checks the
   fence, the presence of the seven required keys, and that `status:` holds a documented value. It
   asserts **no bijection** — there is nothing to be bijective with — and it **never fails on an
   unrecognised key**.
3. Lockstep edits to **`docs/MEMORY-WRITING.md`** (the spec), **`CLAUDE.md`** (the Engineer write
   permission section, which currently instructs a different dialect),
   **`skills/memory-audit/SKILL.md`** (step 1 item 4 writes the losing dialect — see build step 5),
   and **`skills/memory-query/SKILL.md`** (step 2 triages on fields almost no file has).
4. A presence check for `scripts/lint-memory.sh` in **`scripts/check-readiness.sh`**.

**This cut changes syntax and not one fact.** Every value in every key survives byte-for-byte,
including the four keys outside the required seven (`discovered:`, `resolved:`, `last-updated:`,
`verified-at-commit:`) and including the one `status: resolved` value. That is what makes "lossless"
a description rather than an aspiration, and it is the property BAR-012 exists to enforce.

## What does not ship

### The index — deferred, not refuted

**`memory/INDEX.md`, gate 2d, the 45 authored `description:` lines, and the file-to-row bijection all
come out of this cut.** The reason is one verified fact, and it is worth recording so a later reader
does not re-derive it: **the index had no instructed reader.**

`Glob("memory/**/*.md")` is instructed in **25 files** — `CLAUDE.md`, `README.md`,
`docs/AGENT-GUIDE.md`, 15 `agents/*.md`, and 7 `skills/*/SKILL.md`. The plan edited **3** of them.
The other **22 would have kept globbing and never learned `INDEX.md` existed.** So the cut would have
shipped a new artifact, a bijection lint, and a permanently blocking gate — all on the *write* side
of a read path nobody was directed to use, at a cost of 45 judgement calls whose honesty nothing can
check.

**This is a deferral on evidence, not a refusal on principle.** `status`, `type` and `scope` are
genuinely not recoverable from a filename, so the index's premise stands. If it returns it must come
with:

- edits to **all 25** read sites, not 3; and
- a bar asserting that **no instruction-bearing file still directs a bare `Glob("memory/**/*.md")`**
  without naming the index.

That is a materially larger and more visible changeset than the one this plan originally presented,
and it deserves its own cut rather than a footnote in this one. Normalization is a strict prerequisite
either way, which is why it goes first regardless of whether the index ever returns.

### Consolidation. None of it.

No file in `memory/` is merged, rewritten in body, or deleted. **No file is added or removed by this
migration at all.**

This is a deliberate reversal of the request's framing, and the reasoning matters more than the
verdict. The corpus's problems are **not redundancy**:

- **Roughly half of it is one misfiled category.** The `*challenge-*` files — 14 at the time of
  measurement, and the count rises with every audit — hold close to half the corpus's non-blank
  lines. They are `type: finding` audit narratives of a *plan*, filed under `known-issues/`. Their
  proper home already exists and is already permanent: `docs/plans/<plan>.md`, which is committed,
  never deleted, and now carries a `## Challenge` section (present in 5 plans today). One of these
  memory files says so in its own frontmatter — `2026-08-05-challenge-devops-azure-area-iteration-placement.md`
  reads `related-to: docs/plans/devops-azure-area-iteration-placement.md (its ## Challenge section
  holds the full narrative)`. That is a **relocation** question, not a consolidation question, and
  it is worth answering on its own evidence rather than folded into this cut.
- **The apparent semantic clusters are not duplicates.** The az/ADO, PowerShell and Obsidian files
  are distinct facts at distinct scopes, already cross-linked through `related-to:`. Merging them
  destroys the link graph and the per-fact dating, to save lines nobody has shown are being read.
- **Consolidation is irreversible and its benefit is unmeasured.** This pack has no telemetry, so
  no before/after token figure is available to justify it. Normalization is the prerequisite for
  ever measuring anything here, because it is the change that makes the corpus machine-readable at
  all. Consolidating first spends the irreversible move to buy an unquantified benefit.

**One correction to that diagnosis, and it is the audit's, not mine.** The framing above reads as a
closed finding — the corpus's problems are misfiling and dialects, not redundancy. It is
demonstrably **incomplete**: at least one file is *under*-divided rather than over-divided.
`2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md` mixes a resolved bug report
with two permanently live constraints, which is why decision 3 below refuses to bury it. The request
asked for consolidation; the one file with a clear structural defect wants **splitting**. The
conclusion (do not consolidate) is unaffected and if anything strengthened — but the diagnosis should
be read as open, because a plan that defers consolidation partly on the strength of a closed
diagnosis is standing on less than it appears to.

### Also not shipping

- A `/memory-index` skill or a `memory-consolidation-auditor` agent.
- **Gate 2d, or any new `agents/merge-reviewer.md` gate.** `merge-reviewer.md` is untouched by this
  cut. See call 7 for what invokes the script instead, and Risks for the residual that leaves.
- **Any reclassification of `status: resolved`** — see call 5 and decision 3 in the Revision note.
- **Any closing of the `status:` or `type:` value vocabularies.** Both stay open in this cut, and
  calls 4 and 5 say why.
- **Any fix to the `known-issues/` misfiling.** `CLAUDE.md` and `docs/MEMORY-WRITING.md` both define
  that directory as holding what "remains unresolved", so a `resolved` file in it is misfiled by the
  pack's own taxonomy in both copies of it. Build step 1 edits that very table without resolving
  this. Named so it is a known gap, not a discovered one.
- **Splitting that file.** Correct on the merits, out of scope here: it alters body text and changes
  the file count, so **BAR-012 fires on it by design.** That is the anti-scope-creep bar working, not
  an obstacle to route around.
- Any change to the five `obsidian-*.js` hooks, and any claim about token cost per dispatch.

## Calls made for you

1. **The winning dialect is fenced lowercase YAML.** A `---` fence on line 1, closed. Seven keys are
   required **in every `memory/**/*.md`**: `date`, `type`, `status`, `superseded-by`, `scope`,
   `overrides-convention`, `related-to`.
2. **That key set is a MINIMUM, not a closed schema. Extra keys are permitted and `lint-memory.sh`
   must not fail on an unrecognised one.** This is the single most load-bearing detail in the cut,
   and the original wording ("this exact key set") read as closed — which would have made the
   migration silently **delete four dated facts** from a change advertised as lossless. Verified
   extras that survive untouched: **`discovered:`** (6 files, and `CLAUDE.md`'s Engineer write
   permission section *mandates* it), **`resolved:`** (1 file), and **`last-updated:`** /
   **`verified-at-commit:`** (`repo-map.md`). `docs/MEMORY-WRITING.md` states the minimum, enumerates
   these four as sanctioned extras, and says extras are allowed.
3. **The `name:` key is dropped** — it duplicates the filename — and **`description:` is OPTIONAL,
   not required.** This follows directly from dropping the index: `description:` existed to be the
   index row's hook, and there is no row now. The 6 files that already carry one keep it; no new ones
   are authored. `skills/memory-query/SKILL.md` step 2 currently triages on `name` and `description`,
   which exist in only 6 files of the corpus; it is rewritten to triage on **the filename, plus
   `description:` where present.**
4. **`type:` is required to be present. Its value vocabulary is NOT closed in this cut.** Verified
   2026-09-02, and this corrects the plan's original call: the corpus holds **seven** type values,
   not the five a union-of-dialects reading produces — `decision`, `finding`, `constraint`,
   `pattern`, `known-issue`, **`context`** (`2026-08-03-powershell-convertfrom-json-array-double-wraps.md`)
   and **`platform quirk`** (`2026-08-05-az-mangles-non-cp1252-characters-on-output.md`). Closing the
   vocabulary at five would force rewriting two files' `type:` values, which is **changing a fact** —
   exactly what this cut refuses. `MEMORY-WRITING.md` therefore documents the observed seven as the
   recommended set and records the vocabulary as open pending the follow-on cut. **Stated plainly:
   the `type:` value vocabulary is deliberately unenforced here, and no bar claims otherwise.**
5. **`status:` accepts four values — `active | superseded | archived | resolved` — and
   `2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md` keeps `status: resolved`.**
   Its dialect migrates (it is one of the 6 nested-`metadata:` files); its value does not. The
   original call reclassified it to `archived`, which was the **only** place this plan changed a fact
   rather than syntax — sitting inside a plan whose central defence is that immutability protects
   facts and not syntax. That defence licenses everything *except* that call, so the call is dropped.
   The consequence is stated rather than hidden: **the `status:` vocabulary is not closed at three in
   this cut.** Closing it, and fixing the `known-issues/` misfiling it exposes, is a separate cut.
6. **New script `scripts/lint-memory.sh`**, exit `0` pass / `1` finding / `2` self-test failure,
   mirroring `lint-identifiers.sh`'s three-way contract. **Dialect conformance only.** Two hard
   constraints on it, both from the acceptance conditions in Risks: it **must pass on a corpus
   written to the old spec's key requirements** wherever those are a subset of the new ones, and it
   **must pass on an empty corpus** so a freshly scaffolded project is not born failing.
7. **No gate. The coordinating session invokes it, on the `lint-plans.sh` model, path-triggered on
   `memory/`** — added to both `CLAUDE.md` lists alongside the three existing script gates.
   **`/memory-audit` gains a step 4 that runs it** as well, so a hygiene pass self-checks. See
   *Who invokes `lint-memory.sh`* below; **this is the plan's most important open question** and it
   is flagged rather than papered over.
8. **No new skill.** `/memory-audit` gains only step 4 (run the lint). There is no step 5 — the
   description-honesty review died with the index.
9. **`docs/MEMORY-WRITING.md`'s singleton clause stays as it is**, naming
   `memory/architecture/repo-map.md` as its sole instance. No second member is added.
10. **`repo-map.md` IS in the migration set.** Its dialect migrates like every other file — nine
    bold keys and no fence today, becoming fenced lowercase — and its two extra keys survive under
    call 2. This is stated explicitly because the original plan left it ambiguous, and BAR-001's
    scope depends on it: *every* file under `memory/` means every file, `repo-map.md` included.
11. **Immutability protects facts, not syntax**, stated explicitly in `MEMORY-WRITING.md` rather than
    left to inference. See below.

### Why no new skill, and what `/memory-audit` gains

A dedicated `/memory-index` — or `/memory-lint` — skill would be the **third** skill globbing one
tree, and its trigger phrases would collide head-on with `/memory-audit`'s existing description. In
this pack the `description` field *is* the routing contract, so two skills claiming the same phrases
is a first-class defect, not an inconvenience.

`/memory-audit` already reads the whole corpus, and it is the one place in the pack that *writes*
memory frontmatter as its normal function. Running the dialect lint at the end of that pass costs
almost nothing and closes the loop on the skill most likely to break the dialect — see build step 5,
which is now load-bearing rather than cosmetic.

`/memory-audit` is therefore **extended, not replaced**: steps 1a, 2 and 3 are untouched, and step 1
item 4 is corrected.

### Guidance carried forward for the deferred index cut

Recorded here so the deferral does not lose the reasoning. The request asked for an index of the most
current and **meaningful** files. Completeness is lintable; meaningfulness is not, and a ranked subset
should be declined for three reasons that do not depend on anything in this cut:

1. **A ranked subset re-creates the invisibility failure by design.** The hazard of derived state is
   that a file absent from the index stops being read. Deliberately omitting "less meaningful" files
   makes that the feature.
2. **Curated relevance rots silently, and this pack's canonical failure is exactly that** — a
   curation nobody revisited is indistinguishable from one that is current. It is the reasoning
   behind the `## Deviations` sentinel and behind gate 2a. No script can check whether a ranking is
   still right.
3. **Relevance is query-dependent.** `2026-07-15-worktree-isolation-bases-off-main.md` is noise to
   `csharp-engineer` and load-bearing to `git-engineer`. No single ranking is correct for both.

So if an index returns: complete, unranked, per-row facts the reader filters at read time — plus the
25 read-site edits and the bare-glob bar named in `## What does not ship`.

### The immutability conflict: it dissolves, and this is now the plan's central claim

With the index gone, this is no longer an aside — it is the whole justification for touching dated
files at all. The dialect migration edits **frontmatter** in every dated file in the corpus. That is
sanctioned already and needs no new rule: `docs/MEMORY-WRITING.md` line 45 explicitly requires
mutating `status` and `superseded-by` on an existing dated file. The "immutable point-in-time
records" invariant has always protected **facts, not syntax**, and a format change
(`**Date:** 2026-08-04` → `date: 2026-08-04`) preserves every fact exactly. Build step 1 makes that
reading explicit in `MEMORY-WRITING.md` rather than leaving it inferred.

**Calls 2, 4 and 5 exist to keep that claim true.** Each one is a place where the original plan
would have changed a value rather than a syntax — deleting four extra keys, forcing two `type:`
values into a closed vocabulary, and rewriting one `status:` value. All three are dropped. After
that, "lossless" is a property BAR-012 can check at hunk level rather than an assurance.

### Who invokes `lint-memory.sh` — the open question, stated plainly

With gate 2d dropped, **nothing in `agents/merge-reviewer.md` re-runs this script.** That matters
because this pack has already made exactly this mistake once: `scripts/obsidian-stop-hook.test.js`
shipped 131 passing tests that **no pipeline invoked until 2026-08-03**, several of them named as
regressions for bugs already fixed once. A linter nothing runs is worse than no linter, because its
existence reads as coverage.

**The call: two invokers, neither of them an agent.**

| Invoker | Trigger | Strength |
|---|---|---|
| the **coordinating session** | any changeset touching `memory/` | blocking, on the `lint-plans.sh` model |
| **`/memory-audit` step 4** | on demand, end of a hygiene pass | blocking within that run |

`lint-plans.sh` is the precedent for the first row: `CLAUDE.md` states outright that running it "is
the coordinating session's job, not merge-reviewer's", with per-step triggers and no gate. So a
fourth script in that shape is consistent with the pack rather than novel.

**The residual, said out loud.** Gates 2a, 2b and 2c are stronger than this, and the reason is
structural: merge-reviewer holds `Bash` and *re-executes* those checks, so a session that skipped one
cannot pass it off as run. This script has no such backstop. Its enforcement is
**instruction-strength only** — BAR-014 can prove the instruction is written and can never prove it
is obeyed, which is the honest ceiling for an agent-instruction file. `/memory-audit` step 4 narrows
the gap on the highest-risk path (the skill that writes frontmatter checks its own output) but does
not close it.

**This is the plan's single most important open question and it is not settled here.** Reinstating a
merge-reviewer gate would close it; the operator has deferred that with the index, and the original
gate-2d rationale ("a new file appeared in `memory/` with no index row is a set comparison") died
with the bijection, so a gate would need a fresh justification on dialect grounds alone. Flagged for
the operator rather than decided.

## Deviations

- **Frontmatter records `branch: main`** -> the work landed on `chore/normalize-memory-dialect`.
  `CLAUDE.md` requires git-engineer to branch before any engineer runs, so `main` was never a
  candidate. The key records the branch at plan time, which BAR-013's `Cost:` line already says.
  Decided by: coordinating session, with the operator choosing this reading over rewriting the key.

- **Plan and audit artifacts were committed separately at `0fabbbc`, ahead of the implementation**
  -> departs from `CLAUDE.md`'s "the plan lands in the same commit as the implementation".
  Done because BAR-012 requires `git diff --name-status -- memory/` to show zero `A` entries, and
  `memory/known-issues/2026-09-02-challenge-memory-index-and-dialect-normalization.md` was still
  untracked — it would have appeared as an `A` and failed the bar for a reason unrelated to the
  migration. Committing it first also put it in the engineer's worktree, which BAR-001 needs since
  it quantifies over every file under `memory/`. Both artifacts are on the same branch and in order.
  Decided by: coordinating session, in preference to amending BAR-012.

- **`.gitignore` gained `.claude/worktrees/`** -> not in any stated call; a scope addition.
  `.claude/` was surfacing as untracked because the harness puts engineer worktrees there, and
  merge-reviewer holds `git add -A`. Verified effective with `git check-ignore -v`.
  Decided by: the operator, directed mid-run.

- **Call 9 said `MEMORY-WRITING.md`'s singleton clause "stays as it is"** -> two edits were made to
  it. The key name inside it was lowercased (`**Verified-at-commit:**` -> `verified-at-commit:`),
  because leaving a bold-dialect key inside the document that abolishes the bold dialect is
  self-contradictory; and "an extra `verified-at-commit:` field" became "two extra frontmatter
  fields, `last-updated:` and `verified-at-commit:`", because the clause named one and `repo-map.md`
  carries two. No second singleton member was added, which was the call's actual intent.
  Decided by: infrastructure-engineer (first edit), coordinating session (second).

- **Build step 2's scope was exceeded** -> beyond the Engineer write permission section and the two
  invocation-list entries, `Overrides-convention:` was lowercased in `CLAUDE.md`'s two Precedence
  rules lines. Those lines instruct a key spelling, so leaving them capitalised would have left
  `CLAUDE.md` teaching a retired key form. Decided by: infrastructure-engineer.

- **`agents/tech-lead.md`, `agents/devils-advocate.md` and `docs/AGENT-GUIDE.md` were converted by
  the coordinating session rather than by an engineer**, as was `scripts/lint-memory.sh`'s missing
  `status:` rule (R9) and its three code-reviewer cleanups. The plan left "who edits the pack's own
  prompt files" as an open question and named `infrastructure-engineer` the least-bad fit. Two
  patch transplants from engineer worktrees had already proven lossy — each worktree bases off
  `0fabbbc`, which predates the migration, so neither could see the file it was patching, and the
  first transplant failed atomically while the second needed a hand-merge. code-reviewer,
  smell-reviewer and test-engineer all reviewed the result, so the work was not unreviewed.
  Decided by: coordinating session.

- **BAR-010's `Evidence:` enumerated three write sites; there were eight.** The bar's *subject* was
  correct and its enumeration was short — `skills/repo-map/SKILL.md` (a full bold-key template for
  the one file call 10 puts in the migration set), `agents/tech-lead.md`, `agents/devils-advocate.md`
  and two `docs/AGENT-GUIDE.md` blocks. Found by code-reviewer and by infrastructure-engineer's own
  audit, not by the bar. The bar text was **not** amended; the missing sites were fixed instead, so
  the enumeration in the bar now under-describes what was checked. A later reader should know the
  bar shipped against a corrected list rather than the one devils-advocate audited. Recorded rather
  than absorbed because it is a bar-soundness miss — a closed allowlist that is short is
  indistinguishable from one that is complete.

- **BAR-002 was reported `NONE` by test-engineer and then satisfied.** `scripts/lint-memory.sh`
  shipped with no rule validating the `status:` value at all; a `status: pending` fixture passed
  with exit 0. Found by test-engineer, confirmed independently, and fixed by adding rule R9 plus a
  `bad/bad-status.md` self-test fixture and its `_fires` assertion. Recorded because for most of
  this run a bar claimed a check was proven while the check did not exist.
  Decided by: coordinating session, after test-engineer's finding.

## Risks

- **The live defect this fixes, stated precisely — and with the arithmetic corrected.** The original
  version of this bullet carried **three wrong numbers**, and since it is the bullet a reader would
  cite, the corrections are recorded rather than quietly applied. All figures re-verified by grep on
  2026-09-02.

  **19** instruction-bearing pack files (`CLAUDE.md`, `README.md`, `docs/AGENT-GUIDE.md`, 13
  `agents/*.md`, and `skills/memory-audit|memory-query|onboard`) instruct agents to skip files
  matching the literal `status: superseded` / `status: archived`. *(Not 20 — the 20th grep hit was
  this plan itself.)* The corpus holds **8** non-active files: 5 `archived`, 2 `superseded`, 1
  `resolved`. *(Not 7.)* Of those 8, **7 are unmatchable because of their dialect** — they carry the
  bold `**Status:**` form — and **the 8th is unmatchable because of its value**: it is a nested-YAML
  file carrying `  status: resolved`, and `resolved` appears in no documented skip pattern. *(Not
  "all 7 are bold" — those are two different defects.)*

  **So the honest claim after this cut is: normalization makes 7 of the 8 matchable, and the 8th
  stays deliberately unmatched** (call 5). The argument survives all three corrections intact — the
  dialect is the cause of the great majority of the defect, and choosing lowercase fixes it **without
  touching any of the 19 files**, since they already say `status:`. That remains the decisive
  argument for the dialect call.
- **Normalization is also a content-availability change, not only a bug fix.** Making the documented
  skip filter work **for the first time** removes those 7 files from every agent's read set. Today
  they are read by everything, because nothing matches them. This is the correct behaviour and the
  point of the exercise, but it should be named: the cut does not merely fix a pattern, it changes
  what agents see. Nothing in this plan checks whether any of the 7 is still load-bearing, and no bar
  claims otherwise. The one file where that question was live — the `resolved` one — is precisely the
  file call 5 leaves readable.
- **The remaining cost is mechanical, and that is a deliberate result rather than a happy accident.**
  Dropping the index removed the plan's largest exposure: 45 authored `description:` lines, each a
  judgement call whose honesty nothing could check. What is left is a format transformation with no
  judgement in it. **Do not reintroduce judgement into this cut** — the moment a `description:` is
  authored or a `status:`/`type:` value is chosen, BAR-012's losslessness claim stops being provable
  at hunk level.
- **A linter with no gate.** Covered in full under *Who invokes `lint-memory.sh`* above. Named again
  here because it is the plan's top residual risk and the one an implementer is most likely to leave
  half-done.
- **`docs/MEMORY-WRITING.md` is a distributed artifact — and the risk is narrower than first
  stated.** `scripts/setup-project.sh` copies it into other projects and never updates it, so
  downstream projects are **already** drifting; this change adds an instance rather than creating the
  class. The genuinely new failure mode is specific: a downstream project on an old
  `MEMORY-WRITING.md` that picks up an updated `CLAUDE.md` (or vice versa) would get an instruction
  keyed to a spec — or a script — it does not have, and `check-readiness.sh` checks only presence.
  **The acceptance condition is therefore not "know the affected count".** It is two properties, both
  required:
  1. Any instruction to run `scripts/lint-memory.sh` **degrades to `not applicable` when the script
     is absent.** A downstream project scaffolded from an older pack copy must not be blocked by a
     check it cannot run.
  2. **`lint-memory.sh` must never fail a corpus written to the old spec** on any rule the old spec
     did not impose.

  Shipping a spec change with unknown blast radius is acceptable here *only* because the failure mode
  is drift rather than breakage — and that is true only if both properties hold. BAR-014 covers the
  first; the second is the reason call 6 constrains the script's failure conditions.
- **Reversibility, restated honestly.** It improves under normalization-only: there are no 45
  descriptions to lose on revert, and no deleted keys to restore. What stays effectively
  irreversible is the **spec change** for downstream projects already scaffolded — a `git revert`
  here does not reach them. That is the same drift class as the bullet above, not a separate risk,
  and it is why the degradation property is an acceptance condition rather than a nice-to-have.
- **Sequencing is not optional.** The spec (step 1) must land before the migration (step 3), and the
  migration before the lint runs in anger (step 4) — a lint written against three dialects needs
  three regexes, which is pattern fragility of exactly the kind `tech-lead`'s bar-soundness row 5
  describes. The script itself may be *written* before the migration; it must not be *enforced*
  before it.
- **The two grep hazards on this machine are the script's dominant implementation risk.** Both are
  documented in active memory files (see `## Inputs`) and both have already bitten this repo:
  `grep -iF` aborts on this host, and `pipefail` plus a short-circuiting grep returns 141. A new
  grep-based lint written without reading those two files is likely to reproduce a failure this repo
  has had twice, and to reproduce it in the specific form that **prints a pass while failing**.
- **The `obsidian-*.js` hooks are status-blind and need no change** — `obsidian-memory-hook.js`
  filters on path, and `obsidian-stop-hook.js` mirrors the tree wholesale. Verified. A secondary
  benefit of choosing real YAML: Obsidian renders it as queryable properties, which bold-key
  pseudo-frontmatter is invisible to. Given five Obsidian hooks in this pack, forfeiting that
  permanently would be the cost of the lower-churn alternative.
- **Rejected alternative — keep the bold-key dialect and fix the pattern instead** (39 of 52 files
  already conform, and the spec already mandates it, so only 13 files would migrate). Rejected on
  two grounds: it is not YAML, so no parser can read it and Obsidian cannot index it; and it would
  require editing the filter text in all **19** consumer files, which lowercase leaves alone.
  **One correction to how this comparison was originally made:** it weighed "20 consumer files"
  against "13 files migrate" while omitting the 45 `description:` lines — which belonged to the
  **index**, not to the dialect. The two options were not compared at equal scope, which overstated
  the rejected option's relative cost. At equal scope, and with the index gone, the comparison is
  13 file migrations plus 19 consumer edits versus 52 file migrations and zero consumer edits. The
  rejection still holds, now on the YAML-parseability ground doing most of the work rather than the
  file count.

## Out of scope

- **`memory/INDEX.md` and everything downstream of it** — the bijection, gate 2d, the 45
  `description:` lines, and the 25 read-site edits it would need. Deferred with a stated return
  condition, not refuted; see `## What does not ship`.
- Relocating or retiring the `*challenge-*` files. Evidence-gathering only in this cut.
- Merging the az/ADO, PowerShell or Obsidian clusters.
- Any deletion from `memory/`, and any addition to it by this migration.
- **Closing the `status:` vocabulary at three values**, and the `known-issues/` misfiling that a
  `resolved` file in that directory represents. Both belong to the same follow-on cut.
- **Closing the `type:` vocabulary.** Seven values exist; two of them (`context`, `platform quirk`)
  would have to be rewritten to close it at five, and that is a change to a fact.
- **Splitting `2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md`** into its
  resolved-bug half and its live-constraint half. Correct on the merits; BAR-012 fires on it.
- Migrating downstream projects' memory corpora.
- Token-cost measurement. No telemetry exists in this pack, so any before/after figure would be
  unfalsifiable, and no bar in this plan claims one.
- Changes to `/repo-map`, `agents/merge-reviewer.md` (any gate), or `repo-map.md`'s content beyond
  its dialect migration.

---

## Inputs

Read before acting; filter `memory/**/*.md` by status.

- `docs/MEMORY-WRITING.md` — the dialect spec, the singleton carve-out (line 13), the
  status-mutation rule (line 45), and the `known-issues/` definition (line 22).
- `CLAUDE.md` — Memory section, precedence rules, the script-gate pattern in "Always invoke after
  implementation", and the **Engineer write permission** section, which instructs the *losing*
  dialect (`type:`/`status:`/`discovered:`) and is the genuine contradiction with
  `MEMORY-WRITING.md`. Note it **mandates `discovered:`**, which is why call 2 exists.
- `skills/memory-audit/SKILL.md` — **step 1 item 4 at lines 21-22 specifically**, which instructs
  writing `**Status:** archived` / `**Status:** superseded` / `**Superseded-by:**`. Verified. This is
  the site build step 5 must edit.
- `skills/memory-query/SKILL.md` — step 2, and its `description` at line 3, which contains "memory
  hygiene" as an **anti**-trigger.
- `skills/repo-map/SKILL.md`.
- **`memory/context/2026-08-04-grep-iF-aborts-on-this-machine.md`** — active. `grep -iF` aborts on
  this host.
- **`memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md`** — active.
  `pipefail` plus a short-circuiting grep returns 141.

  These two were omitted from the original plan and are the **most constraining inputs for writing
  this script on this machine**. Both are about grep-based shell checkers on this exact host, and
  together they are the reason `scripts/lint-identifiers.sh` treats **exit ≥ 2 as an error** rather
  than as "no matches". A grep-based lint written without them is likely to reproduce a failure this
  repo has already had twice — in the form that prints a pass while aborting.
- `scripts/lint-plans.sh` — the self-test pattern, the herestring-not-pipe rule, the
  exit-2-is-not-a-pass contract to copy, **and the precedent for a blocking script the coordinating
  session owns rather than merge-reviewer** (call 7).
- `scripts/lint-identifiers.sh` — the three-way exit contract and the self-test-before-scanning
  pattern. `scripts/check-readiness.sh`, `scripts/setup-project.sh`.
- `agents/merge-reviewer.md` gates 2a/2b/2c — read as the mould **and as the contrast**: this cut
  adds no gate, so those three are what its enforcement is deliberately weaker than.
- `memory/architecture/repo-map.md` — the singleton model, and **a file in the migration set**
  (call 10). Nine bold keys today, including `last-updated` and `verified-at-commit`, and no fence.

**Corpus facts, re-verified 2026-09-02 — and stated as relations, not totals.** The absolute count is
**already stale by construction**: the audit that reviewed this plan was *required* to write a memory
file, which took the corpus from 51 to **52** before any build step runs, and engineers may add more
mid-pipeline. Every count below is therefore a snapshot for sizing only. **No bar in this plan keys
on an absolute total** — see BAR-012, which asserts *no file added or removed by the migration*
rather than a number.

Snapshot at 52 files. Dialects: **39** bold-key (no `---` fence at all), **7** flat lowercase YAML,
**6** nested under `metadata:` with `name`/`description`. Every file has exactly one frontmatter
status line, so none lacks one. Statuses: **44** active, **5** archived, **2** superseded, **1**
`resolved` — 8 non-active. `type:` values: **7 distinct** — `decision`, `finding`, `constraint`,
`pattern`, `known-issue`, `context`, `platform quirk`. `description:` exists in **6** files, all six
nested-dialect; `name:` in the same 6.

**One legitimate irregularity to preserve, not fix.**
`2026-07-30-step-5b-passes-on-uncommitted-worktree.md` carries
`**Superseded-by:** fixed in place 2026-07-30; see Revisit trigger` — prose, not a filename. It is
legitimate under today's spec. `lint-memory.sh` therefore checks that `superseded-by` is **present**,
never that it **resolves** to a file; rewriting that value would change a fact. See the responsibility
matrix, from which the resolution claim has been removed.

## Build steps

### Responsibility matrix

Written before file selection, per `tech-lead`'s rule, because this design assigns duties across
several agents and stages. Each block is one lifecycle transition.

```
Event: a memory file is written mid-pipeline (engineer, tech-lead, or devils-advocate)
Writer:            the authoring agent          Reader:            next session's consumers
Mutator:           n/a — the file is new        Verifier:          lint-memory.sh, dialect only
Failure behavior:  coordinating session's       Persisted state:   the file
                   lint run FAILs the changeset
```
**Note what is no longer here: the row-append duty.** With the index gone, a writer's only duty is to
write its own file in the correct dialect. This also removes a conflict the original design carried —
engineers run under `isolation: "worktree"` and `CLAUDE.md` forbids them writing the plan file for
exactly the reason a shared `INDEX.md` would have failed: one file every stage depends on, appended
to concurrently, in worktrees that may be based off stale `main`.

```
Event: a memory file's status changes to archived or superseded
Writer:            /memory-audit step 1 item 4  Reader:            the 19 files' skip filter
Mutator:           /memory-audit rewrites the   Verifier:          /memory-audit step 4 runs
                   file's own frontmatter                          lint-memory.sh on its output
Failure behavior:  step 4 FAILs the audit run   Persisted state:   file frontmatter
```
**This block is why build step 5 is mandatory rather than optional.** `/memory-audit` step 1 item 4
currently instructs writing `**Status:** archived` — the dialect this cut abolishes. If it is left
alone, **the hygiene skill becomes the thing that breaks the dialect**, on every future run. Verified
at `skills/memory-audit/SKILL.md` lines 21-22.

```
Event: superseded-by is populated with prose rather than a filename
Writer:            /memory-audit or a human     Reader:            a human following the pointer
Mutator:           n/a                          Verifier:          lint-memory.sh checks PRESENCE
                                                                   only, never resolution
Failure behavior:  none — this is legal         Persisted state:   file frontmatter
```
**The resolution check has been removed from this design.** It would have failed the corpus on day
one: `2026-07-30-step-5b-passes-on-uncommitted-worktree.md` carries a prose value that is legitimate
under today's spec, and rewriting it would change a fact. Presence is covered by BAR-001, since
`superseded-by` is one of the seven required keys; **no separate bar is warranted.**

```
Event: a fresh project is scaffolded
Writer:            setup-project.sh             Reader:            the first lint run in that repo
Mutator:           n/a — no stub needed         Verifier:          lint-memory.sh empty-corpus pass
Failure behavior:  a new project cannot pass    Persisted state:   memory/ dirs + .gitkeep only
                   its own lint if this breaks
```

```
Event: nobody runs lint-memory.sh
Writer:            n/a                          Reader:            n/a
Mutator:           n/a                          Verifier:          NONE — no agent re-runs it
Failure behavior:  silent; the script's         Persisted state:   none
                   existence reads as coverage
```
**This is the design's one unowned duty, and it is named rather than discovered.** Gates 2a/2b/2c are
re-executed by merge-reviewer, which holds `Bash`; this script has no such backstop because no gate
ships. The controls are two textual instructions (call 7) and BAR-014, which can prove only that they
are written. **This is the same shape as the `obsidian-stop-hook.test.js` failure** — 131 tests no
pipeline invoked until 2026-08-03. Flagged as the plan's top open question, not solved.

**Owner-to-file reconciliation.** Every duty owner above maps to a file this plan edits:
`docs/MEMORY-WRITING.md` (the dialect duty on all writers), `CLAUDE.md` (Engineer write permission,
plus the two invocation-list entries), `skills/memory-audit/SKILL.md` (step 1 item 4 and new step 4),
`skills/memory-query/SKILL.md` (step 2 read path), `scripts/lint-memory.sh` (all verification),
`scripts/check-readiness.sh` (presence check), and the corpus itself (step 3). **`setup-project.sh`
is deliberately NOT edited** — with no stub to write, its existing behaviour already satisfies the
scaffold block, and the empty-corpus pass is a property of the script rather than of the scaffold.
The only duty with no owning file is the last block, and that is stated as unowned rather than
assigned to a file that would not discharge it.

### Steps

1. **Decide and document the dialect.** Rewrite `docs/MEMORY-WRITING.md`: the fenced lowercase YAML
   block with **seven required keys**, the explicit statement that **extra keys are permitted** plus
   the four sanctioned extras enumerated, `status:` documented at **four** accepted values, `type:`
   documented as **seven observed values with the vocabulary open**, `description:` marked
   **optional**, and the explicit statement that immutability protects **facts, not syntax**. Leave
   the singleton clause naming `repo-map.md` alone. Sequential; everything depends on it.
2. **Resolve the `CLAUDE.md` contradiction in lockstep.** The Engineer write permission section
   adopts the same key set and dialect, and keeps mandating `discovered:` — now sanctioned as an
   extra rather than contradicted. Add `scripts/lint-memory.sh` to "Always invoke after
   implementation" (trigger: any changeset touching `memory/`) and its counterpart to "Never invoke
   automatically", following the wording pattern of the three existing script gates **and stating
   that no merge-reviewer gate enforces it.** Must not lag step 1.
3. **Migrate every file under `memory/` to the new dialect.** Frontmatter only; no body edits; no
   file added or removed. **Preserve every value byte-for-byte**, including the four extra keys and
   `status: resolved`. `repo-map.md` is in the set (call 10). Gated — see BAR-013.
4. **Write `scripts/lint-memory.sh`.** Dialect conformance only. Self-test **before** scanning, exit
   `2` if any self-test rule fails to fire on a violating fixture or fires on a compliant one.
   Herestrings, not pipes. **Treat grep exit ≥ 2 as an error, not as "no matches"** — both `## Inputs`
   memory files exist because this repo has already shipped that bug. Must **not** fail on an
   unrecognised key, must pass on an empty corpus, and must not check that `superseded-by` resolves.
5. **Fix the two skills.** `/memory-audit`: correct **step 1 item 4** to write the new dialect
   (`status: archived`, `status: superseded`, `superseded-by:`) and add **step 4**, which runs
   `scripts/lint-memory.sh` at the end of the pass. **This supersedes the original plan's "leave
   steps 1–3 alone" instruction, which contradicted BAR-010 — build step 5 wins, and step 1 item 4
   is edited.** Steps 1a, 2 and 3 remain untouched. `/memory-query`: rewrite **step 2** to triage on
   the **filename**, consulting `description:` only where present, and naming `name:` nowhere.
6. **Add the presence check** for `scripts/lint-memory.sh` to `scripts/check-readiness.sh`, and make
   any instruction to run it degrade to `not applicable` when the script is absent (Risks,
   acceptance condition 1).
7. **Run the gated scripts**: `scripts/lint-agents.sh` (the changeset touches `skills/`),
   `scripts/lint-identifiers.sh` (every changeset), the new `scripts/lint-memory.sh`, and
   `scripts/lint-plans.sh` on this plan. `node scripts/obsidian-stop-hook.test.js` is **not**
   triggered — the changeset touches neither `obsidian-stop-hook.js` nor `obsidian-context-hook.js`,
   and that skip is stated out loud rather than left ambiguous with a skip-because-clean.

## Acceptance bars

- BAR-001: every file under `memory/` — **`memory/architecture/repo-map.md` included, with no exceptions** — opens with a `---` fence on line 1, closes it, and carries all **seven** required keys (`date`, `type`, `status`, `superseded-by`, `scope`, `overrides-convention`, `related-to`); and **a file carrying keys beyond the seven passes**
  Evidence: tests -> `scripts/lint-memory.sh` exits 0 across the corpus. **Non-vacuity is proved by a self-test fixture, not by a corpus file count** — the script must exit 2 when a fixture that should fail is accepted, and must **pass on an empty corpus**, because the scaffold responsibility-matrix block requires a freshly scaffolded project (zero `.md` files under `memory/`, only `.gitkeep`s) to pass its own first lint run. An earlier form of this line required exit 2 on a discovery failure, which contradicted that outright: no new project could ever pass. **Three scope questions the earlier form left open are now closed and each is a distinct falsifier.** (1) `repo-map.md` is **in** the set (call 10) — nine bold keys and no fence today, so a migration that skips it fails this bar. (2) `description:` is **not** among the seven (call 3), so a file lacking it passes. (3) **Extras are permitted (call 2), and this bar tests that positively rather than by silence:** a self-test fixture carrying `discovered:`, `resolved:`, `last-updated:` and `verified-at-commit:` alongside the seven **must be accepted**. Without that fixture the bar would pass on a migration that deleted four dated facts from a change advertised as lossless — the exact defect the closed-schema reading would have produced. `superseded-by`'s presence is covered here and needs no bar of its own; **its resolution to a real filename is deliberately not checked** (see the third matrix block)
- BAR-002: `status:` holds only a value documented in `docs/MEMORY-WRITING.md`, in every file under `memory/` — where the documented set is **four** values: `active`, `superseded`, `archived`, `resolved`
  Evidence: tests -> three parts, all required. (a) A `lint-memory.sh` self-test fixture carrying an **undocumented** status value (e.g. `status: pending`) must be **rejected**, proving the check fires rather than matching nothing. (b) A fixture carrying **`status: resolved` must be ACCEPTED.** (c) The **corpus run** must exit 0 on the status rule specifically — an earlier form named only the fixture, so it proved the checker works and said nothing about the corpus, leaning on BAR-001's corpus exit-0, which checks a different rule (fence + keys). **The polarity is now settled and (b) is the whole point of settling it:** the original call reclassified the one `resolved` file to `archived` and this bar's fixture had to *reject* `resolved`. Call 5 drops that, so the fixture inverts — and stating it as an explicit *accept* is what stops a later implementer restoring the reclassification and still passing. `2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md` keeps its value; only its dialect migrates. **What this bar does NOT cover, stated plainly: the `type:` value vocabulary.** Call 4 leaves it open because the corpus holds seven values and closing it at five would require rewriting two files' `type:`, which is changing a fact. `type:`'s *presence* is covered by BAR-001; **its value is deliberately unenforced in this cut, and no bar here claims otherwise** — a migration that invented an eighth type value would pass every bar in this plan, and that is a known, accepted gap rather than an oversight
- BAR-003: **every** file whose status is `archived` or `superseded` is matchable by the lowercase literal the pack's agent and skill instructions document — universally quantified, with no expected count
  Evidence: tests -> `lint-memory.sh` reports **zero** files whose status is `archived` or `superseded` and which fail to match `^status: (archived|superseded)$`, **and** reports the count it examined as non-zero. **The expected total is deliberately not stated.** An earlier form hard-coded **8**, which is bar-soundness row 5: `/memory-audit` step 1 archives and supersedes files as its normal function, so the first hygiene run after this ships makes a correct corpus fail a bar that names a fixed number. **`resolved` files are outside this bar's scope by construction, not by exception** — the bar is universally quantified over `archived`/`superseded` only, so call 5's decision to leave one `resolved` value standing cannot affect its verdict, and the bar therefore has **no dependency on call 5** in either direction. That independence is the point: verified 2026-09-02, the corpus's 8 non-active files split into **7 unmatchable because of their dialect** (bold `**Status:**`) and **1 unmatchable because of its value** (`2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md`, a nested-YAML file carrying `  status: resolved`). Those are two different defects; **this bar fixes only the first, and the second is left unfixed on purpose.** So the property proved is: after this cut, **every** `archived`/`superseded` file is matchable, and the `resolved` file stays deliberately readable by every agent. An anchored match is a sufficient condition for the unanchored literal the **19** instruction-bearing consumer files actually document, so proving the anchored form proves theirs. This proves the string is matchable, **not** that any agent skips the file — agent read behaviour is not checkable and no bar here claims it
- BAR-010: no instruction anywhere in the pack still tells a memory writer to use the bold-key or bare-lowercase form
  Evidence: files -> the **enumerated** write sites, not a category. All three verified to exist today: (1) `CLAUDE.md` Engineer write permission section (`type:`/`status:`/`discovered:` in the bare-lowercase form); (2) `docs/MEMORY-WRITING.md` "Required frontmatter fields" block, lines 28-36, bold-key; (3) **`skills/memory-audit/SKILL.md` step 1 item 4, lines 21-22, which instructs writing `**Status:** archived`, `**Status:** superseded` and `**Superseded-by:**`** — re-verified 2026-09-02. **The contradiction this bar exposed is now resolved in the bar's favour, and the resolution is recorded here because it changed the build:** the original build step said to leave `/memory-audit` steps 1-3 alone, which would have failed this bar as specified. **Build step 5 now edits step 1 item 4, and build step 5 wins.** That reconciliation is load-bearing rather than tidy: if step 1 item 4 were genuinely left alone, **every future `/memory-audit` run would write the abolished dialect**, making the hygiene skill the thing that breaks the dialect — and with no merge-reviewer gate shipping, nothing would catch it except that same skill's own new step 4. **The escape clause is removed:** an earlier form said to search "for `**Status:**` and `discovered:` as instructions rather than as historical description", which lets the checker reclassify any hit as historical and enforce nothing (bar-soundness row 5, second half). The allowlist is instead explicit and closed — **quoted history is permitted only in this plan's `## Challenge` and `## Revision` sections, in `docs/plans/*.md` generally, and inside memory files' own bodies; every other hit is a finding.** Two scope notes: `discovered:` is named here as a **dialect** target only — call 2 sanctions the key itself and `CLAUDE.md` must keep mandating it, so the fix is the form (`discovered:` stays, bare-lowercase-without-fence goes), not the key; and this bar is a presence check on prose, which is the honest ceiling for instruction files
- BAR-011: `skills/memory-query/SKILL.md` step 2 names `name:` nowhere, and names **no frontmatter field as a required triage input** — because after this cut no frontmatter field carrying a summary exists in every memory file
  Evidence: files -> step 2 must triage on the **filename** (a path fact, not a frontmatter field — an earlier wording listed it as one, which would have made the bar assert something false) and may consult `description:` **only as an optional enrichment, explicitly qualified as present in a minority of files.** Verified 2026-09-02: `name:` exists in exactly 6 files, all six nested-`metadata:` dialect, reaching **0** after migration; `description:` exists in those same 6 and **stays at 6**. **The coupling this bar carried is now resolved, in the opposite direction from the one anticipated.** The earlier form read "this bar fails if `description:` does not become universal", on the reasoning that `description:` was required in order to serve the index row. The index is gone and call 3 makes `description:` optional, so the falsifier inverts: **this bar now fails if step 2 instructs triage on `description:` as though every file had one.** Named falsifiers, so the bar can fail: any unqualified "read the `description` field", any reference to `name:`, or any wording that makes a minority-present field the primary triage key
- BAR-012: the migration **added no file and removed no file** under `memory/`, and **altered no body text** — every change is confined to the frontmatter region
  Evidence: manual -> `git diff` on `memory/` reviewed **at hunk level**, with every hunk shown to fall inside the frontmatter region (above the closing `---`, or above the first blank line in an unfenced file), plus `git diff --name-status` on `memory/` showing **zero `A` and zero `D`** — every entry `M`. **`git diff --stat` alone cannot prove this and an earlier wording named only `--stat`** — it reports per-file line counts in which a body edit and a frontmatter edit are indistinguishable, so the one view specified was the view in which scope creep is invisible (bar-soundness row 1: it checks that a change is *present*, not that it is *confined*). **The bar is stated as a relation and names no total, deliberately.** An earlier form read "51 files before, 51 after" — already stale when written, because the audit that reviewed this plan was *required* to write a memory file, taking the corpus to 52 before any build step ran, and engineers may add more mid-pipeline. **A count cannot be made correct here, only relative**, so the property is *no net change to the file set by this migration*, which stays true at any corpus size and under concurrent additions by other stages. **State what a null result means:** an empty diff means the migration did not run, not that it ran cleanly, so a zero-change result **fails** this bar rather than passing it. **This bar is also the tripwire that classifies the file-split as a separate cut** — splitting `2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md` alters body text and adds a file, so it produces an `A` and fails here by design. That is the bar working, not an obstacle to route around
- BAR-013: the corpus-wide frontmatter migration is authorized by the operator before it runs
  Evidence: manual -> operator confirms after being shown the full file list and the worked before/after examples named in `Gated:` below
  Gated: the operator has seen **every file the migration will touch, enumerated** — not a count — and **three** worked before/after examples, one per dialect (bold-key, flat-lowercase, nested-`metadata:`), with the **nested-`metadata:` example mandatory**, and has confirmed. One example is not enough, and the reason the nested one is mandatory has **inverted** since this bar was first written. It was mandatory to *reveal* the `discovered:` / `resolved:` keys being **deleted** under a closed eight-key schema. Call 2 now permits extras, so it is mandatory to *demonstrate* those keys **surviving** — it is the only one of the three examples in which `discovered:`, `resolved:` and a preserved `status: resolved` all appear, and therefore the only one that lets the operator check the losslessness claim rather than take it. An operator shown only a bold-key sample sees a pure syntax change and learns nothing about the interesting case either way
  Cost: frontmatter reformatted in **every `*.md` file under `memory/`** in one commit — 52 files at the 2026-09-02 snapshot, `repo-map.md` included, and **stated as a relation because the total is already stale by construction** (the audit's own required memory write moved it from 51 to 52 before any build step ran, and engineers may add more mid-pipeline). **What this commit does NOT do, all four verified against the revised calls: it authors zero `description:` lines** (was 45 — the index is gone, call 3); **it deletes zero keys** — `discovered:` (6 files), `resolved:` (1), `last-updated:` and `verified-at-commit:` (`repo-map.md`) all survive untouched under call 2; **it changes zero values**, including the one `status: resolved` (call 5); and **it adds and removes no file** (BAR-012 checks this at hunk level). So the cost is a pure syntax transformation with no judgement in it. **Reversibility, stated correctly this time.** The prior wording read "`memory/` is committed and this branch is not merged to `main` by any agent" — but this plan's frontmatter reads `branch: main`, so the work lands **on `main`** and there is no unmerged feature branch to discard. **So the remedy is a revert commit on `main`, unless the work is moved to a feature branch first — and which of those applies is not yet decided, so the operator must be told which at confirmation time rather than at plan time.** A second pass caught the correction over-correcting: `CLAUDE.md` requires **git-engineer** to run before any engineer agent and, when the branch is `main`, to *ask* whether to create a new one — and merge-reviewer commits to a feature branch and never merges to `main`. So a feature branch is the pack's normal path and revert-on-`main` is the exception, which is the reverse of what the first correction implied. **Do not state either as settled here.** The `branch:` field records the branch at plan time, not the branch the migration will land on; whoever presents this gate must read the actual branch at that moment and state the matching remedy — discard the branch, or revert on `main`. This whole line is bar-soundness row 6 twice over, in its exact BAR-015 shape and in **both** directions the table warns about: the original understated the cost (claiming a quarantine that did not exist), the first correction overstated it (claiming a revert-only remedy that the pipeline probably avoids), and in both cases the evidence was sound and the bar would have passed while the sentence the human approved was untrue. **Two real costs remain, and neither is reversed by `git revert`.** (a) The migration makes the documented skip filter work **for the first time**, which **removes the 7 `archived`/`superseded` files from every agent's read set** — the intended effect, but a change to what agents see, and nothing in this plan checks whether any of the 7 is still load-bearing. The one file where that question was live keeps `status: resolved` and stays readable. (b) `docs/MEMORY-WRITING.md` is copied into other projects by `scripts/setup-project.sh` and never updated, so the **spec change reaches downstream projects a revert on this repo cannot reach.** That is drift rather than breakage only if the two degradation properties in `## Risks` hold; BAR-014 covers the first of them
- BAR-014: `scripts/lint-memory.sh` is instructed at **all three** of the sites enumerated below, and **every one of those instructions that could run in a repository lacking the script degrades to `not applicable` when it is absent**
  Evidence: files -> three enumerated sites, all three required: (1) the `CLAUDE.md` entry under "Always invoke after implementation", triggered on a changeset touching `memory/`; (2) its counterpart under "Never invoke automatically"; (3) `skills/memory-audit/SKILL.md` step 4. Plus a presence line in `scripts/check-readiness.sh`. **Two corrections from the post-revision audit, both making this bar able to fail where it previously could not.** (a) The subject read "**at least one** instructed invoker" while this evidence line requires all three — so the subject would have passed with sites (2) and (3) missing, and the weaker of two disagreeing statements is the one an implementer follows. The subject now matches the evidence. (b) The degradation half said "every instruction … degrades" while naming the property only at site (1) — bar-soundness row 2, a category asserted against a single instance. **Site (3) needs it just as much and is the likelier failure:** `/memory-audit` is installed globally and will run in projects that have `memory/` but no `scripts/lint-memory.sh`, so an unconditional step 4 makes the hygiene skill fail in every such project. State the absent-script behaviour at **both** (1) and (3); site (2) is a negative instruction and needs no degradation clause. **This bar exists because gate 2d was dropped and the script would otherwise ship with no invoker at all** — the precise failure this pack already had with `scripts/obsidian-stop-hook.test.js`, whose 131 tests no pipeline invoked until 2026-08-03, several of them regressions for bugs already fixed once. **A linter nothing runs is worse than no linter, because its existence reads as coverage**, so "the script was written" must not be mistakable for "the check happens". **The degradation half is separately falsifiable:** site (1) must state the absent-script behaviour in words, and the falsifier is any unconditional wording — a downstream project scaffolded from an older pack copy would otherwise be blocked by a check it cannot run (`## Risks`, acceptance condition 1). **Two limits stated rather than implied.** First, this is a presence check on prose and cannot be more (bar-soundness row 1): it proves the instruction is written, never that any session obeys it. Second, and more important — **unlike gates 2a/2b/2c, no agent re-runs this script.** merge-reviewer holds `Bash` and re-executes those three, so a session that skipped one cannot pass it off as run; nothing plays that role here. This bar therefore establishes the weakest of the three enforcement strengths available, and **it does not close the plan's top open question — it documents it.** Reinstating a merge-reviewer gate is the only thing that would, and that was deferred with the index

## Challenge

Audited 2026-09-02 by `devils-advocate`. Scope classification: **architectural / irreversible-in-practice**
— it changes a spec that is copied into other repositories, adds a permanently blocking gate, and
rewrites frontmatter in all 51 files of the corpus every other stage reads. Maximum scrutiny applied.
All corpus figures below were re-derived independently rather than taken from the plan or the dispatch.

### Restatement

Ship a complete, unranked `memory/INDEX.md` (one row per memory file: path, type, status, scope, date,
description); normalize all 51 memory files from three frontmatter dialects to one fenced lowercase
YAML dialect with eight required keys; add `scripts/lint-memory.sh` asserting a file-to-row bijection
plus dialect conformance; add a blocking merge-reviewer gate `2d` triggered on `memory/`; and edit five
consumer files in lockstep. Ship **no** consolidation — a deliberate reversal of the request. My
reading matches the stated intent, with one gap worth naming as a finding in itself: the plan is
presented as one change with a severable normalization half, but the **read path** — the reason the
index exists — is neither implemented nor barred anywhere in it. See C1.

### Concerns, ranked

**C1. The index has no instructed reader, and no bar notices.** `Glob("memory/**/*.md")` is named in
**29 files**, of which **25 are instruction-bearing** — ids listed rather than summed, so a reader can
recount: 15 `agents/*.md` (api-designer, backlog-auditor, code-reviewer, csharp-engineer,
database-engineer, devils-advocate, frontend-engineer, infrastructure-engineer, mcp-engineer,
performance-reviewer, python-engineer, security-reviewer, smell-reviewer, tech-lead, test-engineer);
7 `skills/*/SKILL.md` (conventions, debug, memory-audit, memory-query, onboard, refactor, scaffold);
and `CLAUDE.md`, `README.md`, `docs/AGENT-GUIDE.md`. The remaining 4 hits are descriptive, not
instructions: 2 memory files and 2 plans (including this one). The plan edits **3** of the 25
(`CLAUDE.md`, `skills/memory-audit`, `skills/memory-query`), leaving **22 instruction-bearing files
that keep their own local copy of the glob instruction and are never told `INDEX.md` exists.**

*(Correction, same audit: an earlier draft of this paragraph said "25 of them `agents/*.md` … and
eight `skills/*/SKILL.md`". Both were mis-transcribed from the grep. The 29 total and the conclusion
are unchanged; the breakdown above is the derived one. Recorded rather than silently fixed, because
this plan's `## Risks` contains two count errors of exactly this kind — C3 and C16a — and the auditor
producing one in the same pass is the relevant data point.)* This pack's own doctrine — a duplicated
instruction in a second file is what the agent actually obeys — predicts they will keep globbing.

So as scoped, the plan ships: a new artifact, a bijection lint, and a blocking gate — all on the
**write** side of a read path nobody is directed to use. That is the direct answer to the question
`tech-lead` declined to bar. The index's marginal value over a free glob is not *small* here; for 25
of 29 consumers it is **zero by construction**, because they will not open the file. Two honest exits:
(a) add an explicit consumer-edit step covering all 29 sites, which roughly triples the changeset and
puts it into every agent file — a much larger and more visible blast radius than the plan currently
presents; or (b) drop the index. **This should be resolved before any other question in this plan.**

**C2. BAR-013's consent gate rests on a false reversibility premise (bar-soundness row 6).** The
`Cost:` line told the operator "this branch is not merged to `main` by any agent". The plan's own
frontmatter reads `branch: main` — the work lands **on** `main`. The operator would have been asked to
authorize a 51-file rewrite under a description of reversibility that the plan's own header
contradicts. This is the same failure shape as BAR-015: evidence sound, bar passes, and the sentence
the human approved is untrue. Edited in place.

**C3. The corpus count in `## Risks` is wrong, and the two causes of unmatchability are conflated.**
Verified: non-active files are **8** — 5 `archived`, 2 `superseded`, 1 `resolved`. `## Risks` says
"All 7 non-active files use the bold `**Status:**` dialect, so 0 of 7 are matchable". Both halves are
wrong about the eighth file, and wrongly in a way that matters:
`2026-07-29-install-sh-silently-skips-obsidian-block-noninteractive.md` is a **nested-YAML** file
carrying `  status: resolved` at indentation. Its unmatchability is caused by the **value**
(`resolved` is not in the documented pattern) and not by the dialect. So the plan's decisive argument
— "the dialect makes non-active files unmatchable" — is true of **7 files, not 8**, and BAR-003's "8"
silently merges a dialect defect with a vocabulary defect. The argument survives at 7; the count does
not. This is the third read-back defect the dispatch asked me to look for.

**C4. BAR-001's non-vacuity clause contradicts call 12 and the scaffold matrix block.** Call 12 and
the fifth responsibility-matrix block require `lint-memory.sh` to **pass** when `memory/` holds zero
`.md` files (a freshly scaffolded project). BAR-001's evidence requires that "a discovery failure
yields exit 2". Both cannot hold: a fresh project has zero corpus files by definition, and
`setup-project.sh` writes only `.gitkeep` files plus a stub `INDEX.md` that call 6 excludes from the
bijection by exact path. As written, either every new project fails gate 2d, or the bar is unsatisfiable.
Non-vacuity belongs in a **self-test fixture**, not in a count of the live corpus. Edited in place.

**C5. A verifier named in the responsibility matrix fails on existing correct data, and no bar covers
it.** The second matrix block says `lint-memory.sh` verifies "`superseded-by` resolves". Verified:
`2026-07-30-step-5b-passes-on-uncommitted-worktree.md` carries
`**Superseded-by:** fixed in place 2026-07-30; see Revisit trigger` — prose, not a resolvable
filename. That is legitimate content under today's spec. So the stated verifier would fail the
corpus on day one. `superseded-by` is covered by **no bar in this plan**, so the conflict would first
surface as a lint failure during step 4, after step 3's 51-file migration has already run. Three ways
out, each with a different cost: drop the resolution check, widen the field's grammar to admit a
prose form, or edit that file's `superseded-by` — which is a change to a **fact**, not to syntax, and
therefore is *not* covered by the plan's "immutability protects facts, not syntax" reading.

**C6. Build step 6 and BAR-010 contradict each other.** Step 6 says "Extend `/memory-audit` … Leave
steps 1–3 alone." But `skills/memory-audit/SKILL.md` step 1 item 4 instructs writing
`**Status:** archived` and `**Status:** superseded` / `**Superseded-by:**` — the **losing** dialect,
in an *instruction to a writer*, which is exactly what BAR-010 forbids. As specified, the work fails
its own bar. Worse than the contradiction: if step 1 is genuinely left alone, then **every future
`/memory-audit` run reintroduces a dialect violation** and trips the new blocking gate 2d — the
hygiene skill becomes the thing that breaks the hygiene gate. Edited BAR-010 to name the site.

**C7. BAR-008 fails on correct work.** Verified: the phrase "memory hygiene" appears in
`skills/memory-query/SKILL.md` line 3 — inside its `description`, as an **anti**-trigger ("Do NOT use
for a full memory hygiene pass — use /memory-audit instead"). A search of `skills/*/SKILL.md`
descriptions for the three phrases therefore returns two files, and a bar reading "exactly one skill
claims the memory-hygiene trigger phrases" fails. Phrasing the fix loosely ("unless the hit is a
disclaimer") would import bar-soundness row 5's self-exemption escape clause, so the edit names the
one legitimate exception by file and clause instead. Edited in place.

**C8. Tier 1 asks engineers to write a shared singleton mid-pipeline, which this pack forbids for the
plan file for exactly the same reason.** `CLAUDE.md`'s plan spine states: "Engineers never write the
plan file. They run under `isolation: "worktree"` and would conflict on the one file every stage
depends on." `memory/INDEX.md` becomes precisely that — one file every stage depends on, appended to
by any agent that writes a memory file. Compounding it,
`memory/known-issues/2026-07-15-worktree-isolation-bases-off-main.md` records that worktrees base off
`main` unless `worktree.baseRef` is `"head"`, and that the setting is drift-prone by design ("config
can drift between when a check ran and when it matters"). An engineer appending a row inside a
worktree provisioned from stale `main` appends to a stale `INDEX.md`. **The plan's own precedent
argues against tier 1**, and the plan does not engage with it. If tier 1 is unreachable, gate 2d fails
runs for a row nobody was positioned to write — C11.

**C9. Call 5 loses information and silently changes what agents read.** `resolved` is a live
distinction in this corpus, not a stray value:
`2026-07-15-worktree-isolation-bases-off-main.md` carries a section headed "Why this stays
`known-issue` and not `resolved`", and reasons about the difference. `archived` means *this record no
longer applies*; `resolved` means *the defect was fixed and the record is still true*. Collapsing them
discards that. And it has a behavioural consequence the plan does not state: **today that file is read
by every agent** (its value matches no skip pattern); after call 5 it is `archived` and therefore
skipped. More generally, making the skip filter work for the first time **removes 8 files from every
agent's read set**, including two `superseded` plan-spine findings. The plan frames normalization as a
pure bug fix; it is also a content-availability change, and nothing in the plan checks whether any of
the 8 is still load-bearing. A cheaper option exists and is not considered: add `resolved` to the
closed vocabulary as a fourth value and teach the ~29 consumers nothing (they skip only
`superseded`/`archived`, so `resolved` files stay readable, which is the current and arguably correct
behaviour).

**C10. Call 3 relocates the drift class; it does not remove it.** Byte-identity proves the row matches
the file's **claim about itself**. The reader's actual question is whether the file contains what they
need. So drift moves from a location a script can check (row vs. file) to one nothing can (description
vs. reality) — and acquires a blocking gate that makes the whole artifact *look* checked. The plan says
this out loud in `## Risks` and in the fourth matrix block, which is to its credit; my point is
different. This is the **dominant** risk, its owner is `/memory-audit` step 5, and `/memory-audit` is
an on-demand skill nobody is required to run. So the mitigation for the plan's largest exposure has no
trigger. Pairing that with C1 gives the plan's real shape: mechanical enforcement on the half that
does not matter much, and no enforcement or trigger on the half that does.

**C11. Gate 2d's severity is argued on one axis only.** The plan's case (a set comparison is
mechanical, therefore blocking) is sound as far as it goes, but it never prices the failure. Compare
the existing blocking gates: `lint-identifiers.sh` blocks because the failure is publishing a real
identifier to a **public** repo — unrecoverable. A missing index row is a one-line table append,
recoverable in seconds, in a documentation tree, with zero external consequence. Gate 2d as specified
fails a whole pipeline at its final gate for that. It also fires on the memory writes that
`devils-advocate`, `tech-lead`, and engineers are *required* to make at the end of a run — i.e. it is
most likely to fire on agents discharging a mandatory duty, at the worst moment, over a duty C8 argues
they cannot reliably discharge. A proportionate alternative not considered: gate 2d reports the missing
row and the coordinating session appends it, on the model of gate 3b's advisory plus a named repair.

**C12. Two singleton exceptions do not fit call 1's "exact key set", and BAR-001 does not exclude
them.** Verified: `memory/architecture/repo-map.md` carries **nine** bold keys including
`**Last-updated:**` and `**Verified-at-commit:**`, and no fence. `INDEX.md` is specified to carry
`verified-at-commit` and is explicitly **undated**. Call 1 requires "this exact key set … in every
`memory/**/*.md`", including `date`. BAR-001 says "every file under `memory/`". So the spec as written
requires a `date:` on a document whose defining property is that it is undated, and is silent on
whether extra keys are permitted at all. This is call 11's closed-list-of-two question arriving from
the other side: the list is closed, but the two members do not share a schema. Edited BAR-001.

**C13. BAR-012's evidence cannot prove the property it states.** `git diff --stat` reports per-file
line counts; a body edit and a frontmatter edit are indistinguishable in it. The bar's stated purpose
is to fail on scope creep, and `--stat` is precisely the view in which scope creep is invisible.
Edited to name hunk-level evidence and to state what a null result means.

**C14. The distributed-artifact risk is real but misidentified.** `setup-project.sh` copies
`docs/MEMORY-WRITING.md` and never updates it, so downstream projects are **already** drifting; this
change adds an instance rather than creating the class. The genuinely new failure mode is narrower and
worth barring: a downstream project on an old `MEMORY-WRITING.md` that picks up an updated `CLAUDE.md`
(or vice versa) gets a **blocking gate keyed to a spec it does not have**, and `check-readiness.sh`
checks only presence. So the acceptance condition is not "know the affected count" — it is
"gate 2d degrades to `not applicable` when `scripts/lint-memory.sh` is absent, and `lint-memory.sh`
never fails a corpus written to the old spec it cannot see". **No bar covers either.** Shipping a spec
change with unknown blast radius is acceptable here *only* because the failure is drift rather than
breakage — and that is true only if the degradation property holds, which nothing currently checks.

**C15. The plan's `## Inputs` omit the two memory files most relevant to writing this script on this
machine.** `memory/context/2026-08-04-grep-iF-aborts-on-this-machine.md` and
`memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md` are both active, both
about grep-based shell checkers on this exact host, and both are the reason
`scripts/lint-identifiers.sh` treats "exit >= 2" as an error rather than "no matches". A new
grep-based lint written without them is likely to reproduce a failure this repo has already had twice.
Cheap to fix; listed here rather than as a bar edit because it is an input, not a property.

**C16. The `resolved` question, re-audited after operator input.** The operator's instinct is that
`CLAUDE.md` should **add** `resolved` to the skip filter; call 5 instead **eliminates** the value by
rewriting the file to `archived`. Both bury the file. A third route — split the file — was raised and
is the one I judge correct on the merits. Findings, in order of how much they change:

**C16a. A third count error in the same `## Risks` bullet as C3.** It says "20 pack files … instruct
agents to skip". Verified: the literal skip pair matches **20 files**, but **one of them is this plan**.
Instruction-bearing files: **19** — `CLAUDE.md`, `README.md`, `docs/AGENT-GUIDE.md`, 13 `agents/*.md`,
and `skills/memory-audit|memory-query|onboard`. So the one bullet carrying the plan's decisive argument
contains three wrong numbers (7 non-active → 8; "all 7 bold" → 7 bold + 1 nested; 20 files → 19).
The argument survives all three. Its arithmetic does not, and it is the bullet a reader would cite.

**C16b. Migration as specified deletes facts, which answers the coordinator's question in the
negative.** The `resolved: 2026-07-29` key does *not* reliably survive call 5, because call 1 requires
"this exact key set" of eight — `date`, `type`, `status`, `superseded-by`, `scope`,
`overrides-convention`, `related-to`, `description`. Verified extras in the corpus that are **not** in
that set: `discovered:` (6 files), `resolved:` (1 file), `last-updated:` and `verified-at-commit:`
(`repo-map.md`). If "exact" means closed, step 3 silently drops all four — including `discovered:`,
which `CLAUDE.md`'s **Engineer write permission** section explicitly *mandates*. This is C12
generalized, and it is materially worse than C12: a migration advertised as "a lossless format change
… preserves every fact exactly" would delete four dated facts. **Whether extra keys are permitted is
the single most load-bearing unstated detail in the plan**, and no bar covers it.

**C16c. Only one of the three routes leaves the bars intact — and BAR-002 is the dependency the
coordinator asked about.** BAR-002 asserts the vocabulary is closed at exactly three *and* that "the
`resolved` value is gone", with a self-test fixture that must **reject** `status: resolved`:
- *Operator route* (add `resolved` to the filter): inverts BAR-002 — the fixture must now be
  **accepted**. Also requires editing all 19 files from C16a, which is the exact cost the
  lowercase-dialect call was chosen to avoid.
- *Call 5 as written*: BAR-002 stands, and buries live guidance (C9).
- *Split*: BAR-002 stands **unchanged**, vocabulary stays closed at three, zero consumer edits.

**C16d. The split is right on the merits, and it is out of scope for this cut — and the plan already
contains the tripwire that proves it.** Verified the coordinator's reading of the file: it documents
`set -euo pipefail` + bare `read` at EOF aborting a script (a permanent constraint over the seven
`.sh` files in `scripts/`), the `prompt <varname> <text>` / `ASSUME_DEFAULTS` pattern any *new*
prompt must follow, and it names itself the same defect class as two **active** files via
`[[2026-07-27-obsidian-cli-silent-failure-modes]]` and `[[2026-07-10-bash-tool-silent-failure-windows]]`
— so burying it leaves two active files pointing at a skipped third, in a repo with five Obsidian
hooks that render that graph. `status: resolved` genuinely conflates *the bug is not live* (true) with
*the guidance is not live* (false).

But splitting means: body text removed from one file, a new 52nd file created, and the corpus going
51 → 52. **BAR-012 — "51 files before, 51 after, no body text altered", whose stated purpose is "a bar
that can fail on scope creep" — fires on exactly that.** The plan's own anti-scope-creep bar
classifies the split as a different cut. I take that as decisive and **recommend no bars be added for
it**; it wants its own plan, where the constraint-extraction can be done on evidence rather than
folded into a dialect migration.

**C16e. Which leaves the cheapest in-scope answer: drop call 5 rather than choose a route.** Call 5 is
the **only** place this plan changes a fact rather than syntax, and it sits inside a plan whose central
defence is "the invariant has always protected facts, not syntax". That defence does not license call
5 — it licenses everything *except* call 5. Normalizing the file's dialect while leaving
`status: resolved` untouched keeps this cut purely mechanical, edits zero consumer files, keeps the
file readable by every agent (its value matches no skip pattern, which is currently the *correct*
behaviour given C16d), and hands the semantic question to the follow-on cut that can afford it. The
cost is honest and small: the vocabulary is documented as three values plus one recorded exception with
a named successor plan, and BAR-002 must say so rather than presupposing the reclassification. Edited
BAR-002 to expose the dependency instead of hiding it.

**C16f. No route addresses the misfiling, and step 1 is the moment to notice.** `CLAUDE.md:413` and
`docs/MEMORY-WRITING.md:22` both define `memory/known-issues/` as "Bugs, limitations, and workarounds
that **remain unresolved**." A `resolved` file in `known-issues/` is definitionally misfiled by the
pack's own taxonomy, in both copies of it, and no `memory/resolved/` subdirectory exists. Step 1
rewrites `MEMORY-WRITING.md` — including that table — so this cut *will* touch the sentence that makes
the file misfiled, without resolving it.

**C16g. The irony, and an incomplete diagnosis.** The request was to **consolidate**; this is the one
file in the corpus that wants **splitting**. `## What does not ship` presents a closed diagnosis — the
corpus's problems are misfiling and dialects, not redundancy — and that is now demonstrably
incomplete: at least one file is *under*-divided. The conclusion (don't consolidate) is unaffected and
if anything strengthened. But the diagnosis should be stated as open rather than settled, because the
plan uses its closedness to justify deferring consolidation to "after the index exists", and an
incomplete diagnosis is a weaker basis for that deferral than a complete one.

**C17. Every "51 files" in this plan is already stale, and the pack's own rules guarantee it.** This
audit is *required* to write a memory file
(`memory/known-issues/2026-09-02-challenge-memory-index-and-dialect-normalization.md`), which makes the
corpus **52** files before a single implementation step runs. `tech-lead` and `devils-advocate` memory
writes are mandatory at plan time, and engineers may add to `memory/known-issues/` mid-pipeline. So any
bar keyed to an **absolute** corpus count is racing the pack's own duties: BAR-012's "51 files before,
51 after", BAR-007's "all 51 files", and BAR-013's `Cost:` scope all drift between plan time and
implementation time. Note this is the same defect as C3 and C16a arriving from a third direction — and
unlike those, it is not an arithmetic slip but a **structural** one: the number cannot be made correct,
only relative. Restate the counts as relations ("file count unchanged apart from `INDEX.md`"; "one row
per file discovered at run time") rather than as literals. BAR-003 has already been edited this way and
is the model.

### Calls audit — falsifiability at merge-reviewer Tier 3

This plan scores **well** on this axis; almost every call names a lookup-able artifact. Reporting the
exceptions rather than the roll-call.

**Enforceable as written** (each names a file, key, value or path a reviewer can look up): calls 2, 3,
5, 6, 7, 9, 11. Call 8's exit contract (`0` / `1` / `2`) is enforceable by reading the script.

**Ambiguous — sharpen before implementation:**

- **Call 1** hinges on one undefined word. "this **exact** key set required in every `memory/**/*.md`"
  reads as a closed schema, but the corpus carries four extra keys that hold facts and one of them
  (`discovered:`) is mandated by `CLAUDE.md`. Until "exact" is resolved to *closed* or *minimum*, a
  Tier 3 reviewer cannot tell whether a migrated file carrying `discovered:` honours the call or
  violates it — and the two readings differ by four deleted facts (C16b). Sharpen to one of: "these
  eight and no others", or "these eight at minimum; extras permitted and enumerated here".
- **Call 12** states two things with different enforceability. "`setup-project.sh` writes a stub
  `memory/INDEX.md`" is checkable. "`lint-memory.sh` passes when `memory/` holds zero `.md` files" is
  checkable **and contradicted** by BAR-001's original evidence line (C4) — a Tier 3 reviewer reading
  call and bar together gets opposite answers.

**Covered by no bar** — enforceable in principle, unenforced in practice:

- **Call 4** (`type:` vocabulary of five values). BAR-002 closes `status:` and nothing closes `type:`.
  A migration that invents a sixth type value passes every bar in this plan.
- **Call 10's second half** (`/memory-audit` gains step 4 and step 5). BAR-008 checks that no
  `/memory-index` skill exists; nothing checks that the two steps that replace it were written.
  Step 5 is the named owner of the plan's largest residual risk (C10), so its existence being
  unbarred is the more significant of the two.
- **Call 12's stub write**, per the above.
- **The `superseded-by` resolution verifier** named in the second responsibility-matrix block. It is
  not a numbered call and no bar covers it, yet it would fail the corpus on day one (C5).

**Documentation for the human, not an enforceable decision** — state it as such rather than leaving it
ambiguous: the `## What ships` clause "**The index is authoritative for what exists and where. It is
never authoritative for what a file says.** An agent may use it to choose which files to open; it may
not cite a row as a fact." This is the plan's most important instruction and it has **no lookup
target** — it constrains agent reading behaviour, which nothing in this pack can check. The plan's
third responsibility-matrix block already admits this ("Verifier: none — read path is unenforced"),
which is the right call honestly made. It should not be mistaken for a control.

### Alternatives that should be consciously rejected rather than skipped

1. **Normalization only (steps 1–3, no index, no gate 2d).** Fixes the one *verified* defect, adds no
   derived state, adds no blocking gate, and — critically — lets `description:` become optional or be
   dropped, which deletes 45 of the plan's 45 units of judgement work. This is the smallest change
   that fixes the only thing demonstrably broken today.
2. **An index with no `description:` column.** If honesty is unlintable anyway (C10) and descriptions
   are the dominant cost, derive rows from `path | type | status | scope | date` alone — all
   mechanically extractable after normalization, so the index becomes fully generated with zero
   judgement calls. Note what this reveals: those four fields *are* the entire claimed marginal value
   over a glob, so this variant buys the whole stated benefit at a fraction of the cost. It deserves
   an explicit rejection if it is rejected.
3. **Drop call 5 — normalize that file's dialect and leave `status: resolved` standing** (see C9 and
   C16e). Preserves the distinction, leaves the read-set change at 7 files rather than 8, edits zero
   consumer files, and keeps this cut's "facts, not syntax" claim true. Superseded within this audit
   the weaker version of this item, which proposed *adding* `resolved` to the skip filter: C16d shows
   that route buries live guidance, and C16c shows it inverts BAR-002 and costs 19 file edits.
4. **Fix the pattern rather than the corpus** — enforce the bold dialect by lint and edit the ~20
   consumer files' filter text. The plan rejects this in `## Risks` on YAML-parseability and Obsidian
   grounds, and I accept that rejection as consciously made. One flaw in its cost comparison, though:
   it weighs "20 consumer files" against "13 files migrate", omitting the 45 `description:` lines —
   and those belong to the **index**, not to the dialect. The two options were not compared at equal
   scope, which overstates the rejected option's relative cost.

### Severability: is normalization really independent of the index?

Tested, and the answer is **yes, with three couplings, all cheap to cut** — and it gets *cheaper* when
severed, which is the finding:

- Steps 1 and 2 write the tier-1 **row-append duty** into `MEMORY-WRITING.md` and `CLAUDE.md`. Pure
  index prose; omit it.
- BAR-001 and BAR-002 name `lint-memory.sh` as evidence. The script survives severance with its
  dialect half and loses its bijection half. BAR-004 and BAR-005 fall with the index.
- **`description:` is required only to serve the index row** — call 3 says so in as many words ("it is
  the index row's hook"). Without the index there is no reason for it to be mandatory, so severing
  removes the 45 judgement calls the plan names as its largest exposure.

Bars that stand alone: BAR-001, 002, 003, 010, 011, 012, 013 (with the edits below). Bars that fall
with the index: BAR-004, 005, 006, 007, 008, 009.

### Verdict

**On the index, as scoped: I would not ship it, and C1 is the reason.** Not because the marginal value
over a glob is small in principle — `status`, `type` and `scope` are genuinely not in a filename — but
because 25 of 29 consumers are never told to read it, so that marginal value is zero **by
construction** while the cost (45 judgement calls, a permanently blocking gate, a new derived-state
hazard whose mitigation has no trigger) is paid in full. Killing it here is cheap. If the operator
instead closes C1 by editing all 29 consumer sites, the index becomes arguable again — but that is a
materially bigger change than the one presented, and it needs a bar asserting that no consumer file
still instructs a bare glob.

**On normalization: it should ship, and it is genuinely severable.** It fixes a verified defect (7 of 8
non-active files unmatchable by a pattern 19 files document), it costs 51 frontmatter rewrites, and
severed from the index it costs nothing else. C5, C6, C9 and **C16b** must be resolved first — each
would otherwise fail during or after the migration rather than before it, and C16b is the one that
would fail *silently*, by deleting four dated facts from a migration advertised as lossless.

**On `resolved`: neither the operator's route nor call 5 should ship in this cut.** Both bury a file
whose guidance is live (C16d). The split is correct and out of scope — the plan's own BAR-012 fires on
it. The in-scope move is to drop call 5, leave the value standing, and open a follow-on cut for the
split. That denies the operator's stated instinct, and the reason is worth stating plainly: the
instinct treats the file as clutter, and its content is a permanent shell constraint plus a
regression-prevention pattern for a bug this repo has a documented habit of re-shipping.

The decision is the operator's. These are questions, not a veto.
