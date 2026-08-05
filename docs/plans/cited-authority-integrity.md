---
plan_id: cited-authority-integrity
branch: main
origin_skill: /plan
created: 2026-08-05
---

## What ships

Three changes, independently motivated, in one cut. They are ordered by how directly they attack an
observed loss.

**1. The plan file gets a single writer at a time.** This is the fix for what actually happened on
2026-08-05: `tech-lead` and `devils-advocate` both wrote `BAR-008` of
`docs/plans/devops-azure-area-iteration-placement.md`, tech-lead's version won, and three of
devils-advocate's clauses vanished with no signal. Two rules, stated where each actor reads them:

- **After the plan file's first write, every subsequent change to it is an `Edit` against
  freshly-`Read` content — never a `Write` of the whole file.** A whole-file `Write` composed from an
  agent's own context is the mechanism that lost the clauses; the plan text the agent holds in its
  prompt is a snapshot, and by revision time it is stale by one audit.
- **`/plan` may not dispatch a second writer while a first holds the file, and a post-audit revision
  requires re-asking `devils-advocate` to confirm its edits survived** — or an explicit statement that
  no post-audit revision occurred. Today's loss was caught exactly this way, by merge-reviewer asking
  devils-advocate to vouch and getting an honest "I cannot." That recovery was luck; this makes it a
  step.

**2. Cited authorities get machine-checkable anchors and a checker.** The pack's cross-file rule
sharing works by prose pointer ("single authority", "do not restate"), which appears in 18 files. The
pointers themselves are unverified links: nothing notices when a cited heading is renamed, when a
cited file moves, or when a declared shared literal diverges at one of its sites. Ships:

- `docs/rules/authorities.tsv` — a manifest of **ids and locations only, never rule content.** One row
  per cross-file authority: id, class (`prose` or `literal`), defining file, and for `literal` class,
  the full set of files permitted to hold the string.
- `scripts/lint-authorities.sh` — validates the manifest against the tree.
- `<!-- authority: <id> -->` markers at the four definition sites and `<!-- cites: <id> -->` markers at
  each pointer site.
- Gate wiring: `/implement` step 5f and merge-reviewer gate **2d**, blocking on non-zero exit,
  triggered by a changeset touching `agents/`, `skills/`, `scripts/`, or `CLAUDE.md`.
- A correction to `scripts/lint-plans.sh`'s own comment, which today says the `## Deviations` sentinel
  literal lives in three places that "all move together." **It lives in four files and five
  occurrences** — `agents/tech-lead.md:95`, `agents/merge-reviewer.md:419`, `scripts/lint-plans.sh:61`
  and `:100`, and `skills/implement/SKILL.md:182`. The pointer's own count is already stale, in the
  file whose comment warns about staleness. It will cite the manifest instead of a number.

**3. A probe, and only a probe, of the discipline-layer binding mechanism.** Whether an agent
frontmatter `skills:` field binds for a non-plugin agent in `~/.claude/agents/` is unverified. The
probe's verdict is recorded in `memory/context/`. **No discipline skill is created in this cut** — see
`## What does not ship` for why.

Files: `skills/plan/SKILL.md`, `skills/implement/SKILL.md`, `agents/tech-lead.md`,
`agents/devils-advocate.md`, `agents/merge-reviewer.md`, `CLAUDE.md`, `scripts/lint-plans.sh`,
`scripts/lint-authorities.sh` (new), `docs/rules/authorities.tsv` (new),
`memory/architecture/repo-map.md`, plus the memory files listed under `## Calls made for you`.

## What does not ship

**No third component layer.** No `skills/bar-soundness/`, no model-invoked discipline skill, no
`skills:` frontmatter field on any agent, and **no change to `scripts/lint-agents.sh`'s frontmatter
allowlist.** That allowlist rejects `skills:` on an agent today (`AGENT_VALID_FIELDS` at
`scripts/lint-agents.sh:18`), so shipping the field would require widening a check whose purpose is
catching exactly this class of typo — before anyone has confirmed the field does anything. A
frontmatter key that the linter accepts and the harness ignores is worse than the prose pointer it
replaces: it *looks* binding.

**No migration of any of the four duplication instances.** Recommended order for a later cut, and the
reasoning, is in `## Inputs`.

**No rewrite of the 18 prose-pointer files.** Markers are added at the four instances' definition and
citation sites only. Every other pointer stays as prose.

**No paraphrase detection.** The checker finds dangling citations, uncited authorities, and
undeclared occurrences of a declared *literal*. It cannot tell that someone restated the guard table
in their own words, and no rule proposed here pretends otherwise.

## Calls made for you

1. **`docs/plans` as the plan directory**, because `docs/CONVENTIONS.md` defines no
   `- **Plan directory:**` key — guard row 1, re-applied here rather than trusted from the caller.
2. **The manifest is a TSV, not markdown**, so a shell checker parses it with `read -r` and no
   markdown-table splitting. `docs/rules/authorities.tsv` is its only path.
3. **The manifest holds locations, never content.** A location going stale is precisely what the
   checker detects, so a manifest of locations is self-checking in a way a copy of rule text is not.
4. **HTML comment markers** (`<!-- authority: -->` / `<!-- cites: -->`) rather than heading-name
   matching. Headings are prose and get reworded; the guard table has no heading of its own at all
   (it sits under `### Where it goes` in `agents/tech-lead.md`), so heading matching cannot cover it.
5. **Gate 2d triggers on `agents/`, `skills/`, `scripts/`, `CLAUDE.md`** — not on every changeset.
   Unlike `lint-identifiers.sh`, whose subject can be introduced by any file, an authority and its
   pointers live in those four places today. A paraphrase introduced under `docs/` escapes the
   trigger, and that is not a hole, because the checker cannot detect paraphrase anywhere.
