---
name: constraints
description: Set up or change a project's quality bar as a written contract in CONSTRAINTS.md, with numbers, the command that checks each one, and a floor guard that catches an agent quietly lowering the bar (new suppressions, skipped or deleted tests, removed assertions, stubs, loosened thresholds). Run once per project, and again to change the bar.
disable-model-invocation: true
---

# Constraints

Write down what "good enough to ship" means for **this** project, with numbers, in a file that outlives the session and can be checked by a machine. Other skills describe good practice in prose an agent may or may not follow. This one produces a contract: `CONSTRAINTS.md`, the commands behind it, and a guard that makes lowering it loud.

Why it matters: an agent writes more code in an afternoon than anyone reads that week, so the judgement has to move out of a reviewer's head into checks that run around the loop. When a check goes red, an agent takes the cheapest road to green: it silences the check, skips the test or edits the number. The floor guard catches exactly those moves.

**Never ask what you can read.** Detect first, then ask only what's left.

## Steps

1. **Detect.** Read the manifest (`Cargo.toml`, `go.mod`, `pyproject.toml`, `package.json`), the test runner, the existing linters and formatters, CI under `.github/workflows/` (or equivalent), and `CLAUDE.md` / `AGENTS.md`. Run the test suite once with coverage if it's cheap, to learn today's number. If `CONSTRAINTS.md` already exists, this is a **change**: read it, ask what the user wants to change, and skip to step 4. Report what you found in two or three lines. Done when you know the stack, the checks that already exist and today's coverage.
2. **Ask four questions** in one round, in `shape`'s grilling format (question, then your recommended answer and why), so "yes" accepts every recommendation. Every question has a default, so "I don't know" still produces a working setup:
   - **Q1 Dimensions.** Beyond the floor, which to enforce: coverage of changed lines, dependency vulnerabilities, secrets, static security analysis, mutation score, architecture boundaries, bundle size, accessibility, page performance? Recommend from what you detected. Say what each costs: accessibility and page performance need a running URL, architecture needs a rules file, mutation testing is slow unless scoped to the diff.
   - **Q2 Block or warn.** Recommend: the floor and anything external block; new numeric dimensions warn for two weeks, then block.
   - **Q3 Numbers.** Does the user have targets, or should you measure today and hold that line? Recommend measuring: an invented number the codebase fails today becomes a red build everyone learns to ignore.
   - **Q4 Budget.** The slowest check the user will wait for at task end. Recommend about 90 seconds; anything slower runs in CI only.

   In a non-interactive run (CI, a loop, an unattended agent), don't ask: set up the floor only, and list the questions for a human.
3. **Measure.** Run each chosen dimension's check once on the current code and record the result. A target the codebase fails today becomes a **ratchet** (today's value, must not fall or grow) instead of an enforced number. Done when every chosen dimension has a command that runs and a measured value.
4. **Write `CONSTRAINTS.md`** at the repo root from [references/template.md](references/template.md). Every number gets a reason next to it, and every threshold is written with a comparator (`≥`, `≤`, `>=`, `<=`), because that is how the floor guard tells loosening from tightening. A dimension with a number but no command is an aspiration: leave it out, or put it under *Measured*.
5. **Wire it up.** Use [references/tools.md](references/tools.md) for the de facto tool per dimension and language. Don't write your own checker when one exists.
   1. Put the checks in the project's own task runner (`package.json` scripts, `Makefile`, `justfile`, a cargo alias) as `check:fast`, `check:task` and `check:full`, so they run without an agent. `CONSTRAINTS.md` stays the source of truth; the scripts mirror it.
   2. Copy `${CLAUDE_SKILL_DIR}/scripts/floor-guard.sh` to the project's `scripts/floor-guard.sh` and make it executable. Run it from CI on every pull request.
   3. Offer the Claude Code Stop hook (below). Show the settings change and wait for a yes before writing it.
   4. Add the way-of-working line to `CLAUDE.md` or `AGENTS.md` (below).
6. **Prove each check.** For every enforced row, run its command against a deliberate violation and a clean control: the violation must fail, the control must pass, and a scanner error must fail rather than pass. Then run `scripts/floor-guard.sh` on the current branch. Done when every enforced row has been seen to fail and pass. When the guard reports a finding in existing code, fix it or record it as an exception with the user; a new `CONSTRAINTS.md` itself never triggers the guard.
7. **Hand off.** Summarise the bar in a few lines: what blocks, what warns, what is measured, where each check runs, and what you left out and why. Don't commit unless told to.

## The floor

Always enforced, needs no tools beyond git, and passes on any codebase on day one:

- No new suppression of a checker (`@ts-ignore`, `# noqa`, `//nolint`, `#[allow(...)]`, `eslint-disable`, coverage and security ignores).
- No new unfinished work (stubs that throw, empty `catch` or `except`, `todo!()`, `TODO`).
- No new skipped or focused tests, no deleted test files, no assertions removed from tests that stay.
- No secrets in source.
- `CONSTRAINTS.md` is not weakened to make a change pass.

`scripts/floor-guard.sh` checks all of it except secrets against the merge base with the main branch, including uncommitted and untracked files. It exits `0` clean, `1` with findings and `2` when it can't run. A finding the team accepts gets a row in the *Exceptions* table (owner, reason, expiry) and the line cites it with `floor-ok: X<n>`. An expired or unknown ID doesn't count.

## The Stop hook

The guard's `--hook` mode runs when Claude finishes a turn. It blocks once per **new** finding, tells Claude to fix it or explain it to the user, and never blocks twice on the same finding, so an intended one (a pending test in a TDD test list) costs one round, not every turn. Add to the project's `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [ { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/floor-guard.sh --hook" } ] }
    ]
  }
}
```

## Way of working line

```markdown
- Constraints: read `CONSTRAINTS.md` before writing code and run `check:task` before calling work done. Never weaken it to make a change pass; propose an exception instead.
```

## Changing the bar

- **Tightening** (a higher minimum, a lower maximum, a new rule) is silent: edit the file and move on.
- **Loosening** goes in its own commit, with the reason in the message, never in the commit of the feature that was failing. The guard flags it either way; the user approves it.
- Update a ratchet's recorded value when the number improves. A drop is the finding.

## Red flags

- A threshold the codebase fails today, with no ratchet and no plan.
- A number with no command behind it, or a hand-rolled checker where a de facto tool exists.
- Every constraint judged by the project's own tests, with no external opinion (a vulnerability database, a linter rule set, WCAG). At least one constraint should be external.
- A slow check in the fast stage, and someone reaching for `--no-verify`.
- An exception with no owner, or an expiry more than a year out.
- The agent proposing to relax a threshold instead of fixing the code.
