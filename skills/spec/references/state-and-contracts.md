# State model and contracts

Given/when/then scenarios describe examples. When behaviour depends on what state the system is in (several modes, async steps, retries, failure recovery, concurrent callers), examples alone leave gaps: nobody lists the scenario for the transition that must never happen. A state model and contracts close those gaps by stating what must *always* hold, not just what happens in each example.

This borrows the vocabulary of formal methods (invariants, pre- and postconditions) without the notation or tooling. Nothing is proved; everything is tested or checked.

## Pick the lightest tier

Choose the lightest tier that still makes the behaviour precise, and name it in the spec.

**None.** Plain request and response, no meaningful modes. Leave the *State model* section out.

**Lightweight.** Two to four states, guards or async modes that matter, but not a full state machine:

- **Key states:** each with what a user or caller can observe in it.
- **Critical transitions:** only the ones that change behaviour.
- **Invariants:** one to three properties that must always hold.

**Full.** Multi-step, async, concurrent or failure-heavy behaviour, where the state machine itself is part of the contract:

- **States:** every meaningful state, with what can be observed in it.
- **Transitions:** from → to → trigger.
- **Invariants:** every property that must always hold.
- **Impossible transitions:** state changes that must never happen.

```markdown
## State model

Tier: full

States:
- Draft: editable by the author, invisible to others
- Submitted: read-only, waiting for review
- Published: visible to everyone

Transitions:
- Draft → Submitted: author submits
- Submitted → Draft: reviewer rejects
- Submitted → Published: reviewer approves

Invariants:
- INV-1: a published post always has an approver
- INV-2: at most one revision of a post is Submitted at a time

Impossible transitions:
- Draft → Published (skipping review)
- Published → Draft
```

Use glossary terms for state names. Number invariants `INV-1`, `INV-2` and so on, so tasks and tests can refer to them.

## Contracts

For each operation whose effects must hold exactly (a write, a payment, a state transition, a call other systems depend on), state what must be true before and after. Skip reads and trivial getters.

```markdown
### Operation: approve post

Preconditions:
- the post is Submitted
- the caller is a reviewer and not the author

Postconditions (success):
- the post is Published, with the caller recorded as approver
- subscribers are notified once

Postconditions (failure):
- the post is still Submitted; nothing else changed
```

**A contract refines behaviour; it never adds any.** If a clause changes what a user, caller or downstream system can observe, add the scenario or invariant to the spec first, then reference it. The failure postcondition is where most bugs hide: say what is left behind when the operation fails halfway.

## Checks

Before asking for approval:

- The tier is named, and is the lightest one that works.
- Every observable behaviour is in *Behaviour*, an invariant, or *Out of scope*.
- Every contract clause traces to a scenario or invariant.
- Every invariant and impossible transition is covered under *Testing*, by a scenario or a named check.

## How they are tested

Each invariant and each impossible transition needs at least one test or check:

- **Invariant:** exercise the operations that could break it, then assert that it still holds. A property-based test is often the best fit.
- **Impossible transition:** put the system in the source state, attempt the trigger, assert that it is refused and nothing changed.
- **Failure postcondition:** make the operation fail partway (a doubled dependency that errors), assert the promised state.

They become scenarios on the `tdd-cycle` roadmap like any other, named in business terms ("a draft can't be published without review").
