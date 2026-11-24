# Tools per dimension

Use the de facto tool for each dimension, so the team's existing configuration keeps working and two runs don't produce two different checkers. Flags change between versions: check each command against the installed version's help or docs before wiring it in (see `source-check`).

## By language

| Dimension | Rust | Go | Python | TypeScript |
|---|---|---|---|---|
| Format | `cargo fmt --check` | `gofmt -l .` (fails on any output) | `ruff format --check` | `prettier --check .` or `biome format` |
| Lint | `cargo clippy --all-targets -- -D warnings` | `golangci-lint run` | `ruff check` | `eslint .` or `biome check` |
| Types | the compiler | the compiler, `go vet ./...` | `mypy .` or `pyright` | `tsc --noEmit` |
| Coverage report | `cargo llvm-cov --lcov --output-path lcov.info` | `go test -coverprofile=cover.out ./...` | `pytest --cov --cov-report=xml` | `vitest run --coverage` (with `@vitest/coverage-v8`) |
| Dependencies | `cargo deny check advisories` or `cargo audit` | `govulncheck ./...` | `pip-audit` | `osv-scanner scan source -r .` |
| Mutation, changed files | `cargo mutants --in-diff <diff>` | no de facto tool; skip | `mutmut run` | `stryker run --mutate <files>` |

## Any language

| Dimension | Tool | Command | Gate on |
|---|---|---|---|
| Changed-line coverage | diff-cover | `diff-cover <report> --compare-branch=origin/main --fail-under=80` | the percentage |
| Secrets | gitleaks | `gitleaks dir . --redact` | any finding |
| Dependencies (mixed stacks) | osv-scanner | `osv-scanner scan source -r .` | high or above |
| Static security analysis | Semgrep | `semgrep scan --config p/default --severity ERROR --error` | any finding at that severity |
| Architecture boundaries | dependency-cruiser (JS/TS), import-linter (Python), depguard in golangci-lint (Go); in Rust, split layers into workspace crates and let the compiler hold the boundary | per tool | any violation |
| Bundle size | size-limit | `size-limit` | per-entry byte budget |
| Accessibility | axe-core CLI (`@axe-core/cli`) | `axe "$PREVIEW_URL" --tags wcag2a,wcag2aa --exit` | any violation; to gate on critical and serious only, save the JSON and filter by `impact` |
| Page performance | Lighthouse | `lighthouse "$PREVIEW_URL" --output=json --quiet` | LCP, CLS |

## Where each check runs

Cost decides placement. A check that stalls the agent gets switched off, and a switched-off gate is worse than none because the bar still looks like it exists.

| Stage | Script | Runs | Budget |
|---|---|---|---|
| Fast | `check:fast` | format, lint, types, the floor guard | seconds |
| Task end | `check:task` | `check:fast`, the tests, changed-line coverage | the user's Q4 budget (about 90 s) |
| CI | `check:full` | everything, including dependencies, secrets, security, mutation on changed files | minutes |
| Preview deploy | `check:a11y`, `check:perf` | accessibility, page performance | minutes |

**Scope to the diff.** Coverage of changed lines is a number the agent can move; project coverage is one it inherited. Mutation testing on a whole repo takes hours, while on the files a change touched it takes about a minute.

## Things that bite

- **Always pass `--redact` to gitleaks.** Without it, the matched secret lands in the agent's transcript, then in a summary or a commit message. Report the rule and the location, never the value.
- **Some scanners exit 0 on findings.** Semgrep needs `--error`; axe needs `--exit`. Prove every gate fails on a known violation before calling it enforced.
- **Accessibility and page performance need a URL.** A CLI, a library or a service with no UI has nothing for them to measure. Drop the dimension rather than inventing a check that can't run.
- **Coverage needs no second test run.** Point diff-cover at the report the suite already writes.
