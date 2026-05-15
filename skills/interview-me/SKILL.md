---
name: interview-me
description: "Interview the user about a plan or decision through structured one-at-a-time questioning until reaching consensus. Produces a design brief artifact or hands off when the user signals readiness. Use when an idea is vague and needs shaping before planning or implementation begins. Trigger this when someone says: interview me, help me think through this, I have an idea but I don't know how to approach it, ask me questions about this, what should I be thinking about here. Do NOT use when the task is already well-scoped — use /plan instead."
---

# Interview Me

Shape a vague idea into an actionable brief by settling foundational decisions before branching ones. Silently reads the codebase when work has code implications, and terminates when the user signals readiness or all major branches resolve. Produces an optional design brief that feeds cleanly into `/plan` or `/implement`.

## 1. Open with a single orienting question

Ask exactly one question to understand the type of work:

> "What are we working through — a new feature, an architectural decision, a refactor, or something else?"

Do not ask anything else yet.

## 2. Explore the codebase silently (code-related work only)

If the work type from step 1 involves code (feature, refactor, architectural decision with code implications), read relevant files before forming questions — tech stack, existing patterns, affected modules, related code.

Surface what you found as context, not as questions:

> "I can see you're using a repository pattern with EF Core — I'll factor that in."

Skip this step for non-technical work (process decisions, organizational changes, etc.).

## 3. Ask questions one at a time, in dependency order

Work through decisions in this order:

1. **Goal** — What outcome defines success?
2. **Constraints** — What can't change? (performance, compatibility, deadlines, compliance)
3. **Approach** — How will we get there?
4. **Success criteria** — How will we know it worked?
5. **Risks** — What could go wrong?
6. **Implementation details** — Specifics that depend on the above being settled

For each question:
- State in one sentence why it matters
- Offer a recommended answer with brief reasoning
- Let the user confirm, redirect, or skip

Never ask about a branch that depends on an unresolved upstream decision. Hold it until the dependency resolves.

## 4. Detect the termination signal

Stop asking when **either** condition is met, then route accordingly:

- **(a) User signals readiness** — "let's go", "implement it", "that's enough", "I'm ready" → skip step 5, proceed directly to step 6
- **(b) All branches resolved** — goal, constraints, approach, success criteria, and key risks all have answers → proceed to step 5 to produce the brief

## 5. Produce the artifact (optional)

If the user did NOT signal direct readiness (condition a), write a design brief and present it for approval before writing:

```
## Design Brief: <title>

**Goal:** <what success looks like>
**Constraints:** <what can't change>
**Approach:** <chosen strategy and why>
**Key decisions:**
- <decision>: <rationale>
**Known risks:** <flagged but accepted>
**Open questions:** <anything deferred>
```

Ask: "Does this capture it correctly? Any changes before I write it? I'll write to `docs/<slugified-title>-brief.md` — does that path work, or would you prefer somewhere else?"

Write to the confirmed path after approval.

## 6. Hand off

After the interview (with or without artifact):

- **Approach still ambiguous** → offer `/plan` to decompose with tech-lead
- **Plan clear enough to build** → offer `/implement` with the brief as context
- **User wants to iterate** → loop back to step 3

## Gotchas

- **Passive agreement:** If the user keeps saying "yes" without engaging, slow down — "Any concern with that choice, or are you happy with it?" Uncritical agreement is not consensus.
- **"I don't care" is not a decision:** Offer a concrete default and confirm — "I'd default to X, does that work?" Don't leave the branch open.
- **Don't invoke tech-lead mid-interview:** Discovery must complete before handoff. Calling tech-lead while questions remain open produces a half-baked plan.
- **Don't over-interview:** If all major branches resolve early, don't invent questions to fill space. Terminate and hand off.
