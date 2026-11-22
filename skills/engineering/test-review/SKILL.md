---
name: test-review
description: Read-only review of test code against a quality checklist, reporting findings with file:line evidence and leaving the repository untouched. Use when asked to review, audit or validate tests, to check test quality or strength, or to vet a change that adds tests before merge.
---

# Test Review

Review tests the way a senior engineer would before merge, against [references/checklist.md](references/checklist.md). The review is **read-only**: you run tests and read code, and every suggested fix goes in the report rather than into the repository.

> Inspired by [Augmented AI Development (AAID)](https://github.com/dawid-dahl-umain/augmented-ai-development) by Dawid Dahl.

## Steps

1. **Scope.** Use the paths the user named. Otherwise take the test files changed on this branch: `git diff --name-only $(git merge-base HEAD main)` filtered to test files. If neither gives anything, ask. For each test file, find the production code it exercises, and any spec or roadmap the tests are meant to cover. Done when you have a list of (test file, production file, spec if any).
2. **Language.** Detect the language from the project manifest and read its file in `references/languages/` (`rust.md`, `go.md`, `python.md`, `typescript.md`). For other languages, say there is no reference file and apply the checklist using that ecosystem's idioms.
3. **Run.** Run the in-scope tests with the project's runner. Record pass/fail/skip counts and note any test that takes longer than ~100 ms in a unit suite. A red or uncompilable suite is a finding in itself. Report it first and continue the review.
4. **Apply the checklist.** Read [references/checklist.md](references/checklist.md) and apply every criterion to every file in scope. Also check the language file's *Review smells*. Each criterion gets a verdict per file: **pass**, **fail** (with `file:line` evidence) or **n/a** (with a reason). Done when no criterion is left unjudged for any file.
5. **Probe strength.** For each production file, pick two or three plausible mutants (flip a comparison, shift a boundary by one, drop a call to a collaborator, return a constant) and decide whether a test would catch each. Name every mutant that would survive. This is reasoning only: leave the code unchanged.
6. **Report** in the format below.
7. **Offer next steps.** Ask whether the user wants the findings fixed. Fixes to tests that lock in behaviour belong in the refactor phase of the `tdd-cycle` skill. Fixes that need new tests start a red phase there.

## Report format

```markdown
## Test review: <scope>

Suite: <N passed, N failed, N skipped> in <time> · <language>, <runner>

| Criterion | <file 1> | <file 2> |
|---|---|---|
| A1 Behaviour-sized unit | pass | fail |
| ... | | |

### Blocking
- **<ID> <short title>** (`path:line`): <what is wrong> → <concrete fix>

### Should fix
- ...

### Nits
- ...

### Surviving mutants
- `path:line`: <mutation> survives because <reason>; a test asserting <X> would catch it.
```

Severity:
- **Blocking:** the test can pass while the behaviour is broken (a false positive), the suite is red or flaky, or a spec scenario has no test.
- **Should fix:** the test is coupled to the implementation, hard to read, or slow.
- **Nit:** naming, layout, or a minor duplication.
