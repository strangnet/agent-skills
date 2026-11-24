---
name: acceptance-testing
description: Executable acceptance tests built in three layers (scenario, DSL, protocol driver) and run against the real system, with a review gate after each layer. Use when the user asks for acceptance tests, ATDD or executable specifications, wants BDD or Gherkin scenarios turned into tests, mentions a test DSL or protocol driver, or when a layered acceptance cycle is in progress. Unit-level test-first work belongs to tdd-cycle.
---

# Acceptance Testing

Acceptance tests ask *is the feature done and releasable?* They are an executable definition of done. They state what the system does in the user's language and check it against the running system. Unit tests, written with `tdd-cycle`, ask the different question *is the code technically correct?* The developer stays the architect; every layer ends at a **gate** for review.

## The layers

| Layer | Holds | Never holds |
|---|---|---|
| **1. Scenario** | Test cases in business language: either plain tests in the project's framework or Gherkin `.feature` files with thin step definitions. Each step is one DSL call. | Protocol details, assertions, URLs, selectors |
| **2. DSL** | One method per business action or check, named after the scenario wording. It aliases identifiers, fills in defaults, keeps **bridging state** between steps of one scenario, and delegates to the driver interface. | Assertions, business rules, protocol code |
| **3. Protocol driver** | One implementation of the driver interface per way of reaching the system (HTTP API, browser, CLI, message bus). It hides multi-step flows, queries the system to verify outcomes, polls with a deadline, and fails with a descriptive error. | Knowledge of scenarios, state that outlives one test |

The **system under test** (SUT) is the deployed application with its own database, cache and internal services. It is the single source of truth: every check queries it. Only third-party services the team does not control are stubbed, at the SUT's boundary.

**Gherkin is optional.** If the project already has `.feature` files or a BDD runner, step definitions call the DSL. Otherwise scenarios are plain tests calling the DSL directly. The DSL and driver are the same either way.

## Isolation

Acceptance tests share one running system, so each test creates its own **domain partition** as its first step (its own customer, account, tenant) and never relies on data another test made.

- **Alias** every identifier that must be unique or that defines the partition (customer names, product names, order references): `"Desk lamp"` becomes `"Desk lamp-k3f9a1-7"`. The same name maps to the same alias for the whole test, so later steps can refer back to it.
- Give descriptive, non-unique fields (prices, descriptions, roles) plain defaults that tests override only when the scenario cares.

Isolated tests run in parallel and can be re-run against the same environment.

## Stages

1. **Context.** Gather the scenarios (ask for them if they are missing), the architecture, and how the system is reached. Done when you can list the scenarios and the protocol(s) the driver will speak.
2. **Strategy.** Read [references/strategy.md](references/strategy.md) and draft the strategy: domain concepts mapped to DSL areas, driver choice, isolation keys, stubs. Done when the user approves it.
3. **Infrastructure check.** Confirm the alias helper, DSL root, driver interface, driver factory and (if Gherkin is used) step-definition wiring exist. If any are missing, read [references/infrastructure.md](references/infrastructure.md) and ask the user whether to create them or point you at existing ones. Create nothing until they answer. Done when every piece exists.
4. **Three-phase cycle.** Detect the language (see [Language](#language)) and read both of its reference files. Read [references/phases.md](references/phases.md), then run phase 1 → 2 → 3 for one scenario at a time, with a gate after each phase. Done when every scenario in the strategy runs end to end.

## Gates

At the end of every phase: show the diff and any test output, name the phase just finished and the one that comes next, then stop for the developer's go-ahead. When the user says "auto" or "run unattended", continue without stopping but still report each phase. Return to gated mode at the first surprise.

Track the current phase and scenario across messages. The user's explicit statement of the phase wins; if it is still unclear, ask.

## Test-first and system-first

Both orders are valid. When the system already implements the behaviour, phase 3 ends green. When the tests come first, phase 3 ends red, failing because the behaviour is missing rather than because of a test bug. In that case, offer to drive the implementation with the `tdd-cycle` skill, then re-run the acceptance test as the outer check.

## Language

Detect the language from the project manifest, then read both files for it:

| Manifest | Test tooling | Layer examples |
|---|---|---|
| `Cargo.toml` | [references/languages/rust.md](references/languages/rust.md) | [references/layers/rust.md](references/layers/rust.md) |
| `go.mod` | [references/languages/go.md](references/languages/go.md) | [references/layers/go.md](references/layers/go.md) |
| `pyproject.toml`, `setup.cfg`, `requirements*.txt` | [references/languages/python.md](references/languages/python.md) | [references/layers/python.md](references/layers/python.md) |
| `package.json` with `typescript` or a `tsconfig.json` | [references/languages/typescript.md](references/languages/typescript.md) | [references/layers/typescript.md](references/layers/typescript.md) |

For any other language, tell the user there is no reference file for it, then build the same layers with that ecosystem's test runner, BDD runner (if Gherkin is used) and HTTP client.
