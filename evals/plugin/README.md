# Plugin evals

Behavioural evals for the skills in this plugin, run with `claude plugin eval`.

## Run

From the repo root:

```bash
claude plugin eval . --scaffold --allow-tools Bash Write Edit --no-publish
```

- `--scaffold` is required. Each case builds its starting project with `scaffold.sh`, which runs in the agent's working directory.
- `--allow-tools Bash Write Edit` is required. Without it, the "must not write" graders pass trivially because the writes were denied.
- For a cheap smoke run, add `--runs 1 --ablation none`. To filter, use `--case 'tdd-cycle-*'` or `--tag phase`.

## Cases

| Case | Checks |
|---|---|
| `tdd-cycle-red-stops` | Writes one Given/When/Then test, shows it failing, stops before green. Reads `go.md` only. |
| `tdd-cycle-green-minimal` | Hardcodes the minimum, leaves the test file alone, stops before refactor. |
| `tdd-cycle-refactor-not-skipped` | Runs a refactor phase before the next test when asked to skip ahead. |
| `tdd-cycle-language-{rust,python,typescript}` | Detects the language from the manifest and reads only that reference file. |
| `tdd-cycle-not-triggered` | A conceptual TDD question fires neither skill. |
| `test-review-go-weak-tests` | Finds five planted test problems with `file:line` evidence, and writes nothing. |
| `acceptance-testing-asks-before-infrastructure` | With no DSL or driver in place, proposes a strategy or asks before creating infrastructure, and writes nothing. |
| `code-review-flags-weakened-bar` | Flags a skipped test, assertions removed from a test that stays, and a `//nolint` suppression as blocking, and names the boundary defect the skip hides. Edits nothing. |
| `doubt-finds-race` | Doubting a "safe for concurrent use" claim finds the check-then-act race in a rate limiter, with a concrete interleaving, and classifies it as real. |
| `acceptance-testing-phase1-stops` | Phase 1 writes only the scenario test with business-language DSL calls, leaves the DSL and driver alone, and stops before phase 2. |
| `session-handoff-structure` | After a small change, the handoff uses every template section in order, gives absolute paths, reports the change from a `git` check, writes "none" for empty sections, and stays in chat. |

## Sandbox notes

- The agent runs with an isolated home directory, so toolchains installed under `~` (rustup, pyenv, nvm) are not visible, and package downloads are blocked. Phase cases that need to *run* tests therefore use Go (stdlib only). Language-detection cases only grade which reference file was read, so they work without a toolchain.
- Case `env` keys must start with `EVAL_`, so `RUSTUP_HOME` and similar cannot be passed through.
