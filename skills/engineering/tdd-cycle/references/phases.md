# Phase rules

The red, green and refactor phases of [the TDD cycle](../SKILL.md). Each phase ends at a gate (see SKILL.md).

## Red: write a failing test

**Goal:** a test that pins down the next behaviour and fails for the reason you expect.

1. Pick the next scenario. With a test list, un-skip the next pending test and write its body. With single-test mode, write a new test for the next scenario in the roadmap or ordering.
2. Write the smallest test that expresses that one behaviour:
   - Structure the body with `Given` / `When` / `Then` comments in the language's comment syntax (`And` and `But` are allowed too). Use no other structural comments.
   - Assert on observable behaviour: return values, state the caller can see, calls made across a seam. Leave internal structure free to change.
   - Replace out-of-process dependencies (database, network, filesystem, clock, randomness) with test doubles at a seam. See the language reference for the idiomatic seam.
   - Check one behaviour per test. Several assertions are fine when they describe the same outcome.
   - Keep the body straight-line, with no branching or looping that decides what gets asserted. Parameterised tests are the sanctioned way to cover several inputs.
   - Name the test after the business behaviour ("empty cart totals zero"), not the method under test.
   - Unit tests run in milliseconds. If one cannot, it is not a unit test, so reconsider the seam.
3. Run the test and read the failure. A compile, type or import error counts as red when it is caused by the code the test is asking for.

**Done when:** the new test fails, the failure message points at the missing behaviour, and every other test still passes.

**Surprise:** if the new test passes straight away, stop and report it. Either the behaviour already exists or the test is not testing what it claims, and both need the developer's judgement.

## Green: make it pass

**Goal:** the least production code that turns the suite green.

1. Write the minimum that satisfies the failing test, together with every existing test:
   - **Fake it** freely: return a constant if that is all the tests demand. The next test will force generalisation (**triangulation**).
   - Skip edge cases, validation and extension points that no test asks for. They arrive with their own tests later.
   - When the real implementation is a one-liner and just as obvious as the fake, writing it directly is fine.
2. Run the full suite.

**Done when:** every test passes, and no production line exists that some test did not demand.

**Surprise:** if any test fails, stop and report which tests fail and why. Make the production code pass the test as written; changing the test to fit the code is the developer's call. So is silencing a checker or skipping a test to get green: never do either on your own.

## Refactor: improve the design

**Goal:** better structure while staying green. This phase always runs, even when it changes nothing.

1. Review production and test code for:
   - duplication, unclear names, long functions, mixed levels of abstraction
   - cohesion and separation of concerns: pure logic in the core, side effects at the edges
   - tests that are hard to read or that over-specify implementation details
2. Apply improvements one at a time, running the suite after each.
3. When the design or API changes, move the tests to the new design and delete code that only existed to keep old tests passing. Keep a legacy API alive only if the user asks for it.
4. Add non-behavioural supporting code in this phase only: logging, error messages, doc comments, type annotations, performance work that the tests already justify.
5. If nothing is worth changing, say "No refactoring needed" and name what you checked.

**Done when:** the suite is green, and you have either applied improvements or stated explicitly that none were needed.

Next comes red for the next test on the list. If the list is empty, the cycle is complete:

1. If the feature has an acceptance test, run it. If it passes, the feature is done. If it still fails, name the behaviour it shows is missing and propose new scenarios for the list.
2. Summarise what was built and ask whether to add scenarios, or to run the `test-review` skill over the new tests.
