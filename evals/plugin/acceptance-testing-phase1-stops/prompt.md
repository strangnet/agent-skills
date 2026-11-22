---
tags: [acceptance-testing, phase, go]
max_turns: 20
allowed_tools: [Read, Glob, Grep, Bash, Write, Edit, Skill]
---
We're doing acceptance tests for the shop, no Gherkin. Strategy is approved and the infrastructure under `acceptance/` is in place. Do phase 1 for this scenario:

```gherkin
Scenario: Orders at the threshold get ten percent off
  Given a registered customer
  And a product "Desk lamp" priced at 100.00
  When the customer buys "Desk lamp"
  Then the customer is charged 90.00
```
