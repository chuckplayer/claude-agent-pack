---
date: 2026-08-03
type: known-issue
status: active
superseded-by: n/a
scope: skills/devops-azure/SKILL.md
overrides-convention: no
related-to: n/a
discovered: 2026-08-03
---

# `workitemtypes` lists work item types that are BLOCKED for creation, and the process template's name predicts nothing

Verified against `<org>/<project-a>` on 2026-08-03 while executing `BAR-015`.

`az devops invoke --area wit --resource workitemtypes` returned 17 types for the project, including
**both** `Product Backlog Item` and `User Story`. Creating against `Product Backlog Item` failed:

```
ERROR: VS403074: Work item creation or migration to the target work item type
'Product Backlog Item' is blocked. Enable the work item type to unblock the operations.
```

The response carries **no `isDisabled` field**, so the blocked state is not discoverable from the
type list at all.

**The template name is actively misleading.** `<project-a>`'s process is named **"<project-a> Scrum"**, and the
Scrum-native backlog type is the one that is blocked while the Agile-template type (`User Story`) is
the one in use. Inferring the mapping from the template name is what produced the failure — a
reasonable-looking inference that a project's own configuration contradicts.

**Cheap check that does work, and costs no write.** Group `[System.WorkItemType]` over the project's
existing items:

```bash
az boards query --wiql "SELECT [System.Id], [System.WorkItemType] FROM WorkItems WHERE [System.TeamProject] = '<project>'" --org https://dev.azure.com/<org> --output json
```

`<project-a>`'s 113 items came back as Task 96, User Story 15, Feature 2, Epic 1 — **zero** Product Backlog
Items, which is the signal the type list could not give. A type with existing items is demonstrably
creatable.

**Evidence, not proof.** A brand-new project has no items at all, and a legitimately unused type is
not necessarily blocked. Treat a zero-count candidate in an otherwise-populated project as a reason
to prefer another candidate or ask the operator — not as a verdict.

**Workaround:** `skills/devops-azure/SKILL.md` section 8c now runs the in-use type query alongside
`workitemtypes` and treats the latter as a *candidate* list; section 8f carries `VS403074` as its own
stop row, distinct from both "invalid type" and "insufficient permissions", because the type is valid
and the grant is present. A blocked type reached at create time forces a re-preview under a new
mapping per 8e's in-band-override rule.

**Related:** [[2026-08-03-wiql-tags-contains-is-whole-tag-not-substring]] came from the same bar, and
both were found by *executing* a bar after review passes had read the behaviour wrongly from prose.
