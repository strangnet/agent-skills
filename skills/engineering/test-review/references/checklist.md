# Test quality checklist

Every criterion has an ID for the report table. Apply A–E to unit tests. Apply F only to integration and contract tests. Apply G only to acceptance tests (scenario → DSL → protocol driver), together with C1, C2, D1 and E2. When a criterion does not fit, mark it n/a with a reason.

## A. Scope and isolation

- **A1 Behaviour-sized unit.** A test exercises one behaviour of the system, which may span several in-process objects. It does not mirror the class or method structure one-to-one.
- **A2 Out-of-process dependencies doubled.** Database, network, filesystem, clock and randomness sit behind a seam and are replaced in unit tests. In-process collaborators stay real unless they are slow or nondeterministic.
- **A3 Independent.** No state shared or mutated between tests. Each test passes when run alone, in any order, or in parallel.
- **A4 Deterministic.** No fixed sleeps, real time, unseeded randomness or reliance on iteration order.

## B. Design

- **B1 Observable behaviour.** Assertions target outputs, state visible to callers, or commands sent across a seam. A behaviour-preserving refactor of the production code leaves the test green.
- **B2 Public surface.** Tests go through the unit's public API. Reaching into private members, or widening visibility only for tests, needs a stated reason.
- **B3 Stub queries, mock commands.** Interaction assertions (called with, called once) are reserved for outgoing commands whose side effect *is* the behaviour. Collaborators that only return data are stubbed or faked, and calls to them are not asserted on.

## C. Structure

- **C1 Name states behaviour.** The test name says what the system does in business terms ("rejects an expired coupon"), not which method it calls ("test_apply_coupon_2").
- **C2 Given / When / Then visible.** The three parts are easy to see, through comments or clear blank-line blocks.
- **C3 One action.** A single *When*. Several assertions are fine when they describe one outcome.
- **C4 Straight-line body.** No branching or looping that decides what gets asserted. A language's assertion idiom (Go's `if got != want`) and parameterised test mechanisms are exempt.
- **C5 Precise assertions.** Assertions compare specific expected values and fail with a readable message. Flag `assert x` / `toBeTruthy()` where a value comparison is possible, and large snapshot assertions used in place of specific expectations.
- **C6 Parameterise variations.** Input variations of one behaviour use the language's parameterised form with named cases, not copy-pasted tests.
- **C7 Relevant setup visible.** Builders and fixtures hide incidental detail. Detail that the behaviour depends on stays in the test body.

## D. Coverage and strength

- **D1 Spec covered.** Every scenario in the spec's *Behaviour* section or the roadmap (when one exists) maps to at least one test.
- **D2 ZOMBIES walked.** Zero, one, many, boundaries and exception paths each have a test where they apply.
- **D3 Mutants killed.** The mutants probed in step 5 of the skill are caught. Every survivor is a finding.
- **D4 No dead tests.** No commented-out tests. Skipped or pending tests carry a reason, and someone runs them.

## E. Execution

- **E1 Fast unit suite.** Unit tests run in milliseconds. Slow tests are tagged or separated so the default run stays fast.
- **E2 Green.** The suite passes in the review run.

## F. Integration and contract tests

- **F1 Real managed dependencies.** Integration tests for dependencies the system owns (database, cache, queue) run against a real instance and isolate their data per test.
- **F2 Contract pinned.** Contract tests for third-party APIs use a stub server or recorded responses that assert on the request shape the code sends. The stubbed responses match the provider's documented schema.
- **F3 Bounded waiting.** Async conditions are awaited by polling with a timeout, never a fixed sleep.

## G. Acceptance tests

- **G1 Business-language scenarios.** Scenario tests and step definitions contain only DSL calls, one per step, named in the scenario's words. No URLs, selectors, protocol calls or assertions.
- **G2 Pure DSL.** DSL methods do only parameter handling, aliasing, bridging state and delegation to the driver interface. Flag any assertion, business rule or protocol detail.
- **G3 Driver owns verification.** Pass/fail is decided in the protocol driver by querying the system under test. Failures name actual and expected values. Drivers do not return booleans for callers to check.
- **G4 Own partition, aliased.** Each test creates its own domain partition as its first step, and aliases every unique or partition-defining identifier. Nothing depends on data from another test or a shared seed.
- **G5 Real system, external stubs only.** The system's own database, cache and internal services are real. Only third-party services the team does not control are stubbed, at the system's boundary.
- **G6 Swappable driver.** The DSL depends on the driver interface, and a factory selects the implementation from configuration.
