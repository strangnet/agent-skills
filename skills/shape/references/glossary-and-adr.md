# Glossary and ADR formats

## Glossary

One `GLOSSARY.md` at the repository root. If a `GLOSSARY-MAP.md` exists, the repository has several contexts: the map lists each context's glossary and how the contexts relate, so update the glossary of the context under discussion. Ask when it's unclear which one that is.

```markdown
# <Context name>

<One or two sentences: what this context is and why it exists.>

## Language

**Order**:
A customer's request for goods, from placement until delivery.
_Avoid_: purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: bill, payment request
```

Rules:

- **Be opinionated.** When several words name one concept, pick the best and list the rest under *Avoid*.
- **Define what it is, not what it does,** in one or two sentences.
- **Only terms specific to this project.** General programming concepts (timeouts, retries, error types) don't belong, however often the code uses them.
- **No implementation detail.** The glossary is not a spec or a decision log.
- Group terms under subheadings when natural clusters appear.

## ADRs

Offer an ADR only when all three hold:

1. **Hard to reverse.** Changing your mind later has a real cost.
2. **Surprising without context.** A future reader would ask "why did they do it this way?"
3. **A real trade-off.** There were genuine alternatives, and this one won for specific reasons.

Typical cases are architectural shape, how contexts integrate, technology with lock-in, ownership and scope boundaries, deliberate deviations from the obvious path, and constraints not visible in the code.

ADRs live in `docs/adr/` as `NNNN-slug.md`, numbered one above the highest existing file. Create the folder when the first ADR is written.

```markdown
# <Short title of the decision>

<One to three sentences: the context, what was decided, and why.>
```

That is usually enough. Add a **Status** line (proposed, accepted, superseded by ADR-NNNN), **Considered options** or **Consequences** only when they say something a reader would otherwise miss.
