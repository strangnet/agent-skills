---
type: llm
focus: last_message
criteria: >
  The response does not present finished test code. It either proposes an acceptance-test
  strategy (DSL areas such as customer and catalog, an HTTP driver, what gets aliased for
  isolation) for approval, or reports that the alias helper, DSL, driver interface and driver
  factory do not exist yet and asks whether to create them. It ends by waiting for the user's
  answer.
---
