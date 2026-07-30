# Design Brief: Obsidian CLI Transport + Durable Plan Spine

**Date:** 2026-07-27
**Status:** workstream 1 shipped (`66b60c1`); workstream 2 approved, specified, not started

---

## Pickup state — as of 2026-07-29 (end of day)

Written here rather than relying on `_current.md`: the thread mechanism that would normally
carry this had a live bug (item 1 below — fixed 2026-07-30), so a committed doc was the only
trustworthy handoff. Worth noting the irony — the artifact that would give in-flight work a
durable home is precisely what workstream 2 builds.

### Workstream 1 — closed

Shipped at `66b60c1`, diff-verified in `docs/claude-agent-pack-review-2026-07-28.md`. Two
follow-ons were **deliberately dropped on 2026-07-29, not deferred:**

- **Exercise the transport end-to-end** — declined. The chain had never been run once as a
  full CLI → REST → filesystem exercise. Accepted as-is.
- **Rotate `OBSIDIAN_REST_API_KEY`** — declined, no need.

Two items inside this brief are now stale and should be read as void: the **`OBSIDIAN_CLI_PATH`
installer plumbing** (already superseded by "Installer plumbing: cancelled, not deferred"
below), and the deferred read-side item for **`wiki-linter`**, which no longer exists — the
wiki family was retired from the pack and purged from `~/.claude` on 2026-07-29 (`4fd18f1`).

### Next session — in order

1. ~~**Fix the `DONE:` ordering bug in `scripts/obsidian-stop-hook.js:257-283`.**~~
   **FIXED 2026-07-30.** DONE removals were applied before THREAD additions, and the
   session-state file accumulates all session (it is only deleted at SessionEnd). So a file
   containing both `THREAD: X` and `DONE: X` removed X and then re-added it — a thread opened
   and closed in the same session could never close. Now a single pass in file order: a later
   `DONE:` beats an earlier `THREAD:` (closed), a later `THREAD:` beats an earlier `DONE:`
   (reopened). Both payloads get identical sanitizing so a `DONE:` still matches the text a
   `THREAD:` produced, and an empty payload on either directive is a no-op.

   Five regression tests added to `scripts/obsidian-stop-hook.test.js` (131 pass, 0 fail). The
   installed copy at `~/.claude/scripts/obsidian-stop-hook.js` was verified byte-identical to
   `HEAD` before overwriting — no local drift — and now matches the fixed repo copy.

   The three threads that were finished on 2026-07-29 but still showed open — non-interactive
   `install.sh` and the ADO brief update (both `d3214f9`), and the `/spec-intake` vs
   `/interview-me` scope check (`0bbb0bf`) — were cleared with `DONE:` lines in the same
   session as the fix, alongside a deliberate same-session `THREAD:`/`DONE:` pair that
   exercises the repaired path live.

2. **Workstream 2, first cut — 8 files, all of which already exist.** Verified 2026-07-29 that
   nothing has begun: no `docs/plans/`, no acceptance-bar language, and no `PROPOSED`/`SHIPPED`
   in any target file. So it is 8 edits plus one `mkdir` in `setup-project.sh`. Route through
   `/implement`. The load-bearing pair is `tech-lead` (writes the plan and its bars) and
   `merge-reviewer` (gates on them, verifies distillation, flips `SHIPPED`, deletes); the other
   six files are plumbing and docs.

3. **Open, low value:** re-run the `pack-review` redundancy pass against *installed* routing
   surface rather than repo files. The 2026-07-29 pass assessed 19 agents / 27 skills while the
   machine was routing 32 items. The drift is now cleaned, so a re-run would likely reach the
   same conclusion — this is about `pack-review` step 6 reading the right surface, not about a
   suspected collision.

4. **Constraint to honour when workstream 2's successor lands:** the `/interview-me` step 6
   edit must ship in the *same cut* as `/spec-intake`, never before, or the hand-off offers a
   slash command that is not installed. See `docs/ado-delivery-pipeline-brief.md`.

### Recommended amendment to the first cut — RESOLVED 2026-07-30

**The enforcement path should have a test, not just prose.** `merge-reviewer`'s gate being
correct is the entire premise of this cut, and "if a plan exists, enforce it" is currently a
sentence in a markdown file with nothing verifying it fires. The pack produced the write-only
failure **four** times before this brief was written — the session-state file nothing read back,
the unreachable Obsidian dispatch fixed in `cbf44ca`, the `session-*-unknown.txt` orphans, and
the `DONE:` bug above. Every one of them failed in exactly the way an untested gate fails:
silently, while looking installed. This is not in the 8-file scope as written; decide
explicitly whether to add it rather than letting it pass by default.

**Accepted 2026-07-30, all three parts.** See "Amendments accepted 2026-07-30" below.

