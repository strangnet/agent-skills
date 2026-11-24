---
type: llm
focus: last_message
criteria: >
  The final message is a session handoff with these sections, in this order: "Where it started",
  "Decisions and changes", "Key files for next session", "Running state", "Verification",
  "Deferred and open questions", "Pick up here". No section is missing; a section with nothing
  to report says "none" (Running state reports no processes or servers rather than omitting them).
  It names greet/greet.go and greet/greet_test.go by absolute path (starting with "/"), says
  they have uncommitted changes, and gives `go test ./...` (or an equivalent go test command)
  under Verification. "Pick up here" names a single next action. The handoff is in the message
  itself, not only in a file, and the message tells the user to copy it before clearing.
---
