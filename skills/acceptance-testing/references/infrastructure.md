# Infrastructure

The one-time scaffolding every acceptance suite needs. Check for each piece before the first phase. When one is missing, ask whether to create it. The language's `layers/<lang>.md` file has a working version of each.

## Pieces

| Piece | Responsibility |
|---|---|
| **Alias helper** | Turns a plain name into one unique to this test and run. It returns the same alias for the same name throughout a test. Uniqueness comes from a run identifier plus a sequence. |
| **DSL root** | One object per test that composes the domain DSL areas (`dsl.customer`, `dsl.catalog`) and gives them a shared alias helper and driver. |
| **Domain DSL areas** | One per domain concept extracted from the scenarios. Each holds its own bridging state. |
| **Driver interface** | The contract every protocol driver implements, with methods named after business actions. In languages with consumer-side interfaces (Go), it lives with the DSL. |
| **Driver factory** | Picks the driver at runtime from configuration (for example `ACCEPTANCE_DRIVER=http`, `SUT_URL=…`), so the same scenarios can run over a different protocol. |
| **Step definitions** | Gherkin only: wiring that creates a fresh DSL per scenario and maps each step pattern to one DSL call. |

## Shape

```text
acceptance/
  scenarios        (plain tests, or features/*.feature + step definitions)
  dsl/             alias helper, DSL root, domain areas, driver interface
  drivers/         one implementation per protocol, plus the factory
```

## Lifetime

- Create a new DSL root, and with it a new alias helper, for every test or scenario. Aliases and bridging state never carry over between tests.
- Drivers may be shared if they hold no per-test state. Otherwise create one per test as well.
- The system under test is started outside the suite (a deployed environment, `docker compose`, a CI service). The suite reads its address from configuration and never starts or resets it.
