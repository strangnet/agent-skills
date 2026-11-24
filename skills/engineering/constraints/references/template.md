# CONSTRAINTS.md template and defaults

## Template

```markdown
# Constraints

Last reviewed: <YYYY-MM-DD> by <who>

## Floor
Always enforced by `scripts/floor-guard.sh`. Blocks.

- No new suppressions: a checker silenced instead of satisfied
- No unfinished work: stubs, empty catch or except, TODO in new code
- No easier tests: skipped, focused or deleted tests, assertions removed
- No secrets in source: checked by <gitleaks command>
- No weakening: this file is not loosened in the commit of a failing change

## Enforced
| Dimension | Rule | Why this number | Checked by | Runs at | Mode |
|---|---|---|---|---|---|
| Types | 0 errors | — | `<command>` | task end | block |
| Coverage | changed lines ≥ 80% | forces a test, allows a config line | `<command>` | task end, CI | block |
| Dependencies | 0 at high or above | below that is mostly noise | `<command>` | CI | block |

## Measured
Ratchets: today's value is the bar.

| Metric | Today | Direction | Checked by |
|---|---|---|---|
| Project coverage | 62.4% | must not fall | `<command>` |

## Exceptions
| ID | Rule | Path | Reason | Owner | Expires |
|---|---|---|---|---|---|
| X1 | <rule> | <glob> | <why, with a tracking link> | <owner> | <YYYY-MM-DD> |
```

Rules for the content:

- **Comparators on every threshold.** Write `≥ 80%` or `<= 200 kB`, not "80%". The floor guard reads the comparator to tell loosening from tightening, and reports any change to a number without one. In the *Measured* table, the *Direction* column (`must not fall`, `must not grow`) does that job.
- **A reason next to every number.** A threshold without a rationale gets deleted by the next person who hits it.
- **Every rule names its command.** The *Checked by* column is what makes it a constraint rather than a wish.
- **Exception IDs are `X1`, `X2` and so on.** Code cites them with `floor-ok: X1` on the line the guard would flag. Each has an owner and an expiry date; after that date the citation stops counting.
- **Keep row labels stable.** The guard matches a rule by its bullet text before the colon, or by a row's first cell. Rename a rule in one commit and change its number in another, or the guard reports it as removed.

## Sane defaults

Use these when the user has no number in mind. Most codebases meet them on day one.

| Constraint | Default | Why this number |
|---|---|---|
| Coverage of changed lines | ≥ 80% | High enough to force a test, low enough to allow a config line |
| Project coverage | today's value, must not fall | Needs no argument to adopt |
| Mutation score, changed files | ≥ 60% to start | Typical for a suite never mutated before; 80% is mature |
| Dependency vulnerabilities | 0 at high or above | Below that is mostly noise |
| Static analysis findings | 0 at high or above | Same |
| Accessibility | 0 critical or serious axe violations | Moderate and minor are often debatable |
| Largest Contentful Paint | ≤ 2500 ms | Core Web Vitals "good" threshold |
| Cumulative Layout Shift | ≤ 0.1 | Same |
| Exception lifetime | ≤ 90 days | Long enough to plan the fix, short enough to remember it |
| Ratchet tolerance | 0.5 percentage points | Absorbs drift when an unrelated file moves the number |
