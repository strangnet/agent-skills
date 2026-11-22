# Acceptance test strategy

The plan for one feature's acceptance tests, agreed with the user before phase 1.

## 1. Extract domain concepts

Read the scenarios and list the nouns the business uses (customer, product, order). Each concept that scenarios act on becomes a DSL area. List the verbs and checks under each: they become DSL methods, named in the scenario's own words.

## 2. Choose the driver

| System is reached through | Driver |
|---|---|
| A public HTTP or gRPC API | API driver: the default. Fast, and stable against UI change. |
| A web UI that *is* the behaviour under test | Browser driver (Playwright or similar), querying by role and accessible name. |
| A command-line tool | CLI driver: run the binary, parse its output and exit code. |
| Events or a message bus | Messaging driver: publish, then consume or query the resulting state. |

When the same scenarios must hold over two protocols (API and UI), write both drivers behind the one interface and select between them with the factory.

## 3. Plan isolation

For each concept, decide which fields are aliased (unique or partition-defining) and which get plain defaults. Name the partition each test creates first.

## 4. List stubs

List every third-party service the scenarios touch (payment, email, SMS) and how the SUT is pointed at a stub for it. The system's own services are never on this list.

## Template

```markdown
# Acceptance strategy: <feature>

Scenarios: <link or list>
Gherkin: yes (<runner>) | no (plain <framework> tests)

## DSL areas
- customer: isRegistered, buys, confirmCharged
- catalog: hasProduct

## Driver
<API | browser | CLI | messaging>, selected by <env var>; SUT at <how the address is configured>

## Isolation
- Partition: <what each test creates first>
- Aliased: <fields>
- Defaults: <field = value>

## Stubs
- <third-party service> → <stub and how the SUT is configured to use it>

## Open questions
- ...
```

**Done when:** the user approves the strategy, and every scenario step maps to a DSL method listed in it.
