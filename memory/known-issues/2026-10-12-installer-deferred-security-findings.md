---
date: 2026-10-12
type: known-issue
status: active
superseded-by: n/a
scope: install.sh, uninstall.sh, scripts/set-env.sh, scripts/lib/pack-common.sh, scripts/lint-agents.sh
overrides-convention: no
related-to: n/a
discovered: 2026-10-12
---

# Installer and linter findings reviewed and deliberately left open

The scope-aware installer and the pointer linter went through five security review rounds. The Critical
and High findings and the first-round BLOCK were fixed. These were reviewed, judged advisory or
pre-existing, and **left open on purpose** so they are not rediscovered as new.

**Pre-existing at the base commit, not introduced by that work:**

- `scripts/set-env.sh` accepts any `KEY=VALUE`. A prompt-injected key such as `NODE_OPTIONS`, `LD_PRELOAD`,
  `BASH_ENV` or `ANTHROPIC_BASE_URL` would persist into `~/.claude/settings.json`'s `env` and apply to every
  later session. The only documented callers need four keys (a GitHub org, repos, an Azure DevOps org,
  projects), so an allowlist is the obvious fix. Needs its own change.
- The Obsidian REST API key is passed to python and node on argv, visible in `ps` and `/proc/*/cmdline`.
- Retired-name removal deletes whole directories named `challenge`, `wiki`, `check-updates` and so on
  from `~/.claude/skills/` with no ownership check, prompt or backup.
- The installer adds `Bash(echo *session-decisions*)` to `permissions.allow`. Whether the wildcard also
  approves an echo with a redirect to another file was not verified.

**Introduced with the rewrite, judged Low:**

- With no resolvable home directory, the Python settings writer's `expanduser` returns `~/.claude/...`
  unchanged and creates `./~/.claude/settings.json` under the current directory (inside a repo, if run
  from one). Node throws instead.
- The Node writer does not check for a short write and neither runtime calls `fsync` before the rename.
- A dangling `settings.json` symlink behaves differently in Python (writes the target) and Node (replaces
  the link).
- `.bak` replacement is `rm -f` then `cp`, not atomic. The `.bak` still holds the old settings, API key
  included; uninstall now says so.
- Output sanitisers strip C0 controls only. C1 controls (U+0080-U+009F) and bidi overrides pass through.
- `lint-agents.sh` matches `SKILL.md` and `*.md` case-sensitively, so `skill.md` on a case-insensitive
  filesystem is not linted. A non-`.md` file under `skills/` that contains the token passes the linter and
  fails closed at install instead.
- `lint-agents.sh` is about 2,150 lines (204 at base) and runs in roughly 53 s. Most of the time is the
  old per-file frontmatter code (about 25 forks per file), not the new machinery. A single awk pass per
  file is the deferred fix and the self-test already guards the behaviours a rewrite could lose.

Not a finding, but design debt: `install.sh` and `scripts/lib/pack-common.sh` exceed the default size
thresholds. The settings writers share one python and one node function via `pack_py`/`pack_node`; moving
them to real `.py`/`.js` files with an op dispatcher, and splitting the library along its section headers,
was proposed and deferred.
