# Pack development rules (this repository only)

These are the gates for changing **this pack itself**. They are not shipped by `install.sh` and not
copied into a consuming project by `setup-project.sh`: a consuming project has none of these scripts,
so the rules are meaningless there. They used to sit in `CLAUDE.md` and were loaded into every
dispatch; they now live here and `CLAUDE.md`'s "This repository" section carries only the short
trigger for each.

- **`scripts/lint-agents.sh`** whenever the changeset touches `agents/`, `skills/`, `references/`,
  `CLAUDE.md` or `docs/CLAUDE.template.md`, after the files are written and before code-reviewer.
  **Blocking on non-zero exit** -- exit **1** is a finding and exit **2** means the linter's own
  self-test failed, which is also a FAIL -- same footing as ts-linter, and
  enforced by merge-reviewer's gate 2a. `references/` is on the list because an agent or skill reaches
  a reference only through a pointer, so a rename or deletion that touches nothing else would skip the
  check that finds the now-dangling pointer. Run the script directly rather than invoking the
  `/lint-agents` skill -- that skill is for manual runs; this is orchestration. A malformed
  `description` **is** the routing contract, so a file that fails this check may be undispatchable no
  matter how sound its body is, which makes a downstream code-reviewer PASS meaningless. The gate
  exists because a skill description shipped 322 characters over the limit through four review stages
  and a merge gate into two pushed commits, while the one-command check that catches it went unrun.
- **`node scripts/obsidian-stop-hook.test.js`** whenever the changeset touches
  `scripts/obsidian-stop-hook.js` or `scripts/obsidian-context-hook.js`, after the files are written
  and before code-reviewer. **Blocking on non-zero exit**, same footing as `lint-agents.sh`, and
  enforced by merge-reviewer's gate 2b. Node stdlib only -- no npm install, so there is no setup step
  whose absence could excuse a skip. **The trigger is those two filenames, not the `scripts/`
  directory:** the suite imports the stop hook and drives the context hook as a subprocess, and covers
  neither the three other `obsidian-*.js` hooks nor any `.sh` script beside them. This gate exists
  because 131 passing tests went un-invoked by any pipeline until 2026-08-03, several of them named as
  regressions for bugs already fixed once -- found by auditing `scripts/` for other unrun checks after
  the `lint-agents.sh` gate above was added, which is the same failure arriving a second time.
- **`scripts/lint-identifiers.sh`** on **every** changeset, after the files are written and before
  code-reviewer. **Blocking on non-zero exit**, same footing as `lint-agents.sh`, and enforced by
  merge-reviewer's gate 2c. **This repository is public.** The script fails when a real organisation,
  project, host, user path, or email appears where the placeholder convention requires a placeholder —
  see `memory/context/2026-08-04-this-repo-is-public-never-write-real-identifiers.md` for the
  convention and the exact placeholder tokens.

  **Unlike the other two script gates, the trigger is every changeset, not a path.** An identifier can
  be introduced by any file in any commit, so there is no narrower trigger that would be honest — and
  therefore **no legitimate skip**. If it is not run, say so; do not imply it passed.

  Three properties worth knowing before editing it. It ships **no denylist**, because a list of the
  forbidden strings would have to contain them in a public repo; exact-token matching comes from a
  **gitignored** `.identifier-denylist` if present. It **self-tests before scanning** and exits **2**
  (distinct from a finding's exit 1) if any rule fails to fire on a violating fixture or fires on a
  compliant one — a checker that matches nothing otherwise reports a clean repo. And its greps treat
  **exit ≥2 as an error rather than "no matches"**, because `grep -iF` aborts on this machine and the
  first draft swallowed that and printed a pass while core-dumping.

  This gate exists because the rule already existed and nothing enforced it:
  `docs/azure-devops-github-skills-brief.md` forbade hardcoded org names four lines above a list of
  them, and a scrub of 115 references then required rewriting all 172 commits — which **still does not
  remove them from a public host.** Prevention is the only control that works.
- **`scripts/lint-memory.sh`** whenever the changeset touches `memory/`, after the files are written
  and before code-reviewer. **Blocking on non-zero exit** for the coordinating session, on the
  `lint-plans.sh` model — and unlike the three script checks above, **no merge-reviewer gate enforces
  it.** There is no gate 2d. The session that touched `memory/` is the only thing that runs it, so an
  unrun check here is simply unrun; say so rather than implying it passed.

  It checks **dialect conformance only** against `docs/MEMORY-WRITING.md`: the `---` fence on line 1,
  lowercase hyphenated keys, and the presence of the seven required keys (`date`, `type`, `status`,
  `superseded-by`, `scope`, `overrides-convention`, `related-to`). It does **not** close the `type:`
  value vocabulary, does **not** require `description:`, does **not** reject an unrecognised key — the
  key set is a minimum, and extra keys such as `discovered:` are sanctioned — and does **not** check
  that `superseded-by:` resolves to a real file, because two files legitimately carry prose there.

  Like `lint-identifiers.sh` it **self-tests before scanning** and exits **2** (distinct from a
  finding's exit 1) if any rule fails to fire on a violating fixture or fires on a compliant one. It
  **passes on an empty corpus**, so a freshly scaffolded project is not born failing, and it is
  `not applicable` when the script is absent rather than a failure.

## When NOT to run each gate

- **`scripts/lint-agents.sh`** when the changeset touches none of `agents/`, `skills/`, `references/`,
  `CLAUDE.md` or `docs/CLAUDE.template.md`. It validates frontmatter and body in the first two trees,
  and pointer resolution (R1) and token spelling (R4) in all five paths, and has nothing to say about any other file —
  running it elsewhere produces a PASS that means nothing was checked. Say the skip out loud rather
  than leaving it ambiguous with a genuine skip-because-clean
- **`node scripts/obsidian-stop-hook.test.js`** when the changeset touches neither
  `scripts/obsidian-stop-hook.js` nor `scripts/obsidian-context-hook.js` — including changesets that
  touch **other** files in `scripts/`, which is the near-miss worth stating explicitly. A change to
  `check-updates.sh`, `set-env.sh`, or one of the three uncovered `obsidian-*.js` hooks gets a clean
  run out of this suite while nothing in the changeset was exercised, and that reads in a merge record
  as coverage. Same reason as `lint-agents.sh` above: a PASS on an unrelated changeset is worse than
  an acknowledged skip
- **`scripts/lint-memory.sh`** when the changeset does not touch `memory/`. It reads only
  `memory/**/*.md` frontmatter and has nothing to say about any other file, so a run on an unrelated
  changeset reports a clean corpus while checking nothing the changeset touched — the same
  false-coverage shape as the two entries above. Also skip it, as `not applicable`, when the script is
  absent from the project: it is newer than some checkouts, and a missing checker is a stated gap, not
  a failure and not a pass

