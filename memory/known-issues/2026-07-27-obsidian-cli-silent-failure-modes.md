---
date: 2026-07-27
type: known-issue
status: active
superseded-by: n/a
scope: n/a
overrides-convention: no
related-to: n/a
discovered: 2026-07-27
description: The official Obsidian CLI returns exit 0 on every error, silently ignores an unrecognized vault= argument and writes to the active vault instead, and creates a 0-byte file when content= is large while still reporting Created -- so neither exit codes, vault targeting, nor success messages can be trusted
---

The official Obsidian CLI (https://obsidian.md/cli, bundled with the desktop app and enabled
in Settings → General) has two independent silent-failure modes. Both were confirmed by direct
probe on 2026-07-27 against Obsidian's Windows build dated 2026-03-23.

## Symptom 1: every error returns exit 0

```
$ Obsidian.com notacommand
Error: Command "notacommand" not found. It may require a plugin to be enabled.
$ echo $?
0
```

Same for a missing file (`Error: File "..." not found.`) and for a path-traversal attempt
(`read path="../../../Windows/System32/drivers/etc/hosts"` → `Error: File ... not found.`).
Errors go to **stdout**, not stderr, and the exit code is 0 in every case.

Consequence: `if ! obsidian ...` never fires. Any shell-conditional fallback chain built on
exit status silently believes every call succeeded. This is the same class of defect as
[[2026-07-10-bash-tool-silent-failure-windows]], and it compounds with it — the CLI is invoked
*through* Bash, so on this machine a failure can be swallowed twice.

## Symptom 2: an unrecognized `vault=` is silently ignored

This is the more dangerous of the two.

```
$ Obsidian.com append vault="NoSuchVault" path="Claude/probe.md" content="\n- x" inline
Appended to: Claude/probe.md
```

There is no such vault. The CLI reported success and wrote the line into the **active** vault's
`Claude/probe.md` instead. Verified by grepping the real vault afterwards: the line was there.

Consequence: `vault=` is a hint, not a guarantee, and passing it correctly protects nothing.
A typo, a renamed vault, or a stale `OBSIDIAN_VAULT_PATH` basename does not fail — it silently
writes to whichever vault happens to be active. For a multi-vault user this means notes land in
the wrong vault with a success message.

## Symptom 3: large `content=` writes a 0-byte file and reports `Created`

Observed live on 2026-07-30, not by probe — during a real capture of a ~23 KB memory file.

```
$ Obsidian.com create path="Claude/captures/2026-07-30-1056.md" content="<~23KB>"
Created: Claude/captures/2026-07-30-1056.md
```

The file was created and was **0 bytes**. Success prefix present, exit 0, no error text, no
content. The write was retried on the REST API rung and succeeded (HTTP 204, 23,807 bytes
verified on disk), so nothing was lost.

Root cause is content passed through a command-line argument: the payload exceeds what argv can
carry, and the CLI neither errors nor truncates visibly — it creates the file and writes nothing.
No exact threshold has been established. Do not assume one; assume any multi-kilobyte `content=`
may do this.

**This is the first live confirmation that the verification rule below earns its place.** Both
halves were required: the stdout prefix check passed (`Created:` was printed), and only the
filesystem read-back caught the emptiness. A chain trusting either signal alone would have
recorded a successful capture of an empty file — the write-only failure mode, arriving through the
one transport that reports success unconditionally.

Note the interaction with symptom 2's remediation: a 0-byte file is indistinguishable at a glance
from a misroute, and both are detected by the same read-back. Treat an empty read-back as
"unverified" and fall through, whatever the cause.

## Workaround

**Verify the effect, never the exit code, and verify on the filesystem, never through the CLI.**

A CLI write counts as successful only when both hold:

1. stdout begins with the operation's success prefix (`Appended to:` for `append`) — a positive
   check, not merely the absence of `Error:`
2. reading the **absolute filesystem path** with the `Read` tool shows the expected content

Step 2 is what catches vault misrouting, and it only works against the absolute path derived from
`OBSIDIAN_VAULT_PATH`. Using the CLI's own `read path=` would read from the same wrong vault and
confirm a bad write. Using Bash (`cat`, `grep`) would route the check back through the channel
that fails silently on this machine.

If either check fails, fall through to the next transport. A failed CLI call is safe to retry
this way: `append` against a missing file errors and creates nothing, so there is no
partial-write state to clean up.

**Two further mitigations for symptom 2, added after security review:**

1. **Never pass `overwrite` to `create`.** A misrouted write with `overwrite` would clobber an
   unrelated note in whatever vault is active — data loss, not merely disclosure. Without it, a
   misrouted create fails harmlessly when the target already exists. The cost is that an
   intentional overwrite (the dated recap file) cannot use the CLI and must fall through to the
   REST API's `PUT` or a filesystem `Write`.
2. **Remediate a detected misroute.** When stdout says success but read-back of the absolute path
   fails, the content landed in another vault — potentially personal, unrelated, or cloud-synced,
   and containing a full capture body or recap. Delete the stray copy
   (`delete path="<rel>" permanent`), continue down the chain so the content still reaches the
   intended vault, and warn prominently in the return summary. Deleting is safe *only* because
   `overwrite` is never used, so the stray file is known to be new rather than a clobbered
   original.

Treat a misroute as a **data-disclosure event**. The earlier framing of it as an unavoidable
"stray line" understated it in two ways: extending the chain to cover file creation means a whole
document can be misrouted rather than one line, and no remediation existed.

**Revisit trigger:** an Obsidian release note stating that the CLI returns nonzero exit codes on
error, or that an unrecognized `vault=` is rejected rather than ignored. Re-test with the two
commands quoted above. Until then, do not simplify the verification step — it is not defensive
padding, it is the only signal available.

## Other confirmed behaviors (not defects, but needed to use it correctly)

- `append` on a file that does not exist fails and creates nothing. Create the file first by
  another route, then append.
- Default `append` inserts a **blank line** before the content, turning a tight markdown list
  into a loose one (visibly different rendering). Use the `inline` flag with a leading `\n` in
  `content=` to get exactly one newline.
- `\n` and `\t` escapes are honoured inside `content=`. UTF-8 (em dashes, etc.) survives intact.
- The desktop app must be running. If it is not, calls error — which the verification above
  catches, so no separate preflight is needed.