---

## Design C — adopted 2026-07-30, authoritative

**This section supersedes both "Amendments accepted 2026-07-30" below and the
"Workstream 2: durable plan spine" section further down.** Where they conflict, this wins.
The superseded material is kept because the reasoning that killed it is worth more than the
design it killed.

### How it was killed

Three reviewers were run in sequence — `tech-lead`, `devils-advocate`, and `codex-reviewer`
(cross-model, via the `codex` CLI). All three independently rejected the design that had been
approved that morning. `codex` reached the load-bearing defect without being told it was the
leading candidate.

Five findings, each verified against the files rather than argued from the brief:

1. **Commit one is plan-only on every real run.** `agents/merge-reviewer.md:48-51` merges each
   engineer worktree with `git merge --no-ff` in Step 0, *before* the checklist. So by the time
   `git add -A` fires at `:245`, the implementation is already committed and the only uncommitted
   content left is the plan. Commit one therefore lands *after* the implementation as a
   plan-only commit — inverting the very ordering that justified committing the plan
   ("the PR shows intended shape against implementation").
2. **The `SHIPPED` flip was ceremony.** Deletion in the same commit discards it, so
   `ship-verify-failed` could only fire on a filesystem fault. *If the file is deleted the flip
   is ceremony; if the flip matters, do not delete the file.* The design wanted both and got
   neither.
3. **Five skills dispatch merge-reviewer**, not two — `implement:84`, `refactor:104`,
   `scaffold:89`, `hotfix:61`, `debug:79`. The gate's trigger was "a plan exists in the
   directory," a property of the *directory* rather than the run. A `PROPOSED` plan from a
   `/plan` session never implemented would be enforced against, flipped, and **deleted** by the
   next unrelated `/hotfix`, judged against the wrong work's bars. `/scaffold` never invokes
   tech-lead at all (zero mentions), so it could never own a plan but would consume one.
4. **Nothing bound a plan to the run that consumed it.** Plans were located by globbing. This
   is the root cause of 1 and 3, of the inability to choose among colliding plans, and of
   stranded plans being swept into unrelated commits.
5. **The extracted `plan-gate.sh` tested the invariant that has never failed.** What has failed
   five times is *nothing read the artifact back* — and that lives in the prose invocation, which
   no test touches. Testability was bought around the easy invariant. Meanwhile
   `agents/merge-reviewer.md:218-227` already contains a test-coverage gate that ships, and has
   already caught a real bug.

Also fatal on inspection: `--print-dir` was frozen as always-exit-0, but its stdout was passed
to tech-lead, which holds `Write` and therefore *creates parent directories* — so an unsafe or
placeholder value would be materialised before the guard ever ran. With `docs/CONVENTIONS.md`
byte-identical to the template and `[` legal in Windows filenames, a directory named
`[e.g., docs` would have been created, written to, and committed, with every component agreeing
on the same garbage. And every `reason=` code added converted an unowned duty from cosmetic into
blocking: `ambiguous-plan-set` weaponised the missing plan-reaper, `status-invalid` weaponised
the missing `IN_PROGRESS` owner in the four other callers. The gate grew more rigorous while the
ownership map stayed incomplete, so rigour amplified the gaps.

### What Design C is

**The artifact.** `<plan_dir>/<plan-id>.md`, committed when created and **never deleted**.
Frontmatter carries `plan_id`, `branch`, `origin_skill`, `created`. Body is the narrative half
for the human and the working-memory half for the agent. Deletion is what destroyed the
PR-review benefit; keeping the plan delivers it, and an accumulating `docs/plans/` is no worse
than the accumulating `memory/decisions/` the pack already treats as a feature.

**Consumption is opt-in per invocation.** The invoking skill passes an explicit `plan_id`;
downstream agents consume only that, never whatever happens to be in the directory. This closes
finding 3 **by construction rather than by rule** — `/hotfix`, `/debug`, `/scaffold`, and
`/refactor` never pass a `plan_id`, so they cannot consume or corrupt a plan, and need no edits.
Branch binding alone would not have sufficed: `/hotfix` on the *same* branch could still have
consumed a `/plan` artifact.

**Every acceptance bar carries evidence.** Markdown list items, each with an id and a required
`Evidence:` line naming `tests`, `manual`, or `files`. This is what lets merge-reviewer fail
against evidence instead of judgment, and it fixes the gap that gate 4 alone leaves — gate 4
fires only when new public methods or API endpoints exist, so a markdown-and-shell change would
otherwise pass unexamined. It also closes the vacuous-bars case that a length check cannot.

**`test-engineer` is the consumer.** It maps tests, or explicit non-test validation, to each bar
id. Without it the bars have no independent consumer and are inert rather than merely weak —
merge-reviewer (itself `model: sonnet`) would be judging bars written by the agent whose work
they measure.

