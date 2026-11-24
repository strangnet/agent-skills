# strangnet agent skills

Skills that make AI coding agents work the way a disciplined engineer does: test-first, in small reviewed steps, with the developer as the architect. The skills are language-agnostic, with worked examples for **Rust, Go, Python and TypeScript**.

## Install

Claude Code (2.1.275 or later):

```text
/plugin install strangnet-skills --marketplace strangnet/agent-skills
```

The repository also ships a Codex marketplace manifest in `.agents/plugins/marketplace.json`.

## Skills

| Skill | Use it to | Reach for it with |
|---|---|---|
| [`shape`](skills/engineering/shape/SKILL.md) | Turn a loose idea into a destination with every decision settled: explore options, get grilled, and leave with glossary updates, ADRs and a spec. Work too big for one session becomes a map of decision tickets. Invoke it by name only. | `/shape <idea>` |
| [`spec`](skills/engineering/spec/SKILL.md) | Write what's been decided as a spec in `docs/specs/`: behaviour scenarios, test seams, decisions, boundaries and out-of-scope, then stop for approval. Changes to shipped features get a delta spec. | "Write this up as a spec", "spec out the change" |
| [`slice`](skills/engineering/slice/SKILL.md) | Break an approved spec that's too big for one session into vertical-slice tasks, ordered by what blocks what, as task files or tracker issues. | "Slice this spec", "break it into tasks" |
| [`tdd-cycle`](skills/engineering/tdd-cycle/SKILL.md) | Drive code with tests in a gated red → green → refactor cycle. The agent stops for review after every phase. | "Let's TDD this", "next test", "make it pass" |
| [`acceptance-testing`](skills/engineering/acceptance-testing/SKILL.md) | Turn scenarios into acceptance tests built in three layers (scenario → DSL → protocol driver) that run against the real system. Gherkin is optional. | "Write acceptance tests for these scenarios", "ATDD" |
| [`test-review`](skills/engineering/test-review/SKILL.md) | Review tests against a quality checklist and report findings with `file:line` evidence, without editing anything. | "Review the tests before I merge" |
| [`code-review`](skills/engineering/code-review/SKILL.md) | Review a diff or PR across five axes (correctness, readability, architecture, security, performance) and report severity-ranked findings. It fixes only the findings you approve. | "Review this PR", "review my changes before merge" |
| [`constraints`](skills/engineering/constraints/SKILL.md) | Set the project's quality bar once: four questions, then `CONSTRAINTS.md` with numbers and the command behind each, wired into the project's scripts, CI and an optional Stop hook. A floor guard catches the cheap roads to green (suppressions, skipped or deleted tests, removed assertions, stubs, loosened thresholds). Invoke it by name only. | `/constraints` |
| [`doubt`](skills/engineering/doubt/SKILL.md) | Cross-examine a non-trivial decision before it stands: the artifact and its contract, without your reasoning, go to a fresh-context reviewer told to disprove it. `shape` and `spec` run it at their gates. | "Doubt this", "stress-test this plan", before a migration or deploy |
| [`source-check`](skills/engineering/source-check/SKILL.md) | Write library, framework and tool code from the official docs for the version the project pins, not from memory, and cite them. Anything unverified is marked as such. | "Check the docs", or automatically before version-sensitive code |

### Where to start

| Kind of work | Path |
|---|---|
| **New project** with an open start | `/shape` (explore options, maybe chart a map) → `spec` (first slice: a walking skeleton) → build |
| **Idea** that needs breaking into features | `/shape` (grill the split into features) → `spec` (capability map, then one spec per feature) → `slice` each spec → build each task |
| **Issue** that settles the decisions | `spec #123` → build |
| **Issue** that only names the problem | `/shape #123` → `spec` → build |
| **Small fix** | `tdd-cycle`: reproduce the bug as a failing test, make it pass, refactor |
| **Any project**, once | `/constraints` to write the bar down; every build and review after that holds it |

First you shape, then you slice: any spec too big to build in one session goes through `slice` before it's built, whichever path it came from.

**Build** is `tdd-cycle`, wrapped in `acceptance-testing` when the project uses acceptance tests: `acceptance-testing` writes the outer test, and `tdd-cycle` drives the implementation in small unit-tested steps until it passes. Every path ends with `test-review` and `code-review` before merge.

### Way of working

Whether a project uses layered acceptance tests is the project's choice, not the skills'. State it in the project's `CLAUDE.md` or `AGENTS.md`, and `spec` will hand off accordingly:

```markdown
## Way of working
- Specs live in `docs/specs/`, ADRs in `docs/adr/`, the glossary in `GLOSSARY.md`.
- Acceptance tests: yes, layered (scenario → DSL → protocol driver), no Gherkin.
- Tasks: GitHub issues, as sub-issues of the source issue.
```

Three more lines tune the cross-cutting skills:

