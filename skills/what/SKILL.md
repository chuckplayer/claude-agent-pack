---
name: what
description: "Restate the immediately preceding assistant message in ASD-STE100 Simplified Technical English, keeping the domain's own vocabulary as approved Technical Names. Use when a reply was accurate but hard to read — dense, hedged, idiomatic, or pitched at a specialist. Every fact, qualifier, negation, count, identifier and refusal survives verbatim: a status word such as NOT RUN or unverified is a Technical Name and is never simplified away. Trigger this when someone says: what, say that in plain English, simplify that, restate that, what did you just say, put that in STE. Do NOT use to summarise or shorten — STE output is normally longer than its source. Do NOT use to translate domain terms into everyday words. Do NOT use on any message except the last one."
---

# What

Restate **one message** — the assistant's immediately preceding reply — in ASD-STE100 Simplified
Technical English, using the domain's own terms as approved Technical Names.

**This skill adds nothing and removes nothing.** It changes register only. It is not a summary, not an
explanation, and not a second answer. If the restatement would be improved by new information, that
information belongs in a new reply, not in this one.

## 1. Resolve the target

The target is **the assistant's last message in this conversation** — the one directly above the
invocation. Not a file, not a selection, not the whole thing so far.

| Condition | Action |
|---|---|
| No preceding assistant message | Stop and say so. Never restate the user's own message instead |
| The preceding message was itself a `/what` output | Stop and say so. A second pass compounds loss and gains nothing |
| The preceding message is a bare question with no content | Restate the question. A question is a message |
| An argument is supplied (e.g. `/what insurance`) | Treat it as the **domain**, per step 2 |

## 2. Fix the domain before writing anything

ASD-STE100 has two vocabularies, and this is what makes it fit for a specialist reader: a **controlled
general vocabulary** of roughly a thousand approved words, each with one approved meaning — plus
**Technical Names and Technical Verbs**, which are unlimited and drawn from the subject.

So the domain term is not the problem. It is the sanctioned part.

- Take the domain from the argument when one is supplied.
- Otherwise infer it from the conversation and **name your inference in one line** before the
  restatement, so a wrong guess is visible rather than silent.
- **Never translate a Technical Name into everyday words.** `subrogation` does not become "getting the
  money back from the other party". `binder` does not become "temporary paper". The reader knows the
  term; it is the sentence around it that was hard.

## 3. Apply the rules

Write to these. They are the ones that change the text most.

**Sentences**

- One instruction per sentence.
- **20 words maximum** in an instruction. **25 maximum** in descriptive text.
- Active voice. Use the passive only where the actor is genuinely unknown or irrelevant.
- Keep the articles. `the report`, not `report`.
- Simple tenses only — simple present, simple past, simple future.
- No participial phrase standing in for a clause. Split it into two sentences instead.

**Words**

- One term for one thing, every time. **Never vary a term for style** — a synonym reads as a second
  concept.
- No idiom, no metaphor, no slang, no understatement. `earned its keep` becomes a statement of what it
  did. `alarming` becomes the fact that caused the alarm.
- Noun clusters: **three words maximum**. Break longer ones with a preposition.

**Paragraphs**

- One topic each. **Six sentences maximum** in a procedure, ten in description.
- A sequence becomes numbered steps.
- A warning or a caution goes **before** the step it applies to, never after.

## 4. The fidelity rule — this is the one that matters here

**Simplification deletes qualifiers, and in this project the qualifiers are the content.** A reply
saying a check is `NOT RUN`, a claim is `unverified`, a line is `informational and never a stop`, or a
gate `refused` carries its whole meaning in those words. A restatement that loses one has not been
simplified. It has been falsified, and it now reads as more confident than its source.

So:

- **Every status word, negation, hedge, count, identifier, file path, command, work item id and error
  code is a Technical Name.** Reproduce it exactly. Do not reword it, round it, or drop it.
- Where a sentence cannot meet the word limit without losing a qualifier, **split the sentence and keep
  the qualifier**. The limit yields; the qualifier does not.
- Where the source says something was *not* done, *not* measured, or *not* proven, the restatement says
  so **in the same strength**. `could not be measured` does not become `was difficult to measure`.
- Where the source refuses something, the restatement refuses it. Do not soften a refusal into a
  preference.

**A shorter output is a warning sign, not a success.** STE trades length for clarity: short sentences,
repeated terms, no compression. Expect the restatement to be **longer** than its source. If it came out
shorter, something was dropped — find it.

## 5. Output

Emit, in order:

1. One line naming the **domain** used and whether it was supplied or inferred.
2. The restatement.
3. A short **Technical Names** list — the domain terms and status words you carried through unchanged.

That third item is the check on this skill. It shows the reader which words were treated as vocabulary
rather than simplified, so a term wrongly protected — or wrongly flattened — is visible without them
holding both texts side by side.

Nothing else. No preamble, no offer of further help, no restatement of these rules.

## Gotchas

- **This is a register change, not a reading level.** STE is written for a qualified reader working in a
  second language, not for a beginner. Do not explain the subject.
- **Do not merge the source's points to hit a paragraph limit.** Add a paragraph instead.
- **Do not fix the source.** If the preceding message was wrong, say so in a new reply — restating it
  incorrectly-but-clearly is worse than leaving it.
- **A table stays a table.** STE governs sentences. Reformatting a table into prose loses the structure
  that made it readable.
- **Code, commands, and identifiers are quoted, never simplified.** They are Technical Names with no
  approved substitute.
- **The domain vocabulary is the reader's, not yours.** If the conversation used a term, keep that term
  even where a more common word exists outside the domain.
