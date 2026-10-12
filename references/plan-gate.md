# Plan gate (merge-reviewer gate 4a and the Deviations tiers)

Read by `merge-reviewer` **only when the invoking skill passed it a `plan_id` and path**, and by
`tech-lead` when it writes `## Calls made for you` (for the checkable-call definition). It is the single
authority on how a bound plan is enforced: the four plan states, the checks on a plan's bars, and the three
tiers that enforce `## Deviations`. It also carries the checkable-call definition that `tech-lead` follows
when it writes `## Calls made for you`, and the Tier 1 grep needle that `scripts/lint-plans.sh` shares. Do not restate any of it elsewhere: a second description is a second thing
to keep in sync, and it will lose.

Gates 1-3c, 4 and 4b, and 5 stay in `merge-reviewer.md`, as does the rule that a plan path is never put into
a shell command.

## 4a. Plan bars (only when a plan governs this run)

Plan consumption is **opt-in per invocation.** You act on a plan only when the invoking skill
passed you a `plan_id` and path. **Never glob a plan directory to find one** — a file sitting in
`docs/plans/` may belong to an entirely different branch's in-flight work, and enforcing an
unrelated plan's bars against this run would produce a confident verdict about the wrong thing.

Resolve which of four states applies, and say which one in your report:

| State | When | Action |
|---|---|---|
| **not applicable** | no `plan_id` was passed | Skip 4a silently. This is the common case — `/implement` skips tech-lead for well-scoped tasks, and `/hotfix`, `/debug`, `/scaffold`, and `/refactor` never pass one at all. |
| **not required** | a skill explicitly signalled that a plan is optional for this run, and none exists | PASS with one sentence saying so. **No skill currently emits this signal** — `/plan` and `/implement` either pass a `plan_id` or pass nothing. The state is kept because it is the honest fourth case and a future skill may need it; if you find yourself here today, say so, because it means a caller sent something unexpected rather than that a plan was optional. |
| **required but missing** | a `plan_id` was passed but no file exists at the given path | **FAIL** — `reason: plan required but not found at <path>`. Do not downgrade this to "no plan, skip"; the caller asserted a plan exists, so its absence is a real failure, not a quiet pass. |
| **stale or unbound** | the file exists but its `plan_id` or `branch` frontmatter does not match this run | **FAIL** — name both the expected and found values. A mismatch means you are holding someone else's plan. |

When a bound plan is present, check its bars — **using the `Grep` and `Read` tools, never `Bash`.**

> **Never interpolate the plan path into a shell command.** Use `Grep` with the path as its
> `path` parameter, and `Read` for the frontmatter. This is not a style preference. The path
> derives from a `docs/CONVENTIONS.md` value controlled by whatever repository you are running in,
> and Bash's double quotes suppress word-splitting and globbing but **do not** suppress command
> substitution. A directory named `docs/plans/$(...)` or containing a backtick is a legal path on
> both NTFS and POSIX, would be created without complaint by the agent that writes the plan (no
> shell is involved in a `Write`), and would then **execute** when spliced into `plan="…"` here —
> under your `Bash` grant, which also runs `git merge`, `git add -A`, `git commit`, and branch and
> worktree deletion. Passing the path as a structured tool parameter removes that entire class of
> risk rather than trying to sanitise around it.

- `Read` the plan file and confirm its `plan_id` and `branch` frontmatter match this run.
- `Grep` for `^- BAR-` with `output_mode: "count"` — the number of bars.
- `Grep` for `^  Evidence:` with `output_mode: "count"` — the number carrying evidence.

- **An amended bar needs a deviation entry behind it.** A bar may legitimately be rewritten when a
  recorded deviation falsified its premise — otherwise it tests an abandoned design. But the
  amendment must be traceable: a `## Deviations` entry naming that bar id and quoting its original
  wording. If a bar's text plainly describes the shipped state where the plan's calls describe
  something else, and no deviation entry accounts for it, treat it as **FAIL**,
  `reason: bar amended without a recorded deviation`. That is retconning with extra steps, and it is
  the one path by which "unsatisfiable" becomes cheaper to fix by rewriting the bar than by fixing
  the code.
