---
name: spec
description: Write a spec from decisions already made (in the conversation, a shape session, a map or a detailed issue) and stop for approval before anything is built. Synthesises rather than interviews, and its scenarios and test seams become the tests. Use when asked to write up, spec out or specify a feature, to turn a discussion or an issue into a spec, or to spec a change to a feature that already shipped.
---

# Spec

Write down what has been decided, in a form that the people and agents who build it can act on. A spec is the single written record of a piece of work: what it does, how it is tested, and where its edges are.

**Synthesise, don't interview.** The decisions should already exist, from the conversation, a `shape` session, a finished map or a detailed issue. Where something is missing, don't invent it:

- A small gap with an obvious answer goes under **Assumptions**, for the user to confirm.
- A real decision goes under **Open questions**. Recommend `/shape` to settle it. A spec with open questions can't be approved.

## Steps

1. **Gather.** Read the conversation, the issue when one is given (with comments; use the tracker's CLI, such as `gh issue view`), any map under `docs/maps/`, `GLOSSARY.md`, the ADRs in `docs/adr/` that touch this area, and the code the work changes. Use glossary terms throughout the spec and respect existing ADRs. If this changes a feature that already has a spec in `docs/specs/`, write a **delta spec** instead: see [references/evolution.md](references/evolution.md). Done when every section of the template has a source or a named gap.
2. **Split check.** If the work bundles several capabilities that could each ship and be tested on their own (separate users, separate data, acceptance criteria that cluster), write a capability map first, then one spec per capability: see [references/evolution.md](references/evolution.md). When a `shape` session settled the split, write the map from it. Otherwise propose the split, and suggest `/shape` if the boundaries are contested. Most work is one capability, so skip this step.
3. **Seams and work type.** Propose where the behaviour will be tested. Prefer existing seams to new ones, and the highest seam that works: the fewer seams, the better, and one is ideal. In a new codebase there are no seams yet, so the first slice is a **walking skeleton**: the thinnest path that runs end to end through the real shape of the system, and that creates the seams, build and test setup everything after it relies on. Classify the work type with the table in `tdd-cycle`'s `references/roadmap.md`. Confirm the seams and work type with the user before writing: they decide how everything downstream is tested.
4. **Write** the spec to `docs/specs/<slug>.md` using the template below. Decisions that name a library, framework or tool follow its official docs for the version in use (the `source-check` skill). If the behaviour depends on state (modes, async steps, retries, failure recovery, concurrent callers) or has operations whose effects must hold exactly, add *State model* and *Contracts*: see [references/state-and-contracts.md](references/state-and-contracts.md). Otherwise leave both out.
5. **Doubt the spec** (unless the project's way of working says `Doubt: off`). Run the `doubt` skill with *Decisions*, *Testing* and *Boundaries* as the artifact, and *Problem*, *Scope* and *Behaviour* as the contract. Fold real findings into the spec; trade-offs go under *Decisions* or *Assumptions*.
6. **Stop for approval.** Summarise the spec, list its assumptions and open questions, and ask the user to approve it or request changes. **End your turn.** Don't start acceptance tests, a roadmap or code in the same turn. Approval comes in a later message.

## Template

```markdown
# Spec: <name>, V1

Status: draft | approved | implemented
Source: <issue link, map, or "conversation">

## Problem
<who has the problem, what hurts, what success looks like, in the user's terms>

## Solution
<what changes for the user, from their point of view>

## Scope
<this version: the smallest slice that tests the riskiest assumption, and why it comes first (a walking skeleton in a new codebase). What follows it goes under Out of scope, or into later specs.>

## Behaviour

### <user story: as a <role>, I want <capability>, so that <benefit>>
- <scenario in glossary terms: given … when … then …>
- <edge case or failure path>

## State model
<!-- only when behaviour depends on state; see references/state-and-contracts.md -->
Tier: lightweight | full
<states, transitions, invariants (INV-1, INV-2, …), impossible transitions>

## Contracts
<!-- only for operations whose effects must hold exactly -->
### Operation: <name>
Preconditions: …
Postconditions (success): …
Postconditions (failure): …

## Decisions
- <decision: modules, interfaces, schema, API contracts, interactions> (ADR-NNNN when there is one)

## Testing
Work type: domain | technical (managed) | technical (unmanaged) | presentation
Seams:
- <seam> → <how it is reached in tests, and what is doubled>
Prior art: <similar tests in the codebase to follow>
Checks other than tests: <benchmark | audit | inspection> → <scenario or INV it covers, and pass criteria>  (omit if none)

## Boundaries
- Always: <rule specific to this work>
- Ask first: <change that needs a human's OK>
- Never: <thing the builder must not do>

## Assumptions
- [ ] <assumption to confirm> → <how to test it, for one the plan depends on>

## Out of scope
- <deferred idea>: <why it is not in this version>

## Open questions
<!-- must be empty before approval -->
```

Rules for the content:

- **Behaviour is exhaustive for this version.** Cover every user story in *Scope*, and give each one scenarios for the normal path, its edges and its failures. These scenarios become the tests, so a behaviour missing here goes untested.
- **Testable, not vague.** Turn "fast" or "easy" into a condition someone can check ("search returns in under 200 ms for 10,000 orders").
- **Everything is verified.** Every scenario, invariant and impossible transition is covered by a test or a named check. Default to an executable test. Use a benchmark, an audit (accessibility, UX, runbook) or an inspection (code, config, schema) only when it is the more honest way to verify that item, and say which item it covers.
- **No file paths or code.** They go stale. The exception is a snippet from a prototype that pins a decision more precisely than prose (a state machine, a schema, a type shape): trim it to the decision and say where it came from.
- **Boundaries are specific to this work.** Project-wide rules (build commands, code style, layout) belong in `CLAUDE.md` or `AGENTS.md`, not in every spec.

## Keeping the spec alive

- **Spec first.** When a decision changes during the build, update the spec before the code, and add an ADR if the change passes the ADR test.
- **Park new ideas.** An idea that arrives mid-build goes under *Out of scope* and waits for the next version. Rescoping happens between versions, not during one.
- **Mark it implemented** (`Status: implemented`) once it ships. From then on, it describes the system as it exists. A later change gets a delta spec.

## Handoff

After approval, decide whether building this spec fits in one session. If it doesn't, the next step is `slice`, which breaks it into tasks that each do. If it does, check the project's `CLAUDE.md` or `AGENTS.md` for its way of working:

- **The project uses acceptance tests:** the next step is `acceptance-testing`, starting from *Behaviour* and *Testing*, with `tdd-cycle` inside it.
- **Otherwise:** the next step is `tdd-cycle`, whose roadmap starts from *Behaviour* and *Testing*.

Offer that step, and wait for the user to start it.