```markdown
- Sources: check the official docs for the pinned version before writing library code, and cite them.
- Doubt: gates (default) | always | off. Cross-model: offer | off (default).
- Constraints: read `CONSTRAINTS.md` before writing code and run `check:task` before calling work done. Never weaken it to make a change pass.
```

- **Sources** makes `source-check` a standing habit rather than something the agent has to remember to load. That moment ("I'm writing this from memory") is exactly when it wouldn't think to.
- **Doubt** sets how often `doubt` runs. `gates` means at the checkpoints the skills name (before an ADR in `shape`, before approval in `spec`, claims no test can show in `tdd-cycle`) and before anything irreversible. `always` adds every non-trivial decision. `off` means only when asked. `Cross-model: offer` makes `doubt` offer a second opinion from another model's CLI each round.
- **Constraints** is written by `/constraints`, which also installs the floor guard. It's the only one of the three that is enforced mechanically, not by instruction.

Without the acceptance-test line, `spec` hands off straight to `tdd-cycle`, and the spec's scenarios become the unit-test roadmap. Without the tasks line, `slice` writes task files under `docs/specs/<slug>/tasks/`.

## Agents

| Agent | Use it to |
|---|---|
| [`code-reviewer`](agents/code-reviewer.md) | Run the `code-review` skill as an independent subagent, in parallel with other work or apart from the session that wrote the code. Approve fixes in its brief, or by resuming it with the finding IDs after reading its report. |
| [`doubter`](agents/doubter.md) | The fresh-context reviewer behind `doubt`: given an artifact and its contract, never the author's reasoning, it returns only the ways the artifact fails, each with a concrete failure scenario. |

Each skill detects the project's language from its manifest (`Cargo.toml`, `go.mod`, `pyproject.toml`, `package.json`) and loads only that language's reference file. Other languages work too, using the same rules and that ecosystem's idioms.

## Repository layout

```text
skills/<category>/<skill>/     SKILL.md plus the skill's own references/
references/<set>/              shared reference sets, vendored into skills (see below)
scripts/sync-references.sh     copies shared sets into skills; --check detects drift
scripts/validate-versions.sh   checks that every plugin manifest has the same version
scripts/test-floor-guard.sh    tests the constraints skill's floor guard
evals/plugin/                  behavioural evals, run with `claude plugin eval`
```

## Adding a skill

1. Create `skills/<category>/<name>/SKILL.md`. Keep the main file short and move detail into `references/`, which the skill reads only when needed.
2. Skills in an existing category folder load automatically. For a new category, add its folder (for example `"./skills/<category>"`) to the `skills` array in `.claude-plugin/plugin.json`.
3. To use a shared reference set such as the language files, create an empty `references/languages/` folder in the skill and run `scripts/sync-references.sh`. Edit shared files only under the root `references/`; CI fails if a skill's copy drifts.
4. Add eval cases under `evals/plugin/` (see its [README](evals/plugin/README.md)).
5. Check that it loads: `claude plugin validate .` should list the new skill.

## Releasing

Claude Code and Codex use the plugin version to decide whether an installed copy needs updating. If a change ships without a version bump, users may not receive it.

1. Pick the new version using semver: patch for fixes and wording changes, minor for new skills or behaviour, major for removed or renamed skills.
2. Set it in all four manifests: `.claude-plugin/plugin.json` (the source of truth), the root `plugin.json`, `.claude-plugin/marketplace.json` and `.agents/plugins/marketplace.json`. CI fails if they differ; run `scripts/validate-versions.sh` to check locally.
3. Commit as `chore(release): bump plugin manifests to X.Y.Z`, merge it, then tag that commit and publish a GitHub release whose notes list the changes: `gh release create X.Y.Z --target main --generate-notes`.

## Credits

The workflow skills are inspired by [Augmented AI Development (AAID)](https://github.com/dawid-dahl-umain/augmented-ai-development) by Dawid Dahl. They also build on long-standing practice: Robert C. Martin's three laws of TDD, James Grenning's ZOMBIES test ordering, and Dave Farley's layered acceptance test model.

The `code-review` skill and `code-reviewer` agent are inspired by Addy Osmani's [agent-skills](https://github.com/addyosmani/agent-skills). The `spec` skill merges Addy Osmani's `spec-driven-development` with Matt Pocock's `to-spec`, and `slice` merges Addy's `planning-and-task-breakdown` with Matt's `to-tickets`. The `constraints`, `doubt` and `source-check` skills distil Addy Osmani's `constraint-driven-development`, `doubt-driven-development` and `source-driven-development`; the floor guard is a bash port of his reference implementation. The `shape` skill merges ideas from Addy Osmani's `idea-refine` with Matt Pocock's `grilling`, `domain-modeling` and `wayfinder` from [mattpocock/skills](https://github.com/mattpocock/skills).

## License

[MIT](LICENSE)
