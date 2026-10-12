---
date: 2026-10-12
type: known-issue
status: active
superseded-by: n/a
scope: install.sh, uninstall.sh, scripts/set-env.sh, scripts/lib/pack-common.sh, and any test that redirects HOME
overrides-convention: no
related-to: n/a
discovered: 2026-10-12
---

# A temp-HOME test must also redirect USERPROFILE, or it rewrites the real settings.json

The settings code resolves the user's home directory through Python's `os.path.expanduser` and Node's
`os.homedir()`. **On Windows both read `USERPROFILE`, not `HOME`.** A test that sets only `HOME` to a
scratch directory therefore leaves every `~/.claude/settings.json` write pointing at the real file, while
the bash half of the same script (which reads `HOME`) looks at the scratch one. The two halves disagree
silently, and the real settings file is rewritten.

Found while building the scope-aware installer: the engineers' harness refused `HOME` redirects outright,
which is why the user-scope install/uninstall round trip was never run during Phase 1. The one place a
scratch home was used (a Python-only `set-env.sh` case) set `USERPROFILE`, and first proved
`expanduser` resolved into the scratch directory before running.

Workaround: redirect both `HOME` and `USERPROFILE`, and before running anything that writes, assert that
`python -I -c "import os; print(os.path.expanduser('~'))"` resolves inside the scratch directory (compare
with `-ef`, not string equality, because Git Bash's `/tmp` is an alias for the Windows Temp directory).
Refuse to run if it does not.

Also unverified in Phase 1, so any future test author inherits the gap: the real user-scope round trip,
interactive prompts, and real symlinks/junctions (Git Bash `ln -s` copies instead of linking on a
machine without developer mode; the symlink guards were exercised through stubs only).
