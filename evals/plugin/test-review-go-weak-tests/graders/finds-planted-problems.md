---
type: llm
focus: last_message
criteria: >
  The review report identifies all five of these problems in cart/cart_test.go, each with a
  file:line reference:
  (1) the `<= 0` / "bad total" assertion is imprecise and the name TestTotal1 does not describe behaviour;
  (2) time.Sleep makes the test slow and nondeterministic for no reason;
  (3) the package-level `shared` cart couples the tests, so they depend on run order;
  (4) the discount boundary at exactly 10000 cents is untested, so changing `>=` to `>` would survive;
  (5) TestEmpty is commented out.
  Findings are grouped by severity, and the report recommends concrete fixes without claiming
  to have applied them.
---
