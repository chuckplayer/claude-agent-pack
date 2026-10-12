# Plan directory guard

The conditions under which a directory value must be **rejected** before it becomes a filesystem path. It is
applied by `tech-lead` before it creates or edits a plan file -- to whatever value it ends up with, whether it
resolved the value itself or was handed it -- and by any skill or agent that resolves a plan or spec
directory itself.

**This file holds the rejection conditions and nothing else.** How the value is resolved and what to fall back
to are the caller's: `tech-lead` falls back to `docs/plans`, the spec skills to `docs/specs`. A condition added
here applies to every caller, which is why the table is kept in one place and cited, never copied.

| Reject when the value | Because |
|---|---|
| is empty or missing | nothing to write against |
| starts with `[` | it is an unfilled template placeholder like `[e.g., docs/plans/]`. `docs/CONVENTIONS.template.md` ships this key as a placeholder, so every freshly-onboarded project has it unfilled until someone edits it — and `[` is a legal filename character, so an unguarded value silently creates a directory named `[e.g., docs` |
| is an absolute path | your `Write` tool creates missing parent directories, so an absolute path writes outside the repo entirely |
| contains `..` | same reason — path traversal out of the repo. The check is a literal `..` substring, so it catches both `../` and `..\` |
| starts with `\\` | a UNC path (`\\server\share\…`). It has no drive letter, so "is it absolute" is easy to answer wrongly — reject the form explicitly |
| has a `:` as its second character | catches every drive-prefixed form in one check — `C:\foo` (absolute), `C:foo` (*drive-relative*, resolving against that drive's current working directory rather than the repo), and bare `C:`. Do not try to decide which of those is "absolute"; a second-character colon is never valid in a repo-relative path, so reject the whole shape |
| contains `` ` ``, `$`, `;`, `\|`, `&`, `<`, `>`, or a newline | shell metacharacters. Nothing here runs a shell, but a later stage reads this path, and a directory named `$(…)` is a legal path that becomes a command when interpolated. Refuse to create the hazard |

**Know the limit of this guard.** It inspects a *string*. It cannot detect that an otherwise
lexically perfect `docs/plans` is a symlink or NTFS junction pointing outside the repo — that would
require resolving the real filesystem target. Treat the guard as defence against a misconfigured or
careless value, not as a guarantee against a repository that already contains a hostile reparse
point. If the resolved directory already exists and you have reason to doubt it, say so rather than
writing into it.