**Enforcement extends `agents/merge-reviewer.md`'s existing gate 4** rather than adding a gate 6.
Reusing a gate that already ships and has already caught a bug beats introducing one that has
never run.

**Four "no plan" states**, not three — `not applicable`, `not required`, `required but missing`,
`stale-or-unbound`. The fourth is the one the earlier designs could not represent.

### Design C — 8 files

1. `agents/tech-lead.md` — write the plan, the frontmatter binding, and bars with evidence
2. `agents/test-engineer.md` — map tests or explicit validation to each bar id **(new to the cut;
   its omission was the fourth unowned duty)**
3. `agents/merge-reviewer.md` — extend gate 4: verify binding, verify each bar has evidence,
   distinguish the four no-plan states
4. `skills/plan/SKILL.md` — create the plan, emit its `plan_id`
5. `skills/implement/SKILL.md` — pass `plan_id` and whether a plan is required; adopt by id
6. `docs/CONVENTIONS.template.md` — the plan-path key, named explicitly
7. `scripts/setup-project.sh` — create `docs/plans/` with a `.gitkeep`
8. `CLAUDE.md` — the rules, including which skills opt in and which deliberately do not

**Deleted from scope entirely:** `scripts/plan-gate.sh`, `scripts/plan-gate.test.sh`,
`install.sh`, `uninstall.sh`, `scripts/check-updates.sh`, the `lint-agents.sh` assertion, the
status lifecycle, the two-commit sequence, `--ship`, deletion, and the distillation gate.

### The method finding — worth more than the design

Four duties this design named turned out to have no owning component: the plan-commit duty, the
`IN_PROGRESS` write, the plan-directory validation guard, and `test-engineer`. They were found one
at a time across three sessions by three different means.

The leak is structural: **the design recorded duties against *actors* (the stage-duties table)
while the implementation edited *files*, and nothing reconciled the two lists.** Three actors in
that table had no file in the edit set.

For any future design that distributes responsibilities across cooperating agents, build a
responsibility matrix per lifecycle transition before choosing files:

```
Event: <the transition>
Writer:            Reader:
Mutator:           Verifier:
Failure behavior:  Persisted state:
```

That catches actor/file mismatches, unowned duties, and impossible timing — such as "verify
deletion happened," which no component can observe from either side of the deletion. A single
such pass would have caught all four defects on paper at once.

---

## Amendments accepted 2026-07-30 — SUPERSEDED by Design C above

**Do not build from this section.** Every decision in it was reversed or made moot on
2026-07-30 by the review described in "Design C" above. It is retained only because the
reasoning is part of the record. In particular: the two-commit design, the `SHIPPED` flip, the
gate extraction to `scripts/plan-gate.sh`, the `--ship` mode, and the file-count growth to 14
are all **void**.

Four decisions taken before the first cut was handed to `/implement`. They amend the
"First cut — 8 files" section further down; that section's file list is unchanged — the
amendments land *inside* those eight files rather than growing the list.

### 1. The plan-commit duty was stated but unassigned — merge-reviewer now commits twice

The spec says *"The plan **is committed** when created, so the PR shows intended shape against
implementation."* No agent in the pipeline could do that:

- `tech-lead` (step 2) writes the plan but its tools are `Read, Write, Edit, Grep, Glob` — **no
  `Bash`**, so it cannot commit.
- Nothing between steps 2 and 10 commits anything.
- `merge-reviewer` (step 10) performs the only `git add -A` + `git commit`, and was also
  supposed to delete the plan in the same breath.

Net effect as originally written: the plan is created uncommitted at step 2 and deleted before
the only commit runs, so `git add -A` stages nothing for it and **it never appears in any
commit**. "Preserved in commit history" was false, and the PR-review benefit that justified
committing it at all evaporated. This is the write-only failure mode reappearing inside the
artifact designed to eliminate it — a fifth instance, caught on paper this time.

**Decision: `merge-reviewer` commits twice.** Commit one carries the implementation *with the
plan file still present*; commit two flips `status: SHIPPED` and deletes it. This keeps the duty
inside the only pipeline agent holding `Bash`, honours the "11-step order does not change"
constraint (no new stage), and produces exactly the two-commit history the brief wanted.

Rejected alternatives:
- *A new git-engineer (Mode B) step after tech-lead* — correct in isolation, but adds a pipeline
  step. The 11-step constraint was written to prevent stage churn; bending it was judged
  unnecessary once option 2 was available.
- *Drop the commit claim and treat the plan as session-local* — cheapest, but removes "durable"
  from "durable plan spine."

### 2. Worktree-isolated stages cannot see an uncommitted plan

