# Maps

Use a map when reaching the destination needs more decisions than one session can hold. The map is a folder of markdown files that every later session reads to pick up where the last one stopped:

```text
docs/maps/<slug>/
├── MAP.md             the index, read at the start of every session
├── 01-<slug>.md       one file per decision ticket
└── 02-<slug>.md
```

## MAP.md

The map is an **index, not a store**. Each decision lives in exactly one place, its ticket. The map gives a one-line gist and a link.

```markdown
# <Name>

## Destination
<one or two lines: the brief, decision or change this map is finding its way to>

## Notes
<domain, standing preferences, skills every session should use>

## Decisions so far
- [<ticket title>](01-<slug>.md): <one-line gist of the answer>

## Not yet specified
<questions you can see coming but can't phrase precisely yet>

## Out of scope
- <thing>: <why> ([<ticket title>](NN-<slug>.md) when a ticket was closed for it)
```

Open tickets aren't listed in the map. They are the ticket files whose status is `open`.

## Tickets

```markdown
---
status: open | in-progress | closed | out-of-scope
type: grilling | research | prototype | task
blocked-by: [01-<slug>, 03-<slug>]
---

# <Title, phrased as the question>

## Question
<the decision this ticket resolves, sized for one session>

## Answer
<written on resolution: the decision and why, plus links to anything created>
```

Ticket types:

- **Grilling** (with the user): a decision settled in conversation, using the skill's grilling rounds. This is the default.
- **Research** (agent alone): a fact a decision waits on, from docs, APIs or the codebase. Several can run in parallel as subagents.
- **Prototype** (with the user): a cheap, rough artifact to react to (an outline, a stub, a sketch of the UI or logic) when the real question is "how should it look or behave?". Link it from the answer and throw it away afterwards.
- **Task** (agent or user): work that must happen before a decision can be made, such as getting API access or inspecting real data. Record what was done and any facts later tickets need.

The agent never stands in for the user on a ticket that needs them.

Refer to tickets by title, never by bare number. A list of numbers is unreadable at a glance.

## Fog or ticket?

The test is whether you can **state** the question precisely now, not whether you can answer it.

- **Ticket** when the question is sharp, even if it's blocked.
- **Not yet specified** when you can only see it dimly. Don't pre-slice it: one patch of fog may become several tickets, or none.

Fog only gathers toward the destination. Work beyond the destination is **out of scope**: it goes in that section and never graduates into a ticket. It comes back only if the destination is redrawn.

## Charting a map (first session)

1. Steps 1–4 of the skill have settled the destination and stress-tested the direction.
2. Grill **breadth-first** across the whole space, surfacing the open decisions rather than settling them.
3. Write `MAP.md`, then one ticket per question you can state now, then fill in `blocked-by` once every ticket has a file name.
4. Start the research tickets as parallel subagents.
5. Stop. Charting is one session's work, and it resolves nothing by hand.

## Working a map (later sessions)

1. Read `MAP.md`. Read individual tickets only as needed.
2. Take the ticket the user names. Otherwise take the first `open` ticket whose `blocked-by` tickets are all closed. Set it to `in-progress` before starting, so a parallel session skips it.
3. Resolve it according to its type.
4. Write the answer, set the ticket to `closed`, and add a line to *Decisions so far*.
5. Create tickets for newly sharp questions, and remove that fog from *Not yet specified*. If a ticket turns out to lie beyond the destination, set it to `out-of-scope` and add it to *Out of scope*. Update or delete tickets the answer makes obsolete.

Resolve **one ticket per session**. Research tickets are the exception.

The map is done when no open tickets and no fog remain. Then write the brief (step 6 of the skill) from *Decisions so far*.