6. **Exit codes follow `lint-identifiers.sh`:** 0 clean, 1 finding, **2 self-test failed**. An exit 2
   is never converted to a PASS.
7. **No `Model Overrides` were issued**, and none is omitted by oversight. Every file in this cut is a
   prompt file, a shell script, or a memory file; the pack deliberately removed `skill-writer`, so the
   coordinating session writes prompt files. No engineer agent is dispatched, so there is no default
   model to escalate.
8. **The plan file itself does not restate the guard table or the bar-soundness rows.** It cites them.
   A plan about copy-staleness that copies two tables would be the failure it describes.
   **This is documentation for the human, not an enforceable call.** "Does not restate" is a quality
   with no artifact to look up, so merge-reviewer's Tier 3 skips it by construction and it enforces
   nothing downstream. Left as written and reclassified, rather than sharpened, because the checkable
   version of it is BAR-011's reader-check half — which already exists and already says a clean
   `lint-authorities.sh` run cannot establish it.

## Deviations

- **Call:** `## What ships` — three changes in one cut. **Shipped instead: change 1 only.** Changes 2
  (`authorities.tsv` + `lint-authorities.sh` + markers + two new gates) and 3 (the `skills:` binding
  probe) are **deferred to a later cut and are not implemented.** **Decided by:** the operator, on
  devils-advocate's finding that change 2 **cannot be specified** as written — see `## Challenge`. So the
  bars covering changes 2 and 3 are **unmet by design**, not failed: BAR-003, 004, 005, 006, 008, 010,
  011, 012, 013 and 014 all describe work this cut did not do. Nothing hands this `plan_id` to a gate,
  and consumption is opt-in, so the plan is inert until the deferred work is planned properly.
