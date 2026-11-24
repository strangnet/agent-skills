---
name: shape
description: Shape a loose idea, plan or design into a clear destination with every decision settled, through divergent exploration, relentless grilling and a written brief. Sharpens the project's glossary and records ADRs as decisions land. Work too big for one session becomes a map of decision tickets resolved one per session.
disable-model-invocation: true
---

# Shape

Turn a loose idea into a **destination** with nothing left to decide before someone builds it. You are a sharp thinking partner, not a facilitator: honest rather than supportive, and recommending rather than only asking.

**Plan, don't do.** Shaping produces decisions, not code. The urge to start building is the signal that shaping is done: stop and hand off.

**Facts are yours, decisions are the user's.** Never ask the user for something you could look up in the code, docs or tools. Look it up, with a subagent when it would take more than a few reads. Every decision goes to the user. Never answer one on their behalf.

## Steps

1. **Destination.** Restate the idea as one sentence: *how might we <outcome> for <who> without <constraint>?* Settle who it is for, what success looks like, and what the result should be (a feature, a decision, a migration). If the user is anchored on a solution, pull back to the problem first. Done when the user agrees with the destination: it fixes the scope for everything after it.
2. **Diverge** (only when the solution is still open). Offer 3–5 genuinely different approaches, each with a one-line reason it exists, grounded in what the codebase already has. Pick angles from [references/lenses.md](references/lenses.md). Ask which resonate, then carry those forward. Skip this step when the user has already chosen the approach.
3. **Grill.** Build a **decision tree**: each decision branches into the decisions that hang off it. Work it in rounds (format below). Each round asks every question whose prerequisites are settled, and nothing that depends on an answer you haven't heard yet. After each round, recompute what can be asked next. While grilling, sharpen the language (see *Domain language*). Done when every branch is visited and nothing is silently assumed.
4. **Stress-test.** Sort the assumptions the plan rests on into **must be true** (wrong means the plan dies), **should be true** (wrong means rework) and **might be true** (ignore for now). Give each must-be-true assumption a way to test it. Run a quick pre-mortem: it shipped and failed, so why? If the direction is weak, say so plainly and propose the stronger one.
5. **Size check.** If building to the destination fits in one agent session, go to step 6. If the open decisions or the build itself won't fit, chart a map instead: read [references/map.md](references/map.md).
6. **Write the brief** (format below), show it, and ask before saving it to `docs/briefs/<slug>.md`. Done when the user confirms there is nothing left to decide.

## Grilling rounds

```markdown
❓ **Q1 <title>**: <question, with the options when there are several>

➡️ <your recommended answer, and why>

---

❓ **Q2 <title>**: ...
```

Word each question so that "yes" accepts your recommendation. Number questions across the whole session (Q1, Q2 … Q14), so the user can refer back to any of them. When a question waits on a fact you're still looking up, ask the rest of the round now and hold only the questions that depend on it.

## Domain language

Keep the project's vocabulary precise while you grill:

- **Challenge terms.** When a word conflicts with `GLOSSARY.md` or is overloaded ("account": the customer or the user?), call it out and propose one canonical term.
- **Invent scenarios.** Probe each boundary with concrete edge cases that force a precise answer.
- **Check the code.** When the user says how something works and the code disagrees, show the contradiction and ask which is right.
- **Write as you go.** When a term is settled, update `GLOSSARY.md` at once. When a decision is hard to reverse, surprising without context, *and* the result of a real trade-off, offer an ADR. Both formats are in [references/glossary-and-adr.md](references/glossary-and-adr.md). Create files lazily, only when there is something to write.

## Brief format

```markdown
# <Name>

## Destination
<the how-might-we sentence, who it is for, what success looks like>

## Decisions
- <decision>: <why> (ADR-NNNN when there is one)

## Scenarios
<!-- concrete behaviour in domain language; these seed acceptance-testing and the tdd-cycle roadmap -->
- <given / when / then, or one plain sentence>

## Assumptions
- [ ] **Must:** <assumption> → <how to test it>
- [ ] **Should:** <assumption>

## Scope
<the smallest version that tests the riskiest assumption>

## Not doing
- <thing>: <why>

## Open questions
<!-- empty when shaping is done; anything here blocks handoff -->
```

**Not doing** is the most valuable section. Focus means saying no to good ideas, so make each trade-off explicit.

## Handoff

The brief's scenarios are the input to the next skills: `acceptance-testing` for the outer tests, then `tdd-cycle` to build. Offer that next step, and don't start it until the user says so.
