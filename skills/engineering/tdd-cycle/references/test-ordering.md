# Ordering tests: ZOMBIES

Order scenarios so each test forces a small, obvious step in the production code. Walk the **Z → O → M** progression, and at each step ask about **B**, **I** and **E**:

| Letter | Meaning | Ask |
|---|---|---|
| **Z**ero | The empty or initial case | What happens with nothing: an empty collection, no input, a fresh object? |
| **O**ne | A single item or transition | What changes with exactly one? |
| **M**any | The general case | What changes with two or more? This is usually where the fake from green has to become real. |
| **B**oundaries | Edges and limits | Where are the thresholds, off-by-ones, maximums and minimums? |
| **I**nterface | The shape of the API | Is the call site pleasant? Does the test read like the spec? |
| **E**xceptions | Failure paths | What happens on invalid input, a missing dependency or an error from a collaborator? |

Then **S**: keep each step **s**imple. Pick the scenario that needs the least new code.

## Example: shopping cart total

1. Empty cart totals zero. *(Z)*
2. A cart with one item totals that item's price. *(O)*
3. A cart with several items totals the sum. *(M)*
4. Quantity greater than one multiplies the price. *(M)*
5. A discount at exactly the threshold applies; one cent below does not. *(B)*
6. An item missing from the catalogue is reported as an error. *(E)*

Interface questions come up throughout. If writing test 3 makes the API awkward, raise it at the gate rather than pressing on.