- **What shipped, and where:** the single-writer discipline, as three rules in the three files that own
  the transition — `agents/tech-lead.md` (a revision `Read`s first and uses `Edit`, never a whole-file
  `Write`, and never touches `## Challenge` or audited bar text), `agents/devils-advocate.md` (edit bars
  with `Edit`; answer a survival re-ask against the file as it now stands; report a loss rather than
  silently re-adding), and `skills/plan/SKILL.md` (one writer at a time, no parallel dispatch, and the
  coordinating session must state either *"devils-advocate re-confirmed its edits survived"* or *"no
  post-audit revision occurred"* — an absent statement is not the second one). Plus the `repo-map.md`
  fix below.
- **Call:** the cut leaves `memory/architecture/repo-map.md` alone. **Shipped instead:** added the
  missing `lint-identifiers.sh` entry. **Decided by:** the coordinating session, on devils-advocate's
  finding — verified — that the map documents `lint-agents.sh` and `lint-plans.sh` and **omits the third
  blocking gate entirely.** It was a live example of the rot the deferred manifest is meant to prevent,
  and leaving it in place while deferring the manifest would have left the counterexample and removed
  the fix.
- **Two questions the deferred cut must answer first**, recorded here because the author never reported
  and cannot be asked: **(1)** the declared shared literal is **two strings** — the short grep needle
  that four consumers match on, and the full three-line template held only in `agents/tech-lead.md`
  (`scripts/lint-plans.sh:100` holds a truncated one-line copy of it). They need two ids and a
  `quotes-it` class that exempts incident records and plan files. *(The needle is described rather than
  reproduced here, for the reason in the last bullet.)* **(2)** the checker's excluded scope —
  `docs/plans/` and `memory/` — exists today only inside one bar's grep and must become a stated call.
- **Not a deviation:** `tech-lead` wrote this plan and **never reported**, going idle twice including
  after a re-request. `devils-advocate` is therefore the only judgement this plan received, and it
  reviewed the file rather than an author's narrative. Recorded because a plan that reads as reviewed and
  a plan whose author vouched for it are different states, and only one of them happened here.

- **A live instance of the defect this cut was about, produced while writing this section.** The first
  draft of these deviations **quoted the sentinel needle verbatim** to record what had been replaced.
  `scripts/lint-plans.sh` then reported *"still holds its sentinel"* on a section that was fully filled
  in — and `merge-reviewer`'s Tier 1 **fails** while that string is present, so this plan would have
  failed a gate for containing a quotation of the string it was describing. The quotation was removed.
  **This is the `must-match` versus `quotes-it` question of deferred question (1), demonstrated rather
  than argued**, and it is the third time today a checker on this pack was defeated by its own subject
  matter — after `pipefail` breaking the sentinel check itself, and a mangled ellipsis making a compliant
  placeholder read as a violation.

_(This section was written at step 10 by the coordinating session, replacing the sentinel line

merge-reviewer runs — with `None.` if nothing diverged, or one bullet per departure.
Leave this line exactly as it is._

## Risks

- **The checker is a fourth always-adjacent blocking gate.** Gate fatigue is real and the pack already
  runs three script gates plus `lint-plans.sh` at three call sites. Mitigation: the trigger is a path
  set, not every changeset, and the check is a single fast pass over a small manifest.
- **A manifest is a registry, and registries rot.** A row pointing at a moved file must fail loudly
  rather than be skipped. BAR-014 exists specifically because a checker that trusts its own manifest
  is a checker that reports clean when the manifest is wrong.
- **Change 1's rules are prose, enforced by nothing mechanical.** This is stated plainly rather than
  papered over: no script can observe that an agent used `Edit` instead of `Write`. Its bar (BAR-007)
  is a reproduction, not a text check, and it cannot run until `install.sh` runs and a new session
  starts.
- **Markers add noise to prose files agents read.** HTML comments are invisible when rendered and
  ignored by `lint-agents.sh` (which checks frontmatter and body line count only), but an agent reads
  raw text and will see them. Judged acceptable; reversible by deleting the markers and the manifest.
- **The residual concurrency risk is not closed, only made recoverable.** Nothing prevents a harness
  from dispatching two writers at once. What change 1 buys is that the second writer cannot clobber
  the first from a stale snapshot, and that a lost clause has a named party who can detect it.

## Out of scope

- The 18 prose-pointer files as a body of work.
- `scripts/lint-agents.sh` and its frontmatter allowlists.
- Whether the pack should become a plugin, and what `CLAUDE.md` not being loaded as plugin context
  implies for the rules currently living there. Real, and a different plan.
- Any change to `docs/CONVENTIONS.md`, including adding the `- **Plan directory:**` key.
- Retro-editing any merged plan in `docs/plans/`.

---

## Inputs

- `agents/tech-lead.md` — defines the plan-directory guard table (under `### Where it goes`, no
  heading of its own) and the `### Bar soundness` table. Writes the `## Deviations` sentinel.
- `agents/devils-advocate.md` — applies the bar-soundness table; cites it without restating.
- `agents/merge-reviewer.md` — defines the checkable-call rules (gate 4a Tier 3, "This is the single
  authority"); greps the sentinel literal at Tier 1; defines the three deviation tiers.
- `scripts/lint-plans.sh` — greps the sentinel literal twice, and carries the stale three-site comment.
- `skills/implement/SKILL.md` — step 182 quotes the sentinel literal; steps 5c–5e are the existing
  script-gate pattern to follow for 5f.
- `CLAUDE.md` — carries pointers to instances 2 and 4, and the gate-wiring section for 5f/2d.
- `scripts/lint-identifiers.sh` — the pattern to follow: two-sided self-test, exit 2, no denylist in a
  public repo.
- `memory/known-issues/2026-07-31-new-agent-not-dispatchable-in-creating-session.md` — agent edits do
  not take effect until `install.sh` runs and a new session starts. This is why BAR-006, BAR-007 and
  BAR-008 are gated and deferred rather than run in this cut.
- `memory/context/2026-08-04-grep-iF-aborts-on-this-machine.md` and
  `2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md` — two ways a shell check lies on
  this machine. The new script must avoid `grep -iF` and must never pipe a variable into a
  short-circuiting matcher under `pipefail`; use a herestring.
- `memory/context/2026-08-04-this-repo-is-public-never-write-real-identifiers.md` — placeholder tokens.

### Which of the four instances should migrate, and which should not

The four are not the same kind of coupling, and the caller's expectation about instance 3 inverts.

| Instance | Coupling | Verdict |
|---|---|---|
| 3. `## Deviations` sentinel | one **literal string** across four files, one of which is a shell script | **Strongest candidate for a mechanical check; weakest for migration.** A script cannot read a discipline skill. Only a byte-equality rule serves it — and it is already the instance whose pointer has gone stale (three sites claimed, five occurrences present). |
| 2. `### Bar soundness` | one authority, two pointers, and an **applier that is not the owner** — `devils-advocate` audits `tech-lead` using a table `tech-lead` owns | **The only migration with a gain beyond deduplication:** relocating it removes the appearance that the audited party owns the rubric. Migrate **first**, in a later cut, and only after the binding probe returns. |
| 1. plan-directory guard | one authority, one pointer, one applier | **Do not migrate.** Nothing to deduplicate; the only live risk is a dangling citation, which the checker covers. |
| 4. deviation tiers | one authority, one pointer, one applier (`merge-reviewer` is the sole applier) | **Do not migrate.** Same as 1, and there is no second consumer to serve. |

## Build steps

### Responsibility matrix

One block per lifecycle transition, written before choosing files, then diffed against the edited
file set.

```
Event: plan file first written
Writer:            tech-lead (Write)          Reader:   /plan step 2, lint-plans.sh
Mutator:           tech-lead                  Verifier: lint-plans.sh (structure only)
Failure behavior:  non-zero exit blocks /plan step 2
Persisted state:   <plan_dir>/<plan-id>.md, uncommitted, untracked
```

```
Event: devils-advocate edits bars and appends ## Challenge
Writer:            devils-advocate            Reader:   /plan step 3, lint-plans.sh
Mutator:           devils-advocate (Edit; Write only to append ## Challenge)
Verifier:          lint-plans.sh re-run at /plan step 3
Failure behavior:  non-zero exit blocks; sentinel state reported as [--], not a failure
Persisted state:   bars edited in place; ## Challenge appended; sentinel untouched
```

```
Event: plan file revised AFTER devils-advocate edited it   <- the transition that failed
Writer:            tech-lead, on a NEW dispatch only, after devils-advocate has REPORTED
Reader:            tech-lead must Read the current file first; the plan text in its prompt is stale
Mutator:           tech-lead, via Edit only — a whole-file Write is forbidden here
Verifier:          devils-advocate, re-asked to confirm its edits survived. THIS IS THE NEW DUTY —
                   nothing mechanical can see a lost clause, and today it was found only because
                   merge-reviewer happened to ask.
Failure behavior:  the coordinating session states either "devils-advocate re-confirmed" or "no
                   post-audit revision occurred". Neither stated -> the run has an unverified write.
Persisted state:   one file; devils-advocate's bar edits and ## Challenge must both survive
```

```
Event: an authority is cited from a second file
Writer:            whoever edits the citing file (usually the coordinating session)
Reader:            scripts/lint-authorities.sh
Mutator:           the same writer: adds a <!-- cites: id --> marker, and a manifest row if new
Verifier:          scripts/lint-authorities.sh — dangling citation, uncited authority, undeclared
                   literal copy, and manifest rows whose file no longer exists
Failure behavior:  exit 1 blocks at /implement 5f and merge-reviewer 2d; exit 2 = self-test failed
                   and is never converted to a PASS
Persisted state:   docs/rules/authorities.tsv plus markers in both files
```

```
Event: a declared shared literal changes (the ## Deviations sentinel)
Writer:            tech-lead owns the template text in agents/tech-lead.md
Reader:            lint-plans.sh, merge-reviewer Tier 1, /implement step 10
Mutator:           whoever edits the template
Verifier:          scripts/lint-authorities.sh literal-equality rule
Failure behavior:  exit 1 naming every declared site whose copy diverged AND every undeclared file
                   that holds the string
Persisted state:   the literal at four declared files; the manifest row enumerating them
```

```
Event: the `skills:` binding probe runs
Writer:            the OPERATOR runs install.sh and starts a new session (standing preference:
                   environment-mutating scripts are the operator's to run)
Reader:            the coordinating session, which records the verdict
Mutator:           coordinating session writes memory/context/<date>-agent-skills-frontmatter-...md
Verifier:          none needed — nothing in this cut depends on the outcome, which is the point
Failure behavior:  probe not run -> the file records NOT RUN with the blocking condition named.
                   Silence is not permitted; an absent file fails BAR-008.
Persisted state:   one memory/context file stating RUN (with steps and observed output) or NOT RUN
```

**Owner-to-file diff.** tech-lead -> `agents/tech-lead.md`. devils-advocate ->
`agents/devils-advocate.md`. Coordinating session -> `skills/plan/SKILL.md`,
`skills/implement/SKILL.md`, `CLAUDE.md`. Checker -> `scripts/lint-authorities.sh`. Manifest ->
`docs/rules/authorities.tsv`. merge-reviewer gate 2d -> `agents/merge-reviewer.md`. Stale comment ->
`scripts/lint-plans.sh`. New directory and script -> `memory/architecture/repo-map.md`. Probe verdict
-> `memory/context/`. Operator -> no file, and that is correct: the operator's duty is to run
`install.sh`, whose artifact is the session, not a commit.

**Every duty above has an owner with a file in scope.** The one duty with no possible mechanical
verifier is named as such in block 3 rather than left to look covered.

### Order

1. `docs/rules/authorities.tsv` with four rows. Nothing else can be written against a missing manifest.
2. `scripts/lint-authorities.sh`, self-test first, scan second — a checker that cannot demonstrate its
   own detection reports a clean repo for the wrong reason.
3. Markers at the four definition sites and every citation site. Run the checker; it must go from
   failing (markers absent) to clean (markers present). A checker that passes at both ends is a no-op.
4. `scripts/lint-plans.sh` comment correction, citing the manifest rather than a count.
5. Change 1's two rules into `skills/plan/SKILL.md`, `agents/tech-lead.md`,
   `agents/devils-advocate.md`.
6. Gate wiring: `CLAUDE.md`, `skills/implement/SKILL.md` step 5f, `agents/merge-reviewer.md` gate 2d.
7. `memory/architecture/repo-map.md` — new `docs/rules/` entry, new script under `scripts/`, re-stamp.
8. Existing gates, unmodified: `bash scripts/lint-agents.sh`, `bash scripts/lint-identifiers.sh`.
   `node scripts/obsidian-stop-hook.test.js` is **not** triggered — this changeset touches neither
   `obsidian-stop-hook.js` nor `obsidian-context-hook.js`. Say the skip out loud.
9. Reviewers: code-reviewer, then security-reviewer and smell-reviewer in parallel, then
   test-engineer, then merge-reviewer.

## Acceptance bars

- BAR-001: `scripts/lint-authorities.sh` self-tests two-sidedly and exits 2 when a rule fails to fire
  Evidence: manual -> run it on the clean tree (self-test line printed, exit 0), then break one fixture expectation and confirm exit 2 with no scan output. Exit 2 must never be reported as a pass.
- BAR-002: removing an `authority:` marker produces a named dangling-citation finding, not a pass
  Evidence: manual -> delete `<!-- authority: bar-soundness -->` from `agents/tech-lead.md`, confirm exit 1 naming `bar-soundness` and the citing files, restore, confirm exit 0. A null result here means the marker rule does not fire, not that citations are sound.
- BAR-003: an **undeclared** copy of a declared literal fails, even though every declared site agrees
  Evidence: manual -> paste **the exact string the manifest row declares** into a scratch file under `agents/`, confirm exit 1 naming that file, remove it. This is the discriminating bar for the design: a checker that only compares declared sites passes this and is therefore not doing the job.
  **"The sentinel literal" is ambiguous and this bar cannot be run until the manifest resolves it.** The tree holds two strings with different consumers: the grep needle `Deviations not yet reviewed` (at `scripts/lint-plans.sh:61`, `agents/merge-reviewer.md:419`, `skills/implement/SKILL.md:182`, `scripts/lint-plans.sh:100`, and quoted in `memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md:32`) and the full three-line template, held in full only at `agents/tech-lead.md:95` — `scripts/lint-plans.sh:100` holds a **truncated one-line** copy. Pasting whichever string the manifest does *not* declare produces a pass that proves nothing.
  Ordering note: `scripts/lint-agents.sh` scans `agents/`, so the scratch file must be removed before BAR-009 runs, or BAR-009 fails on this bar's fixture rather than on a real finding.
- BAR-004: the manifest's declared site set for the sentinel equals the tree's actual set **within a declared scope, and that scope is recorded as a call rather than as a filter in this command**
  Evidence: manual -> `grep -rlF 'Deviations not yet reviewed' --include='*.md' --include='*.sh' . | grep -v -e '^./docs/plans/' -e '^./memory/'` returns exactly the files in the manifest row — no more, no fewer. `-F` without `-i`: `grep -iF` aborts on this machine. Run the pipeline without `pipefail` set, or the short-circuiting-grep hazard in `memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md` applies to the evidence itself.
  **The two exclusions are load-bearing and are the bar's defect as originally written.** `--include` plus `grep -v` reduces "the tree's actual set" until it equals the manifest, which is row 5 self-exemption: the bar asserts equality with the tree while filtering the tree. Both exclusions are required for a pass today — `memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md:32` quotes the needle, and every file in `docs/plans/` holds it, **including this plan, twice: at its own `## Deviations` sentinel and inside this evidence line.** A file that documents the rule is an occurrence of it.
  This bar therefore fails unless `docs/rules/authorities.tsv` itself declares which files **must match** the literal and which merely **quote** it, and the checker's excluded scope is stated in `## Calls made for you` rather than inferred from this command. Verified count without the filters: **six occurrences across five non-plan files**, not the four-files/five-occurrences the narrative claims.
- BAR-005: `scripts/lint-plans.sh`'s sentinel comment states **no false claim**, not merely no count
  Evidence: files -> the sentinel comment block in `scripts/lint-plans.sh` names `docs/rules/authorities.tsv` and states no number. A filename cannot line-wrap, so the citation half is exact; the absence of a count is a reader's check and is stated as such rather than dressed up as mechanical.
  **Removing the count is not sufficient — the block holds two false claims and the original bar checked only one.** `scripts/lint-plans.sh:264-265` says "This literal is the single authority shared with `agents/merge-reviewer.md` Tier 1, which greps the same string", which reads as if merge-reviewer is the sole other holder; `skills/implement/SKILL.md:182` and the script's own self-test fixture at `:100` hold it too. Line 266's "all three move together" is stale by two sites *within the grep-needle class alone*. This bar passes with the count deleted and the false sole-sharer claim intact, which is row 1 — stated ≠ true — in the bar that exists to fix a stale statement.
- BAR-006: merge-reviewer runs gate 2d itself and reports the exit code it obtained
  Evidence: manual -> in a post-install session, run the pipeline on a changeset touching `agents/` and confirm merge-reviewer's report names gate 2d with an exit code, not an inference from a report.
  Gated: `install.sh` must have run and a new session started — an edited agent file has no effect until then (`memory/known-issues/2026-07-31-new-agent-not-dispatchable-in-creating-session.md`). NOT RUN in this cut, with that condition named.
  Cost: one `install.sh` run (mutates `~/.claude/`, reversible via `uninstall.sh`) plus one commit to a throwaway branch, reversible by branch deletion. No tracker writes, no writes outside the repo and `~/.claude/`. Operator-run.
- BAR-007: a devils-advocate bar edit survives a subsequent tech-lead revision, byte-identical
  Evidence: manual -> post-install session: `/plan` a throwaway task, let devils-advocate edit one bar, then dispatch tech-lead to revise a different section, then compare that bar's text before and after. This is a reproduction of the 2026-08-05 loss and it fails if change 1's rules do not hold.
  **A surviving bar is not sufficient evidence, and this is the bar's own row-3 defect.** `tech-lead` going idle without writing anything produces a byte-identical bar exactly as a compliant `Edit` does — and a silent stall is not hypothetical here: it is what happened to this plan's author twice on 2026-08-05. The revision must therefore be shown to have **occurred**: capture the revised section's text before and after as well, and treat "target bar unchanged **and** revised section changed" as the pass. Either half alone is indistinguishable from no write.
  Gated: same install-and-new-session condition as BAR-006.
  Cost: one uncommitted, untracked plan file under `docs/plans/`, removed by hand afterward. No commit, no tracker write, fully reversible. Operator-run.
- BAR-008: the `skills:` binding question has a recorded verdict, RUN or NOT RUN, never silence
  Evidence: files -> `memory/context/<date>-agent-skills-frontmatter-binding.md` exists and states either the steps run plus observed output, or `NOT RUN` naming the blocking condition. A verdict could in principle be fabricated; that costs nothing here because no shipped element depends on the outcome, which is why change 3 is a probe and not a migration.
  **The probe's agent file must live outside this repo's tree, and the plan does not say so.** BAR-009 requires `scripts/lint-agents.sh` byte-unchanged and passing, and `AGENT_VALID_FIELDS` at `scripts/lint-agents.sh:18` rejects `skills:` — so adding the field to any file under `agents/` here fails BAR-009 **and** blocks the linter. The probe is producible only against an installed agent under `~/.claude/agents/`. A `RUN` verdict must record an observed dispatch, not the harness merely tolerating the frontmatter; loading without error is not binding.
  **This bar gates nothing and, by its own text, proves nothing beyond a file's existence.** Recorded rather than resolved: whether change 3 warrants a bar at all, or is a task with a recorded verdict, is the operator's call.
  Gated: requires `install.sh` and a new session to test an agent frontmatter field at all.
  Cost: one `install.sh` run, reversible via `uninstall.sh`; no repo writes beyond the memory file. Operator-run.
- BAR-009: no existing gate was weakened — `scripts/lint-agents.sh` is byte-unchanged and still passes
  Evidence: manual -> `git diff --stat <base>...HEAD -- scripts/lint-agents.sh` is empty AND `bash scripts/lint-agents.sh` exits 0. The empty diff is the load-bearing half: it fails if the `skills:` field crept in, since that requires widening `AGENT_VALID_FIELDS`.
  **The ref is required, and its absence was the bar's defect.** Bare `git diff --stat <path>` compares the working tree to the **index**, so a change that has been `git add`-ed prints the same empty output as no change at all — row 3, in the half the bar itself calls load-bearing. Name the base ref, or run `git diff --stat HEAD -- <path>` at minimum to cover the staged case.
- BAR-010: `bash scripts/lint-identifiers.sh` exits 0 on this changeset
  Evidence: manual -> exit 0. An exit 2 means the checker could not prove its own rules fire and is not a pass; an exit 0 does not prove the absence of an identifier pasted as a substring inside a larger token, which remains a reader's check.
- BAR-011: this cut introduces no new copy of any of the four authorities' content
  Evidence: manual -> `bash scripts/lint-authorities.sh` exits 0 on the post-change tree, plus a reader check that this plan and every edited file cite rather than restate the guard table and the bar-soundness rows. A clean checker run does **not** establish the second half — it cannot see a paraphrase.
  **Exit 0 is not producible on the post-change tree until BAR-004's scope question is answered.** Under the literal rule as described, `memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md:32` is an undeclared occurrence and every file in `docs/plans/` is another, so the checker exits 1 on a correct tree unless the excluded scope is declared. Row 4: the named evidence is unsatisfiable as the design currently stands, not because the property is false.
- BAR-012: gate 2d states its trigger paths and requires a skip be said out loud
  Evidence: files -> `CLAUDE.md` and `agents/merge-reviewer.md` gate 2d both name the trigger paths and require an explicit skip statement. This is documentation for the human rather than a mechanical property, and is recorded as such.
  **The trigger set as stated in call 5 omits `docs/`, where `authorities.tsv` itself lives.** A changeset editing **only the manifest** — adding a row, the most likely single edit it will ever receive — does not trigger the checker that validates it, so the gate cannot see its own registry change. This bar must additionally require that the stated trigger either covers the manifest's own path, or records in `## Calls made for you` why a manifest-only change need not be checked. Call 5's justification ("live in those four places **today**") is itself an unchecked temporal claim, which is the defect class this cut exists to remove.
- BAR-013: `memory/architecture/repo-map.md` documents `docs/rules/` and `scripts/lint-authorities.sh`, **and its merge-reviewer gate enumeration is correct rather than merely extended**
  Evidence: files -> a `docs/rules/` section exists, `lint-authorities.sh` appears under `scripts/` with its gate call sites, and `Verified-at-commit` is re-stamped to this cut's HEAD.
  **The enumeration at `memory/architecture/repo-map.md:33` is already wrong and this bar as written passes straight through it.** That line lists merge-reviewer's gates as **2a and 2b only, omitting 2c**, and `scripts/lint-identifiers.sh` has **no entry anywhere in the file** — verified 2026-08-05. Adding two new entries satisfies the bar while the gate list stays wrong and 2d joins 2c in absence. Row 2: the bar names instances while the property is categorical. Require that line 33's gate list name every gate merge-reviewer runs, and that every script under `scripts/` carrying a blocking gate has an entry. This is also the plan's own registry-rot risk, observed rather than predicted — the pack's existing registry rotted in exactly the way `authorities.tsv` is being asked not to.
- BAR-014: the checker validates its own manifest rather than trusting it
  Evidence: manual -> point one manifest row at a path that does not exist, confirm exit 1 naming that row, restore. Distinct from BAR-002: that tests a missing marker in a present file; this tests a present row describing an absent file, which is how a registry rots silently.
  **Second direction, required: a marker whose id has no row.** Add `<!-- cites: nosuchauthority -->` to a file in the trigger set and confirm exit 1 naming the unregistered id, then remove it. The row-and-marker relation rots both ways, and the original evidence covered only the direction where the registry is over-complete. The direction it left open — a live citation the manifest has never heard of — is the one that lets a new cross-file authority enter the tree entirely unregistered, which is the plan's stated registry-rot risk in its most likely form. A null result on either direction means the rule does not fire, not that the registry is intact.

## Challenge

Challenged 2026-08-05. `tech-lead` wrote this plan and went idle twice without reporting, so there is
no author narrative and this section is the only judgement the plan received. Verdict: **change 1
ships; change 2 has two unanswered design questions that must be closed before the checker can be
written; change 3 should lose its bar.** Fourteen bars reviewed, eight edited, six left alone.
Nothing here is a veto — the decisions are the operator's.

### Restatement

Three independently motivated changes in one cut: (1) prose rules making the plan file single-writer,
so a post-audit revision cannot clobber a `devils-advocate` edit from a stale snapshot; (2) a
`docs/rules/authorities.tsv` manifest of ids and locations, a `scripts/lint-authorities.sh` checker,
HTML-comment markers at four definition sites and their citation sites, wired blocking at `/implement`
5f and merge-reviewer 2d; (3) a probe, with no dependent decision, of whether agent `skills:`
frontmatter binds outside a plugin. The cut declines a third component layer, and its stated reason —
that `AGENT_VALID_FIELDS` at `scripts/lint-agents.sh:18` rejects `skills:` today, so shipping the field
means widening a typo check before anyone has confirmed the field binds — is sound and is the right
call. `## Out of scope` already prices the plugin-context cost the caller asked about, and names it as
a different plan. That is adequate; see concern 8 for the one refinement.

### 1. The literal class is underspecified, and no checker can be written from the plan as it stands

**This is the blocking finding.** The plan treats the `## Deviations` sentinel as "one literal string
across four files." There are **two** distinct strings in the tree, and they have different consumers:

- **The grep needle** — the prefix `Deviations not yet reviewed`. Held by `scripts/lint-plans.sh:61`,
  `agents/merge-reviewer.md:419`, `skills/implement/SKILL.md:182`, `scripts/lint-plans.sh:100` (its own
  self-test fixture), and `memory/context/2026-08-05-pipefail-plus-short-circuiting-grep-returns-141.md:32`.
  If **this** changes, four greps break.
- **The full three-line template.** Held in full at `agents/tech-lead.md:95` only.
  `scripts/lint-plans.sh:100` holds a **truncated one-line** version. If the wording *after* the prefix
  changes, nothing breaks at all.

So a byte-equality rule over "the sentinel literal" fails at `lint-plans.sh:100` and at all three grep
sites if it picks the template, and matches every file in `docs/plans/` plus a memory quotation if it
picks the prefix. The plan's count correction (four files, five occurrences) is wrong in both classes —
the tree holds **six occurrences across five non-plan files** — but the count is the lesser problem.
**The class is the problem, and the design does not distinguish a must-match site from a file that
merely quotes the string.** `lint-plans.sh:264-266`'s existing comment is stale by two sites *within
the needle class alone*.

### 2. The exclusion set is a design decision smuggled into an evidence line

BAR-004's evidence pipes through `grep -v -e '^./docs/plans/' -e '^./memory/'`. Those two exclusions are
**load-bearing** — without them the memory quotation and every plan file are undeclared copies, and
BAR-011's "`lint-authorities.sh` exits 0 on the post-change tree" is unsatisfiable on day one. Yet the
exclusions appear **nowhere else in the plan**: not in `## Calls made for you`, not in change 2's
description, not in the responsibility matrix block for the shared-literal event. A rule that decides
what the checker can see should not first appear inside the command that verifies it.

Sharpest form of this: **BAR-004's own evidence line contains the literal it counts.** The plan file is
an occurrence. Any file documenting the rule becomes a violation of it. That is concern 1's must-match /
quotes-it distinction made concrete, and it is not a corner case — it is the checker's ordinary
operating condition in a repo that writes about its own rules.

### 3. BAR-007 cannot tell a compliant revision from a stalled one

The reproduction says: let `devils-advocate` edit a bar, dispatch `tech-lead` to revise a different
section, compare the bar before and after. A surviving bar is also what you observe if `tech-lead`
**stalled and wrote nothing** — which is what happened twice to this plan's own author, today. Row 3:
the check's failure produces the same result as the property holding. The bar needs independent evidence
that a write occurred. Edited.

### 4. BAR-009's `git diff --stat` is blind to a staged change

`git diff --stat scripts/lint-agents.sh` compares working tree to **index**. A staged modification
prints exactly the same empty output as no modification. The bar's own text says the empty diff is "the
load-bearing half" — and as written it is the half that does not hold. Edited to name a ref.

### 5. The probe conflicts with BAR-009, and nothing says where its agent file lives

BAR-008 tests an agent frontmatter field; BAR-009 requires `scripts/lint-agents.sh` byte-unchanged and
passing. Adding `skills:` to any file under `agents/` in this repo therefore **fails BAR-009 and blocks
`lint-agents.sh`**. The probe is only producible against an installed agent outside the repo tree, and
the plan never says so. A reader following BAR-008 literally breaks two gates. Edited.

Separately: BAR-008's own text concedes "a verdict could in principle be fabricated; that costs nothing
here because no shipped element depends on the outcome." A bar that gates nothing, proves nothing, and
is `NOT RUN` in this cut reduces to "a file exists." **That is a task, not a bar.** Recorded rather than
resolved — dropping it is the operator's call.

### 6. Registry rot is not speculative here; it is already present, and BAR-013 would pass through it

The caller's concern that `authorities.tsv` becomes the enumeration that rots is stronger than stated,
because the repo's **existing** registry already rotted in exactly this way:
`memory/architecture/repo-map.md` has **no entry for `scripts/lint-identifiers.sh` at all**, and its
merge-reviewer line 33 enumerates gates 2a and 2b while **omitting 2c** — the most recently added gate.
BAR-013 requires a `docs/rules/` section, a `lint-authorities.sh` entry, and a re-stamp. It would pass
while line 33 stays wrong and 2d joins 2c in absence. Row 2: the bar enumerates instances while the
property is categorical. Edited.

This is evidence about *this repo's* capacity to maintain a registry, not a general argument against
manifests. It does not sink change 2 — BAR-014 exists precisely for it — but it does mean the manifest
inherits a demonstrated failure mode, and the one mitigation that has worked in this pack is a checker
that fails on its own registry rather than a habit of updating it.

### 7. Change 1's detection step is real but weaker than the sentinel pattern it lives beside

The caller asks whether "re-ask `devils-advocate` to confirm" is real detection. It is real — an honest
"I cannot" is what recovered today's loss — but its failure behavior is prose: "neither stated -> the run
has an unverified write," with nothing that fails. And its verifier is the agent class documented as
prone to going idle (`memory/known-issues/2026-08-03-subagent-goes-idle-before-reporting.md`), so the
common failure is silence, which is the state the pack's own rule says must never be read as assent.

**Unconsidered alternative, not evaluated in the plan:** the pack already solved the isomorphic
"indistinguishable from nobody looking" problem *mechanically* — with a sentinel string and a gate that
greps it. `devils-advocate` already appends `## Challenge`, gate 4a already reads the plan with `Grep`,
and `lint-plans.sh` already parses sections. Whether a survival marker in the plan file is better or
worse than an attestation is a genuine question; the plan does not appear to have asked it, and it needs
no new script or gate. Raising, not prescribing.

### 8. Two further points, smaller

- **Gate 2d's trigger omits `docs/`, where the manifest lives.** Call 5's trigger set is
  `agents/`, `skills/`, `scripts/`, `CLAUDE.md`. A changeset that edits **only `authorities.tsv`** —
  adding a row, the single most likely edit — does not trigger the checker that validates it. Call 5's
  justification ("an authority and its pointers live in those four places **today**") is itself a
  staleness admission with nothing detecting the change. Recorded in BAR-012.
- **The plugin cost lands on change 2, not change 1.** Change 1's rules go into `skills/plan/SKILL.md`,
  `agents/tech-lead.md`, `agents/devils-advocate.md` — all plugin components, so they travel. Only the
  gate wiring in `CLAUDE.md` does not. `## Out of scope` prices this generically; the asymmetry is worth
  knowing when deciding what to ship.
- **`## What ships` line 55 promises "the memory files listed under `## Calls made for you`" and that
  section lists none.** Only BAR-008 names a memory file. Notably, the 2026-08-05 clause-loss incident —
  this cut's entire justification — is **in no memory file today** (verified across `memory/`), and the
  plan ships none. A rule lands in `agents/tech-lead.md` with no recorded incident behind it.
- **"18 files" is not reproducible.** The three obvious phrasings ("single authority", "do not restate",
  "the single authority") appear in 14 files, 7 of them plans or memory. In a plan whose thesis is that
  unchecked counts rot, its own headline count is unchecked.

### Calls made for you — falsifiability

Calls 1, 2, 3, 4, 6 and 7 each name a concrete artifact a reader could look up; call 1 verified
(`docs/CONVENTIONS.md` defines no `- **Plan directory:**` key). **Call 5 is checkable but its content is
defective** — see concern 8. **Call 8 has no lookup target**: "does not restate the guard table or the
bar-soundness rows" is a quality judgement about this file, so merge-reviewer Tier 3 skips it by
construction. Edited to declare itself documentation. **One call is missing**: the literal rule's scope —
which files must match, which may merely quote, and what the checker excludes. Concerns 1 and 2 are that
gap; it is not filled here, because filling it would be making the decision.

### Key questions

1. Which string is the declared literal — the grep needle or the full template — and which sites must
   match versus merely quote it? Nothing else in change 2 can be built until this is answered.
2. What does the checker exclude, and why is that a call rather than a `grep -v` in a bar?
3. Should gate 2d trigger on the directory holding its own manifest?
4. Is change 1's attestation preferable to a machine-detectable survival marker, given both were
   available and only one was considered?
5. Does change 3 warrant a bar, or is it a task with a recorded verdict?

### What would change my mind

If questions 1 and 2 have answers the author held and did not write down, change 2 is sound and my
first two concerns are documentation defects rather than design defects. Change 1 I judge shippable
as-is with BAR-007 corrected. I found no reason to narrow the cut beyond dropping BAR-008 to a task.

## Appended 2026-08-05 after commit — pricing the survival marker, which would have passed on the incident

**Appended, not rewritten, and `## Challenge` above is untouched** — per the rule this cut shipped. This
section answers `## Challenge` question 4 and is the coordinating session's, not the auditor's.

**The plain survival marker should not be planned. It would have passed cleanly on the very incident
that motivates it.**

The idea, restated so the reasoning is checkable: an auditor writes a marker into the plan; a later
revision composed from a **pre-audit snapshot** cannot carry forward a string it never saw, so the
marker's absence is mechanical evidence that the audit's work was overwritten. It is the pack's existing
sentinel pattern with the polarity flipped — the sentinel proves *nobody looked* by being present, a
marker proves *the audit is still here* by being present. One string, one grep, no agent alive.

**Why it fails on the actual case.** On 2026-08-05 the loss was in **bar text**, not in the narrative.
The revising agent **explicitly preserved `## Challenge`** while rewriting `BAR-008`. A marker living in
that section would therefore have **survived**, reported "audit intact", and said nothing while three
clauses were gone. So the marker's *location* is the entire design, and the only useful location is
where the edits are — inside the bars.

### A correction, and it sharpens deferred question 1

An earlier reading of this plan claimed that a plan *about* the shared literal cannot satisfy the gate
that greps it. **That is true of one consumer and false of the other, and the split is the finding.**

- **`scripts/lint-plans.sh` bounds its search to the `## Deviations` body**, stopping at the next `## `
  heading. So only an occurrence *inside that section* affects its verdict; the occurrences in
  `## Acceptance bars` and `## Challenge` never did. This plan reports `## Deviations filled in`
  correctly.
- **`merge-reviewer` Tier 1 greps the whole plan file.** Those same occurrences **would fail it.**

So this plan passes one consumer and fails the other **on the identical string**. Deferred question 1 is
therefore not only *which string is the authority* but **over what extent each consumer applies it** — a
section-bounded match and a whole-file match are different rules wearing one name, and a manifest that
records only ids and locations would not capture the difference. Any `literal` class needs a **scope**
field alongside its site list.

**One fact worth having before anyone builds either version: nothing verifies `## Challenge` today.** It
is referenced in six files — `agents/devils-advocate.md`, `agents/tech-lead.md`, `skills/plan/SKILL.md`,
`skills/implement/SKILL.md`, `scripts/lint-plans.sh`, `CLAUDE.md` — and checked by none of them.
`lint-plans.sh` names it only in comments, as a section to **exclude** from body scans, and requires only
`## Acceptance bars` and `## Deviations`. `merge-reviewer` never greps it. An audit's whole narrative can
disappear and no gate notices. There is consequently **no existing check to extend**; either version is
new machinery, though small.

### The variant worth planning instead: a per-bar fingerprint

The auditor records, inside `## Challenge`, a short **verbatim phrase from each bar it edited**, in a
machine-readable block — id, then fingerprint. A checker greps each phrase **inside the bar it names**;
a missing phrase fails, naming that bar. This detects **content loss per bar, mechanically, with no
agent alive**, and needs no hashing — which matters, because the auditor holds no `Bash` and could not
compute one.

Three limits, stated rather than discovered later:

1. **It catches the accident, not the intent.** A reviser who reads current content and deliberately
   removes a clause while updating the fingerprint defeats it. The 2026-08-05 loss was accidental, and
   that is the common case.
2. **A legitimate reword breaks the fingerprint**, producing a false positive. That is arguably the
   correct behaviour: it forces a reviser to acknowledge they changed an auditor's text rather than doing
   it silently — but it must be specified as a stop with a stated fix, not left to surprise someone.
3. **It is another declared shared literal**, so it depends on the manifest that change 2 defers. Building
   the fingerprint check before that manifest exists reproduces this cut's own criticism: a cross-file
   string with no registry.

### Disposition

**The attestation shipped in change 1 stays, and is the weaker half rather than the wrong one.** The two
are complementary: the fingerprint catches the accident with nobody alive, while the attestation catches
what no string can show — *"I cannot confirm"* is the answer that actually recovered the 2026-08-05 loss,
and no grep produces it. **Question 4 is therefore answered "neither alone", and the plain marker is
withdrawn from consideration.** Credit where due: `devils-advocate` raised the marker explicitly as
*"raising, not prescribing"* and did not price it; this section prices it and reaches a sharper
conclusion than the challenge did.
