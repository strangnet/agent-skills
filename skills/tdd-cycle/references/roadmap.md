# Roadmap

A roadmap is the ordered list of scenarios for one piece of work, together with the test strategy that fits its **work type**. Write it before any test exists, and get the user's approval on it.

**From an approved spec,** take the work type and seams from its *Testing* section and the scenarios from its *Behaviour* section, so the user reviews a draft rather than a blank page. When working a task from `slice`, take only the scenarios that task names. Reclassify only if the code contradicts the spec, and then say so: the spec may need updating first.

## 1. Classify the work type

| Work type | Signals | Test strategy |
|---|---|---|
| **Domain** | business rules, calculations, policies, state transitions | Unit tests against the domain core. Double every out-of-process dependency. |
| **Technical: managed dependency** | repository, adapter, migration, cache, queue that *your* system owns | Integration tests against the real thing (a container or local instance). No doubles for the dependency under test. |
| **Technical: unmanaged dependency** | client for a third-party API (payments, email, SaaS) | Contract tests against a stub server or recorded responses that pin the request and response shape you rely on. |
| **Presentation** | components, views, CLI output, formatting | Component tests on rendered output and user interaction. Pure visual styling is checked by hand: say so in the roadmap. |

If the signals conflict or are missing, ask the user which type the work is. Mixed work usually splits into one roadmap per type, with the domain roadmap first.

## 2. Draft the roadmap

```markdown
# Roadmap: <feature>

Work type: domain | technical (managed) | technical (unmanaged) | presentation
Behaviour: <one sentence the user agreed to in stage 1>

## Seams
- <dependency> → <how it is doubled, or "real instance via <tool>">

## Scenarios
1. <business-language scenario>  (Z)
2. ...                           (O)
3. ...                           (M / B / E)

## Out of scope
- <things deliberately deferred>

## Open questions
- <anything the user must decide before red>
```

Order the scenarios with [test-ordering.md](test-ordering.md). Write each scenario as an observable behaviour; it will become a test name.

**Done when:** the user approves the scenario list and every open question is resolved or explicitly parked.
