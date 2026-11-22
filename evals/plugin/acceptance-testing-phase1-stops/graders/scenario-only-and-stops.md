---
type: llm
focus: last_message
criteria: >
  The message shows one new test whose steps each make a single DSL call named in the
  scenario's wording (for example Customer.IsRegistered, Catalog.HasProduct with "Desk lamp"
  and "100.00", Customer.Buys, Customer.ConfirmCharged with "90.00"), under Given / When / Then
  comments. The test contains no HTTP calls, URLs or assertions on response data. The message
  reports that the test does not compile yet because the new DSL methods are missing, stops
  for review, and names phase 2 (DSL) as next.
---
