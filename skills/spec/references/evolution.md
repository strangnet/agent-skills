# Splitting and evolving specs

## Capability map

Use one when a single request bundles capabilities that could each ship and be tested separately. Signs:

- It names distinct capabilities with their own users or data (accounts, billing, notifications).
- Its scenarios cluster into groups that could be verified separately.
- One capability could be cut or replaced without rewriting the others.

Propose the map before writing any spec, and get it approved. It's ten lines to review, and a wrong split is expensive to undo later.

```markdown
# Capability map: <initiative>

| Id | Responsibility | Depends on |
|---|---|---|
| accounts | Sign-up, sessions, SSO | — |
| billing | Plans, invoices, payments | accounts |
| notifications | Email and webhook fan-out | accounts |

Build order: accounts → billing, notifications
```

- **Stable ids.** Kebab-case, chosen once and never renamed. Each capability's spec is `docs/specs/<id>.md`, and the map is `docs/specs/<initiative>-map.md`.
- **Dependencies point one way.** If two capabilities need each other, they are one capability.
- **Contracts live in the provider's spec.** The map records that billing depends on accounts. The interface between them is a decision in the accounts spec.

Then write and approve one spec per capability, in build order.

## Delta specs

A spec that has shipped (`Status: implemented`) describes the system as it exists. Don't hand-edit it to describe a change. Write a delta spec next to it instead, `docs/specs/<slug>--<change>.md`, covering only what changes:

```markdown
# Spec delta: <change>

Status: draft | approved | implemented
Changes: [<original spec>](<slug>.md)

## Objective
<the change and why; name the deferred item or new requirement it implements>

## Current behaviour
<what happens today; link the relevant section of the original spec>

## New behaviour
<scenarios for what will be true afterwards, including what must not change>

## Decisions, Testing, Boundaries
<only what differs from the original; everything else is inherited>
```

It goes through the same approval gate. Keep one change per delta, so each build cycle stays small.

Once the change ships, fold the result into the original spec, bump its version (`V1` → `V2`), and set the delta's status to `implemented`.
