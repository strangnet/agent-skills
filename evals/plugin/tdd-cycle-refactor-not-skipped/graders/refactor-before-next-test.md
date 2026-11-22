---
type: llm
focus: last_message
criteria: >
  Before any new test is written, the response carries out a refactor phase. It either
  applies improvements (for example, the unclear names `x` and `c` in cart.go) with the suite
  still green, or it states explicitly that no refactoring is needed and says what it checked.
  It then stops for the developer's review. A response that goes straight to writing or
  un-skipping TestSingleItemTotalsItsPrice without a refactor phase fails.
---
