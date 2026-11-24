# Phase rules

The three phases of [acceptance testing](../SKILL.md), run once per scenario. Each ends at a gate (see SKILL.md).

## Phase 1: Executable scenario

**Goal:** the scenario written as a test that reads like the spec and calls DSL methods, some of which may not exist yet.

1. Write the test in layer 1:
   - **Without Gherkin:** a test in the project's framework whose name is the scenario title, with `Given` / `When` / `Then` comments.
   - **With Gherkin:** the scenario in a `.feature` file, plus step definitions whose bodies are a single DSL call each.
2. Map each scenario step to exactly one DSL call. Name the DSL method after the scenario's own words (`the customer buys "Desk lamp"` → `customer.buys("Desk lamp")`).
3. Make the first step create the test's own domain partition (for example, register a customer).
4. Pass only the values the scenario mentions. Everything else is a DSL default.
5. Run the test. A compile error or "undefined step" pointing at missing DSL methods is the expected result.

**Done when:** every step maps 1:1 to a DSL call named in business language, the test contains no URLs, selectors, protocol calls or assertions, and any failure is caused by DSL methods that do not exist yet.

## Phase 2: DSL

**Goal:** the DSL methods that phase 1 called, delegating to the driver interface.

1. Implement each missing DSL method:
   - Alias the identifiers that must be unique or define the partition.
   - Apply defaults for parameters the scenario left out.
   - Store **bridging state** that later steps of the same scenario need (for example, the current customer).
   - Call the driver interface.
2. Add any driver-interface methods the DSL needs as declarations only. Name them after the business action, not the protocol (`placeOrder`, not `postOrdersEndpoint`).
3. Run the test. It should compile and then fail because the driver does not implement the new methods.

**Done when:** the DSL compiles against the driver interface, and contains only parameter handling, aliasing, bridging state and delegation: no assertions, no business rules, no protocol code.

## Phase 3: Protocol driver

**Goal:** a driver that speaks to the running system and decides pass or fail.

1. Implement each new interface method in the driver for the chosen protocol:
   - Hide multi-step flows inside one method (for example, `registerCustomer` may sign up *and* sign in).
   - Verify outcomes by querying the system. Never trust what the driver itself sent.
   - Wait for asynchronous effects by polling with a deadline. Use no fixed sleeps.
   - On failure, fail in the language's idiomatic way (panic, raise, reject or return an error) with a message naming the actual and expected values. Avoid returning booleans for the caller to check.
   - Keep only transient protocol data (session tokens, connection handles), and only for the life of one test.
2. Stub only third-party services the team does not control, at the system's boundary (configure the SUT to use the stub). Leave the system's own database, cache and internal services real.
3. Run the test against the running system.

**Done when:** the test runs end to end, and either passes (the system has the behaviour) or fails with a message that describes missing behaviour rather than a test or infrastructure error. State which of the two happened.

When the scenario list is finished, summarise what was covered and offer to run the `test-review` skill over the new tests.
