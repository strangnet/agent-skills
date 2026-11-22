---
type: llm
focus: last_message
criteria: >
  The final message presents exactly one new test and the runner output showing it fails
  (a compile error for missing types counts as failing). The test body uses Given / When / Then
  comments. The message stops and asks the developer to review before moving on, and names
  green as the next phase. It does not implement production code that makes the test pass,
  and it does not claim the test passes.
---