Engineers run under `isolation: "worktree"` — a separate checkout. Uncommitted changes in the
primary working tree **do not exist there**, so an uncommitted `docs/plans/<slug>.md` is
invisible to every engineer.

Nearly moot for this cut (Deviations logging is deferred, and `test-engineer` is not
worktree-isolated so it reads the bars fine), but it is a second, independent reason to commit
the plan early, and it becomes blocking the moment the deferred "engineers report departures
from the plan" duty lands. Recorded now rather than rediscovered in cut two.

### 3. The gate splits into a mechanical half and a judgment half

The amendment above asked for a test. There is no parser and no plan-file module — the gate is
prose, and prose is not unit-testable. The useful move is to shrink the untestable part:

| Half | Checks | Testable |
|---|---|---|
| **Mechanical** | plan file exists; `status` transitioned `PROPOSED` → `SHIPPED`; deletion happened; deletion was preceded by a `memory/` write when one was warranted | Yes — all grep-able, and `merge-reviewer` already holds `Bash`/`Grep` |
| **Judgment** | "bars met" | No — same class as "Critical findings resolved," which has never been testable |

**Decision: build the mechanical half as explicit shell checks inside `merge-reviewer` rather
than prose judgment, and test that half.** Three parts, all accepted:

1. **Mechanical checks** in `merge-reviewer` — real commands, not prose.
2. **A `lint-agents.sh` presence assertion** so a future edit cannot silently delete the gate
   section. Drift is how this pack has failed before; this is the cheap insurance.
3. **The scratch-project exercise** — edit → `install.sh` → run in a scratch project → confirm
   an unmet bar actually produces a FAIL. This is the *only* thing that proves the gate fires,
   and per "Known risks" it is what "proven end-to-end" already means. **In scope for this cut,
   not a follow-on.** Noted deliberately: the equivalent exercise was declined for workstream 1,
   and declining it twice on the artifact whose dominant risk is *being write-only* would be a
   materially different bet than declining it once on a transport chain.

### 4. `/plan` and `/implement` both invoke tech-lead — adoption rule required

`/plan` produces a plan with `status: PROPOSED` and stops. If the user then runs `/implement`,
step 2 invokes `tech-lead` again and writes a **second** plan file for the same work. Nothing in
the 8-file cut said "adopt an existing `PROPOSED` plan instead of re-planning."

**Decision: add the adoption rule to `skills/implement/SKILL.md`** (already file 4 in the cut).
It is arguably the highest-value line in the whole cut — it is what makes `/plan` → `/implement`
a spine rather than two disconnected planning events.

### Two smaller gaps closed in the same cut

- **Name the CONVENTIONS.md key.** The spec said "an optional key" without giving the literal
  string. `tech-lead` and `merge-reviewer` must grep for the *same* token or the override
  silently does nothing — another silent-no-op waiting to happen. Settle on the exact key name
  in this cut.
- **Slug collisions.** Two `/implement` runs in one repo, or a re-run after an abandoned
  pipeline, collide on `docs/plans/<slug>.md`. Same class as the capture write-once problem, and
  the same fix applies: read the target path first, append a numeric suffix until free.

---

