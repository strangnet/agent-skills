# Code review checklist

Apply every axis to every changed file. A criterion that doesn't fit the change is skipped silently. Only failures become findings.

## 1. Correctness

Does the code do what it claims?

- Matches the spec or task, including the parts it's silent about.
- Edge cases handled: empty, null, zero, one, many, boundaries.
- Error paths handled, not just the happy path. No silent fallbacks that hide a broken invariant.
- No off-by-one errors, races or inconsistent state.
- Tests exercise the new behaviour and would fail if it broke. A bug fix comes with a regression test.

## 2. Readability and simplicity

Could another engineer follow this without the author explaining it?

- Names are specific and follow project conventions (no bare `data`, `temp`, `result`).
- Control flow is straightforward: no nested ternaries, deep callbacks or clever tricks.
- The code is no bigger than the problem. Ten times the necessary lines is a defect, not a style point.
- Abstractions earn their cost. Don't generalise before the third use.
- Comments explain non-obvious *why*, not *what*.
- No leftovers: unused variables, compatibility shims, commented-out code, `// removed` markers.
- **New conditionals aren't bolted onto unrelated flows.** That's a missing abstraction, not a nit.
- **No repeated conditionals on the same shape.** They point to a missing model or dispatcher.

## 3. Architecture

Does the change fit the system?

- Follows existing patterns. A new pattern needs a stated reason.
- Module boundaries hold. Dependencies point the right way, with no cycles.
- **Refactors reduce complexity rather than relocating it.** Count the concepts a reader must hold. If the "cleaner" version needs as many, it isn't cleaner. Prefer the version where branches, modes or layers disappear, and prefer deleting an abstraction to polishing it.
- **Feature logic stays out of shared modules,** and existing canonical helpers are reused instead of near-duplicated.
- **Type boundaries are explicit.** Question gratuitous `any`, casts, optionals and defaults that paper over an unclear invariant.
- **File size stays healthy.** Around 1000 total lines in one file is a signal to inspect. When a change grows an already-large file, decompose first, then add.
- **Change size is reviewable.** About 100 lines changed is good, 300 is fine for one logical change, and 1000 should be split (by stacking, by layer or by vertical slice). Mechanical refactors and deletions are exempt. Refactoring mixed with new behaviour is two changes.

## 4. Security

Does the change open a hole?

- Input is validated at system boundaries. Data from APIs, files, config, logs and users is untrusted.
- No injection: parameterised queries, encoded output, no shell string building.
- Authentication and authorisation are checked where needed.
- No secrets in code, logs or version control.
- New dependencies are justified (the existing stack can't do it), maintained, licence-compatible and free of known vulnerabilities.
- Dependency upgrades are one package per change, with the changelog read and the lockfile diff reviewed. A "patch" bump can still change behaviour.

## 5. Performance

Does the change add a bottleneck?

- No N+1 queries.
- No unbounded loops, fetches or list endpoints without pagination.
- No blocking work on a path that should be async.
- No large allocations in hot paths, or needless re-renders in UI code.

## Structural remedies

When you flag a structural problem, name the move:

- Replace a chain of conditionals with a typed model or an explicit dispatcher.
- Collapse duplicate branches into one clearer flow.
- Separate orchestration from business logic.
- Move feature-specific logic into the package that owns the concept.
- Reuse the canonical helper instead of a near-duplicate.
- Make a type boundary explicit so that downstream branching disappears.
- Delete a pass-through wrapper that adds indirection without clarity.
- Extract a helper, or split a large file into focused modules.

Prefer the remedy that removes moving parts over one that spreads them around.

## Presumptive Required findings

Report these as Required unless the change leaves the structure no worse than before:

- A refactor that relocates complexity instead of reducing it.
- A file pushed past a healthy size with no decomposition.
- Feature logic added to a shared module.
- A near-duplicate of an existing canonical helper.
- A silent fallback that hides an unclear invariant.
