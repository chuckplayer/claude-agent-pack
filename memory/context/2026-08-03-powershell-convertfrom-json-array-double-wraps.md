---
date: 2026-08-03
type: context
status: active
superseded-by: n/a
scope: any PowerShell 5.1 script parsing JSON from a CLI
overrides-convention: no
related-to: n/a
discovered: 2026-08-03
---

# `@($json | ConvertFrom-Json)` double-wraps an array on PowerShell 5.1

On Windows PowerShell 5.1, `ConvertFrom-Json` emits a JSON array as **one pipeline object** rather
than unrolling it. Wrapping that in the array subexpression operator therefore produces a
**one-element array whose single element is the whole `Object[]`**:

```powershell
$raw = Get-Content items.json -Raw     # a 4-element JSON array

$a = $raw | ConvertFrom-Json           # Object[], Count = 4   <-- correct
$b = ConvertFrom-Json -InputObject $raw # Object[], Count = 4   <-- correct
$c = @($raw | ConvertFrom-Json)        # Count = 1, $c[0] is Object[]   <-- WRONG
```

**Why it is dangerous rather than merely wrong.** The idiom `@(...)` is the normal defensive way to
guarantee an array when a result might be a single object, so it is exactly what a careful author
reaches for. It fails silently and *plausibly*: iterating `$c` yields one item, and reading a field
off it returns an **array of that field across every row**. Downstream comparisons then compare a
scalar against an array, which stringifies to things like `System.Object[]` or a space-joined list of
every value, and the code reports confident nonsense instead of erroring.

Observed cost: a reconciliation pass over Azure DevOps work items reported three spurious
"different id" stops and a bogus type divergence on every row, because each row's id had become the
list of all four ids.

**Workaround** — assign directly, then normalize the single-object case explicitly:

```powershell
$parsed = ConvertFrom-Json -InputObject $raw
$rows = if ($parsed -is [System.Array]) { $parsed } else { ,$parsed }
```

Note `,$parsed` (the unary comma), not `@($parsed)` — the latter reintroduces the bug.

**Related:** [[2026-07-30-powershell-mangles-native-exe-arguments]] is the same class of hazard — a
PowerShell layer silently producing a wrong value rather than an error, where the failure looks like
a result.