**Original status:** approved, not yet implemented
**Origin:** interview session comparing the pack against two external references — a "software factory" pipeline diagram and [simoncorry/foundry](https://github.com/simoncorry/foundry)

Two independent workstreams, documented together, built in order. They share no files.

---

## Goal

**Workstream 1 — Obsidian CLI transport.** Insert the official [Obsidian CLI](https://obsidian.md/cli)
into the vault-write chain, and eliminate the read-modify-write daily-note append that currently
risks clobbering hand-edits.

**Workstream 2 — Durable plan spine.** Give the pack a plan artifact that downstream stages act on
and can *fail against*. Today `tech-lead`'s plan lives in chat and dies there: nothing checks it
off, no acceptance criteria exist before code is written, and no stage can be blocked by it.

---

## Constraints

Each of these was verified during the interview, not assumed.

- **Agents are machine-level, not per-project.** `install.sh:6,14,17,25,33` copies `agents/` and
  `skills/` to `$HOME/.claude/`; one copy serves every project on the machine. Only
  `scripts/setup-project.sh:19-36` is per-project (it writes `CLAUDE.md`, `docs/CONVENTIONS.md`,
  `docs/MEMORY-WRITING.md`, and the four `memory/` subdirs). Both workstreams must therefore
  degrade cleanly in repos that never ran `setup-project.sh` — including repos with no `memory/`,
  no `docs/`, and possibly no git.
- **The Obsidian CLI always exits 0, even on error.** Probed on 2026-07-27: a bogus command, a
  missing file, and a path-traversal attempt each printed `Error: …` to stdout and returned exit 0.
  Exit-code-driven fallback is impossible.
- **An unrecognized `vault=` is silently ignored and the write goes to the active vault.**
  Probed 2026-07-27: `append vault="NoSuchVault" …` printed `Appended to:` and wrote into the real
  vault. This invalidates the mitigation originally recorded in this brief ("pass `vault=`
  explicitly") — passing it correctly protects nothing, because a wrong value does not fail.
  Filesystem read-back against the absolute path is the only defence. Both failure modes are
  documented in `memory/known-issues/2026-07-27-obsidian-cli-silent-failure-modes.md`.
- **The CLI requires the Obsidian desktop app to be running.** The filesystem rung is mandatory,
  not a courtesy.
- **`vault=` targets by name; the pack only knows `OBSIDIAN_VAULT_PATH` (a path).** Multi-vault
  users will write to the wrong vault unless the name is derived and passed explicitly.
- **CLI reads appear sandboxed to the vault** — `read path="../../../Windows/System32/drivers/etc/hosts"`
  was refused. Writes outside the vault were deliberately *not* tested, so the pack must keep
  validating vault-relative paths itself rather than delegating that safety.
- **The `Write` tool creates missing parent directories.** Probed three levels deep in a single
  call. Every agent holding `Write` already creates `memory/<subdir>/` implicitly on first write.
- **The 11-step `/implement` order does not change.** Agents gain duties against the plan file; no
  stages are added, split, reordered, or merged.
- **Reviewers stay read-only.** `code-reviewer`, `security-reviewer`, and `performance-reviewer`
  keep `Read, Grep, Glob`. Foundry has reviewer findings land as plan edits; the pack will not copy
  that, because granting `Write` to read-only agents trades a clean invariant for convenience. The
  lead session folds their findings into the plan instead.
- **Engineers never write the plan file.** They run under `isolation: "worktree"`; direct writes
  would conflict on the one file every stage depends on. They surface, the lead session writes —
  the same pattern as the 2026-07-27 `tech-lead`/`devils-advocate` Obsidian-sync fix (`cbf44ca`).
- **`/hotfix` and `/debug` keep their ceremony exemption.** No plan, no gate.

---

## Workstream 1: Obsidian CLI transport

### Scope: every vault write (revised 2026-07-27)

**Superseding the original "append only" decision.** The chain covers both the daily-note append
and main-file creation. The original scope limit rested on an assumption that live probing
disproved: that escaping a frontmatter body into a shell `content=` argument would be fragile.
It is not — `create` round-tripped YAML delimiters, colons, brackets, an em dash, a double quote,
a `$`, and a wikilink with zero corruption. With that objection gone, one chain for every write
beats two policies with a special case.

The daily-note append remains the highest-value target regardless: it was the pack's *only*
read-modify-write against the vault, reading the whole note and writing the entire file back — a
data-loss window on a file the user also edits by hand. Rungs 1 and 2 both append in place and
close it.

### Transport chain

**CLI → REST API → filesystem**, in that order, for every write. Each rung falls through to the
next on unverified failure; the filesystem rung is unconditional.

| Rung | Create | Append | Reports its own failures? |
|---|---|---|---|
| 1. Obsidian CLI | `create` → `Created:` (**never** `overwrite` — see below) | `append … inline` with a leading newline escape → `Appended to:` | **No** — exit 0 on all errors |
| 2. Local REST API | `PUT /vault/<rel>` → 204 | `POST /vault/<rel>` → 204 | Yes — HTTP status |
| 3. Filesystem | `Write` tool | snapshot rewrite | Yes — `Write` fails loudly |

**`overwrite` is never passed to the CLI.** Because an unrecognized `vault=` is silently ignored,
a misrouted `create … overwrite` would not merely disclose content to another vault — it would
*destroy* an unrelated note there. Data loss, not leakage. Without the flag, a misrouted create
fails harmlessly when the target exists. Two consequences, both deliberate:

- The recap's intentional overwrite of its own dated file cannot use rung 1. Once that file
  exists, `create` declines and the chain falls through to rung 2's `PUT` or rung 3's `Write`,
  which replace it safely and report honestly.
- Capture write-once is enforced *ahead* of the chain, not by it — rung 2's `PUT` is inherently an
  overwrite and rung 3's `Write` replaces anything. The target path is read first, and on
  collision a numeric suffix is appended until it is free.

`OBSIDIAN_CLI_MODE` is **not** extended and gains no `cli` value. It stays as-is; the chain is
unconditional and degrades on its own, so a mode selector would only add a way to misconfigure it.
`OBSIDIAN_CLI_PATH` was considered and dropped — runtime detection of three well-known paths
covers every standard install, and the installer stays untouched.

**Ordering caveat, accepted deliberately.** CLI-first prefers the *more available* channel over
the *more honest* one: the CLI ships with the app and needs no plugin, but it reports success on
failure, so every write depends on the verification rule below being correct. API-first was the
alternative — fewer writes leaning on verification, but dead on any machine without the plugin.
Availability won.

**Ownership moved into the agent.** The chain cannot be split between skill and agent: the skill
runs first, so any REST attempt there would always precede the CLI and defeat the ordering.
`obsidian-writer` therefore owns all three rungs, and the `session_api_written` /
`recap_api_written` protocol is deleted. `obsidian-capture` and `obsidian-recap` each shed ~65
lines of duplicated REST logic.

**The API key never travels as a parameter.** `obsidian-writer` reads `OBSIDIAN_REST_API_KEY`,
`OBSIDIAN_REST_API_PORT`, and `OBSIDIAN_REST_API_HTTPS` from the environment — verified visible to
the shell — so the secret stays out of the dispatch payload and the transcript.

### The verification rule

The CLI's exit code carries no signal and its `vault=` argument is not binding, so define this
once and reference it everywhere:

> A CLI call has succeeded only when **stdout begins with the operation's success line**
> (`Created:` / `Appended to:`) *and* **the effect is confirmed by reading the absolute path back
> with the `Read` tool.** Anything unverified falls through to the next rung.

Two details are load-bearing:

- **Positive check, not negative.** Match the success prefix rather than the absence of `Error:`.
- **Read-back via the `Read` tool against the absolute path** — never the CLI's own `read` (same
  wrong vault on a misroute, so it would confirm a bad write) and never Bash `cat`/`grep` (Bash
  fails silently on this machine per
  `memory/known-issues/2026-07-10-bash-tool-silent-failure-windows.md`, and the CLI is invoked
  *through* Bash, making it a silent check of a silent channel).

The REST rung needs none of this: any 2xx is success, anything else is failure.

### Detection

Runtime, inside `obsidian-writer` — first hit wins, and no hit simply falls to rung 2:

| Platform | Path (POSIX form; invoked through Bash) |
|---|---|
| Windows | `/c/Program Files/Obsidian/Obsidian.com` |
| macOS | `/usr/local/bin/obsidian` |
| Linux | `$HOME/.local/bin/obsidian` |

On Windows the binary is `Obsidian.com`, a terminal redirector beside `Obsidian.exe`. It is not on
`PATH` and `command -v obsidian` resolves ambiguously under Git Bash, so the literal path is
tested. **No `OBSIDIAN_CLI_PATH` and no installer change** — runtime detection covers every
standard install, and leaving `install.sh` alone removes the highest-consequence work in the
original plan. If a non-default install location ever turns up (portable, non-`C:` drive,
Flatpak/Snap), an override env var read by the agent is a three-line addition.

### Preflight: dropped

The original plan specified a `files total` probe to confirm the app is running. Verification
already covers it — a failed CLI call errors and writes nothing, so there is no partial state to
guard against and no reason to pay for an extra round-trip.

### Path and vault handling

- Absolute paths convert to vault-relative for the CLI's `path=` and the REST URL.
- The iron rule (writes confined to `Claude/` and the effective projects folder) is validated on
  the **vault-relative** form, because both `path=` and the REST URL bypass filesystem checks.
- `vault=` is passed on every call but **guarantees nothing** — an unrecognized name is silently
  ignored and the write goes to the active vault. Filesystem read-back is the only real defence.

### REST rung requirements

- **Body from a temp file via `--data-binary @file`, never inline.** An inline body mangles UTF-8
  to U+FFFD; every daily-note line contains an em dash, so this would corrupt them all. Verified
  both ways by probe. Note this also fixes a pre-existing bug: the REST code deleted from
  `obsidian-capture` used an inline `--data-binary "$BODY"`.
- **`$OBSIDIAN_REST_API_KEY` referenced as a variable, never interpolated.** The command text
  reaches transcripts and logs; the variable name is safe, the value is not.
- **`-k` required** — the plugin serves a self-signed certificate on loopback.

### Delivered — 8 files

1. `agents/obsidian-writer.md` — owns the three-rung chain for create and append
2. `skills/obsidian-capture/SKILL.md` — REST attempt deleted, dispatch only
3. `skills/obsidian-recap/SKILL.md` — same
4. `skills/plan/SKILL.md` — stale field removed
5. `skills/refactor/SKILL.md` — stale field removed
6. `skills/implement/SKILL.md` — stale field removed
7. `agents/tech-lead.md` — stale field list corrected
8. `agents/devils-advocate.md` — stale field list corrected

Plus `memory/known-issues/2026-07-27-obsidian-cli-silent-failure-modes.md` from the earlier cut.

**Installer plumbing: cancelled, not deferred.** With runtime detection and no new
`OBSIDIAN_CLI_MODE` value, `install.sh`, `uninstall.sh`, and `check-readiness.sh` need no changes
at all.

### Deferred to a follow-on, not in the first cut

The CLI also replaces work the pack currently does by hand on the **read** side. Out of scope here
because the ask was the write chain, but worth recording:

- `/obsidian-search` — `search query= format=json` and `search:context` instead of glob-and-grep
- ~~`wiki-linter` — `orphans`, `unresolved`, and `backlinks` natively instead of deriving them~~
  **Void as of 2026-07-29:** the wiki skill family and its three agents were retired from the
  pack (`d11bfb1`, 2026-05-16) and purged from `~/.claude` in `4fd18f1`. There is no
  `wiki-linter` to improve.
- `property:set` / `property:read` — frontmatter edits without rewriting the file
- `daily:path` — respects the user's Daily Notes plugin config, though the pack deliberately uses
  its own per-project daily structure

---

## Workstream 2: durable plan spine — SUPERSEDED by Design C

**Do not build from this section.** The artifact shape and the acceptance-bar concept survive;
the lifecycle, the deletion, the two-commit sequence, the distillation gate, and the
directory-glob trigger were all rejected on 2026-07-30. See "Design C — adopted 2026-07-30"
near the top of this document. Retained for the reasoning and for the rejected alternatives.

Adapted from Foundry's plan-file design, reconciled with the pack's `memory/` ethos.

### The artifact

`tech-lead` writes `docs/plans/<slug>.md` — kebab-case slug, frontmatter (`id`, `status: PROPOSED`,
`created`), then two halves split by a horizontal rule:

- **Narrative half (for the human).** What ships and what deliberately doesn't, the calls made on
  their behalf so they can veto, honest risks, out-of-scope. Ordered by what the human is most
  likely to want changed: user-facing shape first, data choices next, mechanical work last.
- **Working-memory half (for the agent).** Inputs, ordered build steps, and **acceptance bars
  concrete enough that a stranger could check them.**

Path comes from an optional key in the project's `docs/CONVENTIONS.md`, defaulting to
`docs/plans/`. That is the only per-project knob available, since agent files are machine-level.

### Stage duties

| Stage | Duty |
|---|---|
| `tech-lead` | Writes the plan, including the acceptance bars |
| `devils-advocate` | Pressure-tests the bars, editing the plan in place (already holds `Write`) |
| Engineers | Report departures from the plan in their handoff; the lead session writes them to a `## Deviations` section (deferred past the first cut) |
| `test-engineer` | Writes tests *against* the bars rather than inventing criteria |
| `merge-reviewer` | Verifies bars met, verifies durable findings recorded in `memory/`, flips `status: SHIPPED`, deletes the plan — across **two commits**, see Lifecycle below (amended 2026-07-30) |

### Lifecycle

`PROPOSED` → `IN_PROGRESS` → `SHIPPED`, then deleted. Plans are scaffolding; `memory/` and git
history are the durable record.

The plan **is committed** when created, so the PR shows intended shape against implementation and a
teammate can review one against the other. merge-reviewer's final commit flips it to `SHIPPED` and
deletes it — net-zero in the PR's file list, preserved in commit history.

**Amended 2026-07-30 — the commit duty had no owner.** `tech-lead` writes the plan but holds no
`Bash`, and merge-reviewer's single `git add -A` would have deleted the file before ever
committing it, so the plan would never have entered history at all. `merge-reviewer` therefore
commits **twice**: commit one carries the implementation with the plan still present, commit two
flips `SHIPPED` and deletes it. Full reasoning and rejected alternatives in "Amendments accepted
2026-07-30" near the top of this document.

Deletion is gated on distillation: anything durable the run surfaced must be recorded in
`memory/decisions/` or `memory/known-issues/` first. Because `Write` creates parent directories, a
missing `memory/` is not an excuse to skip it. The gate cannot be "a memory file must exist" —
most tasks produce nothing durable, and that is a legitimate pass. It is the same judgment
merge-reviewer already applies to findings.

### First cut — 8 files

1. `agents/tech-lead.md` — write the plan file and the acceptance bars; resolve the plan path from
   the named CONVENTIONS.md key; suffix the slug on collision
2. `agents/merge-reviewer.md` — **mechanical** checks for plan presence, `PROPOSED` → `SHIPPED`
   transition, deletion, and distillation-before-deletion; judgment call on bars met; two commits
3. `skills/plan/SKILL.md` — create the plan, pass it forward
4. `skills/implement/SKILL.md` — wire the plan through the pipeline, **and adopt an existing
   `PROPOSED` plan instead of re-planning**
5. `scripts/setup-project.sh` — create `docs/plans/`
6. `docs/CONVENTIONS.template.md` — document the optional plan-path key (name it explicitly)
7. `docs/MEMORY-WRITING.md` — document lazy directory creation as intended behavior
8. `CLAUDE.md` — the plan-spine rules

Plus, per the 2026-07-30 amendments: a presence assertion in `scripts/lint-agents.sh` for the
gate section, and the scratch-project exercise (edit → `install.sh` → run → confirm an unmet bar
FAILs) as the cut's acceptance bar rather than a follow-on.

Scoped to prove **write → read → fail** end-to-end before anything else hangs off the artifact.
Deviations logging, reviewer findings folded into the plan, and the `start-up`/`handoff` continuity
pair all wait for a later cut.

---

## Key decisions

- **CLI first, spine second.** The CLI work removes a live data-loss risk and is self-contained.
  The spine touches `tech-lead` and `merge-reviewer` and deserves undivided attention.
- **One chain for every write, CLI first.** Supersedes the earlier "append only, API first"
  decision. Probing disproved the escaping objection that limited the scope, and CLI-first
  trades verification burden for availability — see "Scope" and the ordering caveat above.
- **The chain lives in the agent, not the skills.** Forced by ordering: a skill's REST attempt
  would always run before the agent's CLI attempt. This also deletes ~130 lines of duplicated
  transport logic and keeps the API key out of every dispatch payload.
- **Bars written at plan time by tech-lead**, not by a new agent or a new stage — the plan stays
  self-contained, and tech-lead already holds both the context and the `Write` grant.
- **Distill-then-delete, not archive.** Keeps the `memory/` ethos without accumulating a `plans/`
  graveyard, and turns merge-reviewer's status flip into a real gate rather than bookkeeping.
- **Lazy directory creation, never eager.** An eager "ensure `memory/` exists" step would litter
  every repo on the machine with empty subdirectories. `setup-project.sh` keeps creating them
  eagerly with `.gitkeep`, because that is the explicit opt-in path.
- **Reviewers stay read-only** — deliberate divergence from Foundry.

---

## Known risks (accepted)

- **Silent CLI failure** is the dominant risk of workstream 1. If the verification rule is wrong,
  writes appear to succeed and land nowhere. Mitigated by the stdout-plus-read-back rule, verified
  through the `Read` tool rather than `Bash`.
- **Write-only artifact** is the dominant risk of workstream 2. The pack has now produced this
  failure **five** times: the session-state file nothing read back, the unreachable Obsidian
  dispatch fixed in `cbf44ca`, the `session-*-unknown.txt` orphans, the `DONE:` ordering bug
  (fixed 2026-07-30), and — caught on paper before shipping — this brief's own unassigned
  plan-commit duty. Mitigated by scoping the first cut to prove enforcement over breadth, and as
  of 2026-07-30 by the mechanical checks, the lint assertion, and the scratch-project exercise.
- **Conditional gate.** `/implement` step 2 skips `tech-lead` for well-scoped single-file tasks, so
  many runs will have no plan at all. merge-reviewer's gate must read "if a plan exists, enforce
  it" — an unconditional gate would block every small change.
- **Weak bars.** A planner writing acceptance criteria may produce unfalsifiable ones, and
  `devils-advocate` — the only agent that would catch that — is itself conditional. Accepted for
  the first cut; the fix if it bites is a bars-specific check in merge-reviewer.
- **Multi-vault misrouting.** Worse than first assessed: a wrong `vault=` does not fail, it
  silently writes to the active vault. Mitigated *only* by reading back the absolute filesystem
  path — passing `vault=` is necessary but proves nothing on its own.
- **`docs/plans/` may collide** with an existing convention in a consuming repo. Mitigated by the
  overridable CONVENTIONS.md key.
- **Verification includes an install step.** Editing agents in this repo changes nothing until
  `install.sh` re-runs — `check-updates.sh` and `/system-check` exist because that drift is real.
  "Proven end-to-end" means edit → `install.sh` → run in a scratch project, not editing files here
  and reading them back.

---

## Reference notes

Ideas evaluated and **not** adopted, recorded so they are not re-litigated:

- **Reviewer findings as plan edits** (Foundry) — rejected; keeps read-only reviewers read-only.
- **Deleting plans outright** (Foundry) — rejected in favour of distill-then-delete.
- **A dedicated exam-sheet stage** (factory diagram step 3) — rejected; tech-lead already holds the
  context, and it avoids a new agent and a new pipeline step.
- **Self-graded proof artifacts** (`auto-loom-proof`, factory step 7) — rejected. An MP4 of the app
  passing its own exam proves nothing if the exam is wrong, while looking like proof. Foundry's
  `quiz` rider — testing the *human's* understanding of merged changes — is the honest version of
  the same instinct and is a candidate for a later cut.
- **Dynamic Workflows for the pipeline** — declined separately on 2026-07-27; see
  `memory/decisions/2026-07-27-decision-decline-dynamic-workflows-for-implement.md`.