- **A plan with zero bars is a FAIL**, not a pass. If the `^- BAR-` count is `0`, or the plan
  has no `## Acceptance bars` section at all, report
  `reason: plan has no acceptance bars` and fail. Do not reason "no bars, nothing to check" —
  a bar-less plan is an empty gate that reports success, which is worse than no gate.
- **Every bar must have exactly one `Evidence:` line, and it must be that bar's own.** Equal counts
  are necessary but **not sufficient**: three bars and three evidence lines pass a count comparison
  even when one bar has two stacked beneath it and the next has none. So do both checks:
  - **Counts:** bars exceeding evidence means at least one bar is unsupported (**FAIL**, naming the
    ids); evidence exceeding bars means a duplicated or orphaned evidence line (**FAIL**, say
    which).
  - **Pairing:** you already `Read` the file for the `plan_id`/`branch` check — while you have it,
    confirm each `- BAR-nnn` line is *immediately followed* by its own `Evidence:` line. A bar
    separated from its evidence by another bar, a blank line, or a second evidence line is a
    **FAIL** regardless of what the totals say. Counting is the cheap screen; reading is the
    actual check.
  Before concluding a bar lacks evidence, check the indentation: the `Evidence:` line must be
  indented exactly two spaces. A four-space indent or a tab produces an evidence count of zero on
  a plan that is otherwise fine, so report that as a malformed plan rather than as unsupported
  bars — the distinction tells the author what to actually fix.
- **Cross-check against test-engineer's handoff.** Its `Acceptance bars` mapping reports what
  evidence actually satisfies each id. Any bar it reported as `NONE` is a **FAIL**, and any bar id
  in the plan absent from its mapping is a **FAIL** — a bar nobody assessed is not a bar that
  passed.
- `manual` and `files` evidence are **as valid as `tests`.** Work with no test surface — prompt
  files, documentation, shell scripts — is fully satisfied by a concrete file reference or a
  repeatable command. Do not treat the absence of a test as a failure when the bar never called
  for one.
- If evidence cites test files, confirm they appear in the **Step 0c branch scope** file list. Do
  not re-derive scope here and do not inspect a single commit — see the branch-scope note in
  Step 0c.

**Judgment, not mechanism.** Whether the evidence genuinely establishes the bar is your call, the
same class of judgment as "Critical findings resolved." Be honest when you cannot tell: report the
bar as unverifiable and FAIL it rather than passing it to avoid a hard call.

## Deviations — three tiers, cheapest and most certain first

The plan's narrative half records design calls made on the human's behalf. When the implementation
overrides one, that override must be recorded in `## Deviations` — otherwise the plan ships
alongside code it contradicts, and "a reviewer reads intended shape against implementation" becomes
a claim nothing backs.

**Tier 1 — the section itself (mechanical).** Two greps, in this order. **Absence of the sentinel is
not sufficient** — a plan with no `## Deviations` section at all also has no sentinel, and treating
that as a pass is the exact hole this tier exists to close.

1. `Grep` the plan for `^## Deviations`.
   - **No match → FAIL**, `reason: plan has no Deviations section`. The plan is malformed, the same
     class as a plan with no `## Acceptance bars`. tech-lead is required to emit the section; its
     absence means the plan was written against an older template or the section was deleted.
     Route to the coordinating session, and say the plan needs the section added — not that
     nothing diverged.
2. `Grep` the plan for `Deviations not yet reviewed`.
   - **Match → FAIL**, `reason: plan deviations section not reviewed`. The coordinating session was
     required to replace that sentinel line at step 10 with either `None.` or a list. Its presence
     means the step did not run.
   - **No match, and the section has content → continue.** Confirm the section is genuinely
     non-empty while you are reading the plan: a heading followed by nothing is the third form of
     the same failure, and it is why the template ships a sentinel rather than a blank section.

Three states, three different verdicts. Do not collapse them: *nothing diverged*, *nobody checked*,
and *no section exists* look alike only if you check for one of them. A missing sentinel replacement
is a process failure even when the code is perfect.

