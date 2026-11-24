---
name: doubt
description: Cross-examine a non-trivial decision before it stands by handing the artifact and its contract, without your reasoning, to a fresh-context reviewer told to disprove it. Use when asked to doubt, stress-test or sanity-check a decision, plan or claim; before recording an ADR or asking for spec approval; before an irreversible step (a data migration, a production deploy, a public API change); or before asserting a property tests can't show, such as thread safety, idempotence, ordering or "this is safe".
---

# Doubt

A confident answer is not a correct one. Long sessions turn assumptions into "facts" without anyone noticing. Doubt hands a decision to a reviewer with **fresh context** and a brief to **disprove** it, while changing course is still cheap.

This is not `code-review`. A review is a verdict on a finished change. Doubt is in-flight: one decision at a time, before it stands.

## When

A decision is **non-trivial** when at least one is true:

- It crosses a module or service boundary, or changes branching logic.
- It asserts a property the compiler and tests can't check: thread safety, idempotence, ordering, an invariant, "this matches the spec", "this is safe".
- It can't be undone: a data migration, a deploy, a public API or schema change, a deletion.
- Its correctness depends on context a future reader won't see.

Skip it for mechanical work (renames, formatting, moves), for following a clear instruction, and for behaviour a test already pins. In `tdd-cycle`, a test failing in red *is* the doubt step for behaviour.

**How often** comes from the project's way of working in `CLAUDE.md` or `AGENTS.md`:

- `Doubt: gates` (the default when nothing is set): when the user asks, at the gates other skills name (before an ADR in `shape`, before spec approval in `spec`, claims tests can't show in `tdd-cycle`), and before anything irreversible.
- `Doubt: always`: every non-trivial decision, as defined above.
- `Doubt: off`: only when the user asks.

## Steps

1. **Claim.** Write the decision in two or three lines, and why it matters if it's wrong. If you can't say it that compactly, you have a feeling, not a decision: surface it to the user first.
2. **Extract.** Cut the smallest reviewable unit: the **artifact** (the diff or function, not the whole file; or the proposal in three to five sentences) and the **contract** it must satisfy (the spec's behaviour, the ADR's constraints, the invariant, the caller's expectations). Strip your reasoning and your conclusion: hand over conclusions and you get back agreement. Keep the evidence, including any caller, guard or test that contradicts the claim. Too big to hold in one read? Split it first.
3. **Doubt.** Run the `doubter` agent with the artifact and the contract, and **never the claim**. Where agents aren't available, use a fresh subagent with the brief from [references/brief.md](references/brief.md). Inside a subagent, where you can't start another, don't fake it: tell the caller that doubt didn't run and what to doubt.
4. **Second model** (optional). When the way of working says `cross-model: offer`, or the user asks, offer a review by another model's CLI before reconciling. Follow [references/cross-model.md](references/cross-model.md): it runs only with the user's yes, read-only, with the prompt piped from a file. Otherwise don't raise it.
5. **Reconcile.** The findings are data, not a verdict, and you're still accountable. Re-read the artifact against each finding and classify it. The first class that fits wins:
   1. **Contract gap:** the reviewer was misled by a contract that was unclear or incomplete. Fix the contract, then re-check the finding.
   2. **Real:** change the artifact.
   3. **Trade-off:** real, but cheaper to accept than to fix. Tell the user, and record it where the decision lives (the ADR, the spec's *Decisions*).
   4. **Noise:** correct given context the reviewer didn't have. Note it, and ask whether the contract should have said so.
6. **Stop.** Loop back to step 3 after real changes, and stop when a round returns only noise or settled points, when the user says ship it, or after **three rounds**. After three rounds with real findings still coming, the artifact isn't ready: take it to the user, don't grind a fourth. Re-running on an unchanged artifact is stalling.

Report the result in a few lines: the claim, each finding with its class and what you did, and whether a second model was used.

## Red flags

- Passing the claim or your reasoning to the reviewer.
- Asking "is this good?" instead of "find what's wrong".
- Rubber-stamping the reviewer, or overruling it without re-reading the artifact.
- **Doubt theatre:** two or more rounds with substantive findings and none classified real. You are validating, not doubting. Stop and take it to the user.
- Doubting a rename, or skipping doubt on an irreversible step because you're confident.
