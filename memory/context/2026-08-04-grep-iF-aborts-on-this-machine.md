**Date:** 2026-08-04
**Type:** constraint
**Status:** active
**Superseded-by:** n/a
**Scope:** global — any shell script or one-off command in this repo on this machine
**Overrides-convention:** no
**Related-to:** 2026-07-30-powershell-mangles-native-exe-arguments.md, 2026-07-10-bash-tool-silent-failure-windows.md, 2026-08-04-this-repo-is-public-never-write-real-identifiers.md

## Summary

**`grep -i` combined with `-F` ABORTS on this machine.** GNU grep 3.0 under Git Bash, SIGABRT,
**exit 134**, no output, and it drops a `grep.exe.stackdump` in the working directory. Discovered
2026-08-04 while building `scripts/lint-identifiers.sh`.

**The trigger is the `-i` + `-F` combination, not `-i` alone.** This matters, because the first
diagnosis was "`grep -i` is broken", which is wrong and would have condemned working code:

| invocation | result |
|---|---|
| `grep -iF`, `grep -inF`, `grep -iwF`, `grep -inwF`, `-iF` on stdin | **exit 134, abort** |
| `grep -i`, `grep -in`, `grep -iw` | works |
| `grep -nwF`, `grep -nw` | works |
| `grep -i` under `LC_ALL=C` | works |

So `scripts/lint-plans.sh`'s `grep -qi` was never at risk — no `-F`. Only the `-F` pairing is affected.

## Why it is dangerous rather than merely annoying

**Exit 134 with empty output is indistinguishable from "no matches" to any caller that writes
`|| true`.** The first draft of `lint-identifiers.sh` did exactly that and printed
**`[ok] denylist`** while the grep was core-dumping. The check reported success *because its own
mechanism died* — the same failure class as `az boards query --wiql` returning blank with exit 0, and
as `az devops invoke` serving a sibling route.

## Workaround

- **Never pair `-i` with `-F`.** If literal matching is required — and it is for any denylist, since
  entries containing `.` or `*` must not be reinterpreted as regexes — then **drop `-i`** and list case
  variants explicitly. `-F` is the flag worth keeping.
- **Treat grep's exit code with three branches, never two.** `0` = matched, `1` = no match, `>=2` =
  **error**. A `|| true` collapses all three into "clean". `lint-identifiers.sh` carries a
  `grep_strict` helper that exits 2 on `rc >= 2` rather than reporting a clean scan.
- **Have the script prove its own grep runs before trusting it.** That script's self-test executes the
  exact denylist invocation against a fixture and fails loudly if it aborts — a *mechanism* check
  distinct from its rule checks.
- If a case-insensitive literal search is genuinely needed, `LC_ALL=C grep -iF` is worth testing, or
  use `grep -i` with the pattern regex-escaped instead of `-F`.

**Same lesson as the two related files: on this machine, an unexpected negative means suspect the
invocation before the subject.** A `grep.exe.stackdump` appearing in the tree is the tell.
