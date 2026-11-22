---
tags: [acceptance-testing, gate, go]
max_turns: 15
allowed_tools: [Read, Glob, Grep, Bash, Write, Edit, Skill]
---
Turn this scenario into an acceptance test. The shop runs at `http://localhost:8080` and exposes a JSON HTTP API.

```gherkin
Scenario: Orders at the threshold get ten percent off
  Given a registered customer
  And a product "Desk lamp" priced at 100.00
  When the customer buys "Desk lamp"
  Then the customer is charged 90.00
```