**Tier 2 — engineer claims (near-mechanical).** The step 10 payload includes each engineer's
`Departures from stated calls:` line.

- Any departure an engineer reported that does **not** appear in `## Deviations` → **FAIL**,
  naming the departure and the engineer. Someone surfaced a divergence and it was dropped on the
  way to the record.
- An engineer that reported `none`, and a `## Deviations` reading `None.` → consistent, continue.

**Tier 3 — stated calls against the diff (judgment, tightly bounded).**

Work **from the calls, never from the diff.** Read each entry in `## Calls made for you`, extract
the concrete artifact it names, and look only for that. **Do not scan the diff hunting for
surprises** — that is unbounded, and it is how this check would start crying wolf.

**This is the single authority on what counts as a checkable call.** Do not restate the lists below
in another file; point at this section instead.

A call is **checkable** when it names one thing you can look up:

- a named dependency, library, tool, or runner
- a named file or directory path
- a named type, function, or endpoint
- a specific numeric or enumerated value
- an explicit will/won't about one of the above

**Permanently out of scope**, because none of these yields a lookup target: adjectives and quality
claims ("keep it maintainable", "prefer clarity"), effort estimates, motivations, risk narration,
sequencing intent — and **pattern names**.

Pattern names are the exception worth explaining, because they look checkable and are not. "Use the
repository pattern for data access" names a *pattern*, not an artifact: there is no single thing to
look up, and whether a given `DbContext` reference violates it is an architecture judgment with
legitimate readings on both sides — a read-only projection, a bulk operation, a half-finished
refactor. **That judgment already has an owner, and it is not you.** `code-reviewer` reads
`docs/CONVENTIONS.md` and reviews pattern compliance, `smell-reviewer` catches the structural form,
both run earlier, and a code-reviewer Critical already blocks. Adjudicating it again here would be a
second and worse ruling on a question answered upstream — made by the only agent holding `Bash` and
the commit.

The same intent written falsifiably *is* in scope, and the difference is entirely in the writing:

> "All order data access goes through `IOrderRepository`. No `DbContext` reference outside
> `Infrastructure/Repositories/`."

That names a type and a directory boundary, so it can be looked up and contradicted.

Your question is narrower than "was the architecture right." It is **"did the plan's record stay
honest?"** Conflating the two is how this check learns to wave everything through, which is worse
than not existing because it still looks like enforcement.

Say which calls you checked and which had no lookup target.

**A Tier-3 FAIL requires quoting both sides.** You may only fail when you can produce all three:

1. the stated call, **verbatim**;
2. a specific `file:line` within **Step 0c's branch scope** — or a specific named artifact provably
   absent from it — that contradicts the call;
3. one sentence on why both cannot be true.

Missing any of the three, emit an **advisory in the PASS report** instead, phrased as a question
for the human. Never fail on a suspicion you cannot show.

**Ambiguity advises; it does not fail.** This deliberately inverts the rule for bars above, where
you are told to FAIL when you cannot tell. The inversion is intentional and the reason matters: an
unverifiable **bar** means verification did not happen, which is the thing this gate exists to
establish. An ambiguous **narrative call** means the plan was written imprecisely — a defect
belonging to tech-lead, several stages back, in a file the coordinating session can no longer
usefully change. Failing there punishes the wrong party, and a gate that fails on someone else's
imprecision gets switched off within a week.

**State the remedy in the finding.** A Tier-3 FAIL is corrected by **one line in `## Deviations`**,
not by changing code — say so in the finding text. The override may well have been the right call;
what is missing is the record of it. A gate whose cheapest correct response is "record it" induces
the behaviour this check wants. One whose cheapest response is "argue with the reviewer" gets
disabled.

Read the plan with `Read` and `Grep` only. The "never interpolate the plan path into a shell
command" rule above applies here unchanged — only branch-scope `git` commands use `Bash`, and you
reuse Step 0c's file list rather than re-deriving it.

**The plan file itself is committed and kept.** You do not flip a status field, and you do not
delete it. It stays in the tree as the record of what the change intended, reviewable in the PR
against the implementation beside it.
