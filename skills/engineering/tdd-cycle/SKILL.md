---
name: tdd-cycle
description: Test-driven development as a gated red-green-refactor cycle that stops for developer review after every phase. Use when the user asks to work test-first or says "TDD", "red/green/refactor", "test list", "next test" or "make it pass", or when a cycle is already in progress. Not for planning-only discussions or for changes the user has not asked to drive with tests. Feature-level tests against the running system belong to acceptance-testing.
---

# TDD Cycle

The developer stays the architect; you are the pair who types. Every phase ends at a **gate** where the developer reviews before anything moves on.

## Unit tests and acceptance tests

The two kinds of test answer different questions:

- **Unit tests** (this skill) ask *is the code technically correct?* They are fast, double every out-of-process dependency, and put design pressure on the code.
- **Acceptance tests** (the `acceptance-testing` skill) ask *is the feature done and releasable?* They run against the real system through its boundaries.

This skill is the inner loop. When the user wants to confirm a feature works end to end, or to turn scenarios or acceptance criteria into tests, switch to `acceptance-testing`. When the feature already has a failing acceptance test, that test is the outer loop. The cycle ends by re-running it (see [references/phases.md](references/phases.md)).

## Stages

Stages 1–2 are ordinary collaboration. Strict cycle rules apply from stage 3 onward.

1. **Context.** Read the spec, the relevant code and any existing tests. Done when you can state the behaviour to build in one sentence and the user agrees with it.
2. **Roadmap** (optional, when the user wants a plan). Read [references/roadmap.md](references/roadmap.md), classify the work type and draft the roadmap. Done when the user approves the ordered scenario list. Production code waits until stage 4.
3. **Test list.**
   1. **Load the language reference first.** Detect the language from the manifest (see [Language](#language)) and open its reference file before writing or planning any test. Take the test runner command, pending-test marker and test layout from that file, not from memory.
   2. Ask whether the user wants a full **test list** (every scenario written as a pending test) or a **single test** at a time, unless they already said.
   3. Order scenarios with [references/test-ordering.md](references/test-ordering.md). Write only test names and pending markers here.

   Done when the language reference file has been read in this session and the pending tests use its marker and layout. Then enter red.
4. **Cycle.** Read [references/phases.md](references/phases.md) before the first phase. Run red → green → refactor for one test at a time, a gate after each phase. Done when every scenario on the list is green and has been through refactor.

## The three laws

1. Write production code only to make a failing test pass.
2. Write only as much test as is needed to fail.
3. Write only as much production code as is needed to pass.

## Gates

At the end of every phase:

1. Show the diff and the test runner output.
2. Name the phase just finished and the phase that comes next.
3. Stop and wait for the developer's go-ahead.

**Unattended mode.** When the user says "auto" or "run unattended", move through the phases without stopping, but still report each phase as above. Return to gated mode as soon as anything surprising happens: a test passing in red, a test failing in green, or a refactor turning the suite red.

## Phase state

Keep track of the current phase, the current test and the remaining list across messages. To decide which phase you are in:

1. The user's explicit statement ("we're in green") wins.
2. Otherwise follow the fixed order red → green → refactor → red. Every phase runs, including refactor.
3. If it is still ambiguous, ask "Which phase are we in?"

Explicit user instructions override anything in this skill.

## Language

Detect the language from the project manifest and read only that language's reference file:

| Manifest | Reference |
|---|---|
| `Cargo.toml` | [references/languages/rust.md](references/languages/rust.md) |
| `go.mod` | [references/languages/go.md](references/languages/go.md) |
| `pyproject.toml`, `setup.cfg`, `requirements*.txt` | [references/languages/python.md](references/languages/python.md) |
| `package.json` with `typescript` or a `tsconfig.json` | [references/languages/typescript.md](references/languages/typescript.md) |

For any other language, tell the user there is no reference file for it, then apply the same phases using that ecosystem's test runner, pending-test marker and idiomatic seams for test doubles.
